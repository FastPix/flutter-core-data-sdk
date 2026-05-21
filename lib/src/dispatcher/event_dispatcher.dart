import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fastpix_flutter_core_data/src/logger/metrics_logger.dart';
import 'package:fastpix_flutter_core_data/src/services/service_locator.dart';
import 'package:fastpix_flutter_core_data/src/services/configuration/configuration_service.dart';
import 'package:fastpix_flutter_core_data/src/storage/event_store.dart';
import 'package:fastpix_flutter_core_data/src/util/utils.dart';

class SessionExpiredException implements Exception {
  final String message;

  SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

class EventDispatcher {
  // Process-wide singleton. The previous code constructed `EventDispatcher()`
  // from three different places (FastPixMetrics, AppLifecycleHandler,
  // DisposeManager) and quietly got three different queues. Make it explicit.
  static EventDispatcher? _instance;

  factory EventDispatcher() => _instance ??= EventDispatcher._internal();

  EventDispatcher._internal() {
    _configService = ServiceLocator().configurationService;
    _startTimer();
    _initializeNetworkMonitoring();
    // Reload any events that survived a previous process. Fire-and-forget;
    // dispatch() will await the same `ready` future before inserting, so
    // ordering is preserved.
    _seedFromDisk();
  }

  /// Sentinel key used to thread a stored event's DB row id alongside its
  /// payload while it traverses the in-memory queue. Stripped before send.
  static const String _dbIdKey = '_dbId';

  final EventStore _store = EventStore.instance;

  // Lock mechanism to prevent race conditions
  Completer<void>? _currentLock;

  final Duration batchInterval = const Duration(seconds: 10);
  int maxBatchSize = 200;
  int maxQueueSize = 1000;
  // Exponential backoff (mirrors Android's WorkManager policy): 10s, 20s, 40s,
  // 80s, 160s, capped at 5 min. No hard retry cap — events are only dropped
  // when the queue overflows.
  final Duration retryBaseDelay = const Duration(seconds: 10);
  final Duration retryMaxDelay = const Duration(minutes: 5);
  final Duration httpTimeout = const Duration(seconds: 30);
  bool useOverflowQueue = true;

  // Current consecutive-failure counter for backoff computation.
  int _consecutiveFailures = 0;

  // final EventDispatcherConfig config;
  late ConfigurationService _configService;

  // Network monitoring fields
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkAvailable = true;
  bool _isWaitingForNetwork = false;
  Timer? _networkRetryTimer;
  static const Duration _networkCheckInterval = Duration(seconds: 5);

  final Queue<Map<String, dynamic>> _eventQueue =
      Queue<Map<String, dynamic>>();
  final Queue<Map<String, dynamic>> _overflowQueue =
      Queue<Map<String, dynamic>>(); // New overflow queue
  final Map<Map<String, dynamic>, int> _failedEvents = {};
  Timer? _timer;
  bool _isSending = false;
  StreamController<String>? _logController;

  // Getter for the log stream
  Stream<String> get logStream {
    _logController ??= StreamController<String>.broadcast();
    return _logController!.stream;
  }

  void _log(String message) {
    MetricsLogger.debug('dispatcher', {'message': message});
    _logController?.add(message);
  }

  /// Initialize network connectivity monitoring
  void _initializeNetworkMonitoring() async {
    MetricsLogger.debug('network:monitor:init', {
      'initialAssumedAvailable': _isNetworkAvailable,
    });
    // Check initial network status
    _checkNetworkStatus();

    // Listen to network changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onNetworkStatusChanged);
  }

  /// Check current network status. NOTE: [Utils.checkNetworkType] returns
  /// `"cellular"`, `"wifi"`, or `null` — it NEVER returns the literal
  /// `"NA"`. So treating "any non-null value" as available, and `null` as
  /// unavailable, is the correct semantic.
  Future<void> _checkNetworkStatus() async {
    try {
      final networkType = await Utils.checkNetworkType();
      final wasNetworkAvailable = _isNetworkAvailable;
      _isNetworkAvailable = networkType != null;
      _pushConnectionTypeToConfig(networkType);

      MetricsLogger.debug('network:check', {
        'networkType': networkType ?? '(null)',
        'isAvailable': _isNetworkAvailable,
        'changed': wasNetworkAvailable != _isNetworkAvailable,
      });

      if (wasNetworkAvailable != _isNetworkAvailable) {
        if (_isNetworkAvailable && _isWaitingForNetwork) {
          _log('Network restored - resuming event processing');
          _isWaitingForNetwork = false;
          _networkRetryTimer?.cancel();
          // Trigger immediate processing of queued events
          _processEvents();
        }
      }
    } catch (e) {
      MetricsLogger.debug('network:check:error', {'error': e.toString()});
      // Don't flip _isNetworkAvailable to false on a transient check failure —
      // let the connectivity_plus listener be the source of truth.
    }
  }

  /// Handle network status changes
  void _onNetworkStatusChanged(List<ConnectivityResult> results) {
    final wasNetworkAvailable = _isNetworkAvailable;
    _isNetworkAvailable = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);
    _pushConnectionTypeToConfig(_mapTransportsToConnectionType(results));

    MetricsLogger.debug(
        _isNetworkAvailable ? 'network:online' : 'network:offline', {
      'transports':
          results.map((r) => r.toString().split('.').last).toList(),
      'changed': wasNetworkAvailable != _isNetworkAvailable,
    });

    if (wasNetworkAvailable != _isNetworkAvailable) {
      if (_isNetworkAvailable && _isWaitingForNetwork) {
        _log('Network restored - resuming event processing');
        _isWaitingForNetwork = false;
        _networkRetryTimer?.cancel();
        // Trigger immediate processing of queued events
        _processEvents();
      }
    }
  }

  /// Cache the latest connection type into [ConfigurationService] so every
  /// subsequent event's `vicity` field is populated. The base event reads
  /// it from cache synchronously — see BaseEvent.getBaseEventData.
  void _pushConnectionTypeToConfig(String? connectionType) {
    if (connectionType == null) return;
    _configService.updateConnectionType(connectionType);
  }

  /// Maps a connectivity_plus result list to the same short string we
  /// already produce in [Utils.checkNetworkType] (`"wifi"`/`"cellular"`/
  /// `"ethernet"`/...), so events always carry a meaningful value even
  /// on transports the initial sync check doesn't recognise.
  String? _mapTransportsToConnectionType(List<ConnectivityResult> results) {
    if (results.isEmpty) return null;
    if (results.contains(ConnectivityResult.wifi)) return 'wifi';
    if (results.contains(ConnectivityResult.mobile)) return 'cellular';
    if (results.contains(ConnectivityResult.ethernet)) return 'ethernet';
    if (results.contains(ConnectivityResult.vpn)) return 'vpn';
    if (results.contains(ConnectivityResult.bluetooth)) return 'bluetooth';
    if (results.contains(ConnectivityResult.other)) return 'other';
    return null; // ConnectivityResult.none — truly offline
  }

  /// Wait for network to become available
  void _waitForNetwork() {
    if (!_isWaitingForNetwork) {
      _isWaitingForNetwork = true;
      _log('Waiting for network connectivity to resume...');

      // Start periodic network checking
      _networkRetryTimer = Timer.periodic(_networkCheckInterval, (timer) async {
        _checkNetworkStatus();

        if (_isNetworkAvailable) {
          timer.cancel();
          _isWaitingForNetwork = false;
          _log('Network available - resuming event processing');
          _processEvents();
        }
      });
    }
  }

  /// Persist + queue an event. Does NOT flush — the natural 10s batch timer
  /// or an explicit [flushNow] will move it to the wire. This separation lets
  /// callers enqueue a group of events (e.g. playerReady + viewBegin + play
  /// at session start) and then flush ONCE so they all ship in the same POST.
  Future<bool> dispatch(Map<String, dynamic> event) async {
    // Persist before queueing so a hard kill between insert and send still
    // leaves the event recoverable on next launch. The row id is stamped
    // onto the in-memory copy so we can delete by id after a successful POST.
    final id = await _store.insert(event);
    if (id != null) event[_dbIdKey] = id;
    MetricsLogger.debug('store:inserted', {
      'evna': event['evna'],
      'dbId': id,
    });

    String queueTarget;
    if (_eventQueue.length >= maxQueueSize) {
      if (useOverflowQueue) {
        _overflowQueue.add(event);
        queueTarget = 'overflow';
      } else {
        _log('Queue full - event dropped');
        MetricsLogger.debug('queue:dropped', {
          'evna': event['evna'],
          'reason': 'queue_full',
        });
        return true;
      }
    } else {
      _eventQueue.add(event);
      queueTarget = 'main';
    }
    MetricsLogger.debug('queue:enqueued', {
      'evna': event['evna'],
      'target': queueTarget,
      'mainQueueSize': _eventQueue.length,
      'overflowQueueSize': _overflowQueue.length,
      'failedSize': _failedEvents.length,
    });
    return true;
  }

  /// Caller-driven flush. Use after enqueueing a logically-grouped set of
  /// events (e.g. session-start) so they ship in one HTTP POST instead of
  /// each triggering its own.
  Future<void> flushNow() async {
    MetricsLogger.debug('flush:now', {
      'mainQueueSize': _eventQueue.length,
      'overflowQueueSize': _overflowQueue.length,
      'failedSize': _failedEvents.length,
    });
    await _processEvents();
  }

  /// Load any events left over from a prior process and seed the queue
  /// (oldest first). Events recovered this way are NOT re-inserted into the
  /// store — they already have their row ids from the previous session.
  Future<void> _seedFromDisk() async {
    try {
      final stored = await _store.loadAll();
      if (stored.isEmpty) {
        MetricsLogger.debug('seed:empty');
        return;
      }
      for (final s in stored) {
        s.payload[_dbIdKey] = s.id;
        _eventQueue.add(s.payload);
      }
      MetricsLogger.debug('seed:recovered', {
        'count': stored.length,
        'oldestAgeMs': DateTime.now().millisecondsSinceEpoch -
            stored.first.createdAtMs,
      });
    } catch (e) {
      MetricsLogger.logError('Failed to seed event queue from disk', e);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(batchInterval, (_) => _processEvents());
  }

  // Force immediate processing of events
  Future<void> flush() async {
    await _processEvents();
  }

  /// Best-effort blocking flush for use during SDK shutdown. Drives
  /// [_processEvents] in a loop until the queue drains or we hit the
  /// [maxWait] budget. Bounded so dispose() can't hang forever on a flaky
  /// network.
  Future<void> flushUntilEmptyOrGiveUp(
      {Duration maxWait = const Duration(seconds: 5)}) async {
    MetricsLogger.debug('flush:start', {
      'maxWaitMs': maxWait.inMilliseconds,
      'mainQueueSize': _eventQueue.length,
      'overflowQueueSize': _overflowQueue.length,
      'failedSize': _failedEvents.length,
    });
    final deadline = DateTime.now().add(maxWait);
    while (DateTime.now().isBefore(deadline)) {
      if (_eventQueue.isEmpty &&
          _overflowQueue.isEmpty &&
          _failedEvents.isEmpty) {
        MetricsLogger.debug('flush:done', {'reason': 'drained'});
        return;
      }
      await _processEvents();
      // If the network is gone we won't make progress; bail rather than spin.
      if (!_isNetworkAvailable) {
        MetricsLogger.debug('flush:done', {
          'reason': 'network_unavailable',
          'mainQueueRemaining': _eventQueue.length,
          'overflowRemaining': _overflowQueue.length,
          'failedRemaining': _failedEvents.length,
        });
        return;
      }
    }
    MetricsLogger.debug('flush:done', {
      'reason': 'timeout',
      'mainQueueRemaining': _eventQueue.length,
      'overflowRemaining': _overflowQueue.length,
      'failedRemaining': _failedEvents.length,
    });
  }

  Future<void> _processEvents() async {
    // Make every silent bail visible — these are the points where a missing
    // batch:starting log usually originates.
    if (_isSending) {
      /*MetricsLogger.debug('batch:skipped', {
        'reason': 'already_sending',
        'mainQueueSize': _eventQueue.length,
        'failedSize': _failedEvents.length,
      });*/
      return;
    }
    if (_eventQueue.isEmpty &&
        _failedEvents.isEmpty &&
        _overflowQueue.isEmpty) {
      MetricsLogger.debug('batch:skipped', {'reason': 'all_queues_empty'});
      return;
    }

    // Check network availability before processing
    if (!_isNetworkAvailable) {
      MetricsLogger.debug('batch:skipped', {
        'reason': 'network_unavailable',
        'mainQueueSize': _eventQueue.length,
      });
      _waitForNetwork();
      return;
    }

    _isSending = true;

    try {
      // Move events from overflow queue to main queue if space available
      while (_overflowQueue.isNotEmpty && _eventQueue.length < maxQueueSize) {
        _eventQueue.add(_overflowQueue.removeFirst());
        _log('Moved event from overflow queue to main queue');
      }

      // All previously-failed events are eligible for retry (no hard cap).
      final retryEvents = _failedEvents.keys.toList();

      // Calculate how many new events we can process
      final availableBatchSize = maxBatchSize - retryEvents.length;
      final newEvents = _eventQueue.take(availableBatchSize).toList();

      // Combine failed events with new events
      final eventsToSend = [...retryEvents, ...newEvents];

      // Remove sent events from queues
      for (final event in eventsToSend) {
        _failedEvents.remove(event);
      }
      for (var i = 0; i < newEvents.length; i++) {
        _eventQueue.removeFirst();
      }

      if (eventsToSend.isEmpty) {
        MetricsLogger.debug('batch:skipped', {'reason': 'eventsToSend_empty'});
        return;
      }

      // Backend enforces "one viewId per HTTP request" — a mixed-viewId
      // batch gets 400'd ("Inconsistent values across events"). So we group
      // by veid, sort viewIds by their oldest event's timestamp (drain-old-
      // before-new per the SDK brief), and send ONE POST per viewId. On
      // first failure we stop, re-queue the rest, and back off — that way
      // a poisoned old viewId can't starve newer ones forever (because the
      // backoff still lets the periodic timer retry the same viewId next
      // tick; if it keeps 400ing, that's a separate "drop on 4xx" concern).
      final groups = _groupByViewId(eventsToSend);
      final orderedViewIds = _viewIdsOldestFirst(groups);

      MetricsLogger.debug('batch:starting', {
        'totalEvents': eventsToSend.length,
        'viewIdCount': orderedViewIds.length,
        'viewIdOrder': orderedViewIds,
        'retryEvents': retryEvents.length,
        'newEvents': newEvents.length,
        'mainQueueRemaining': _eventQueue.length,
        'overflowRemaining': _overflowQueue.length,
        'evnaCounts': _summarizeByEvna(eventsToSend),
      });

      int sentBatches = 0;
      int sentEvents = 0;
      bool failed = false;

      for (var i = 0; i < orderedViewIds.length; i++) {
        final viewId = orderedViewIds[i];
        final group = groups[viewId]!;
        final stopwatch = Stopwatch()..start();
        MetricsLogger.debug('viewBatch:posting', {
          'viewId': viewId,
          'eventCount': group.length,
          'evnaCounts': _summarizeByEvna(group),
        });
        final success = await sendEventsToServer(group);
        stopwatch.stop();

        if (success) {
          sentBatches++;
          sentEvents += group.length;
          final sentIds = group
              .map((e) => e[_dbIdKey])
              .whereType<int>()
              .toList();
          if (sentIds.isNotEmpty) {
            await _store.deleteByIds(sentIds);
          }
          MetricsLogger.debug('viewBatch:success', {
            'viewId': viewId,
            'eventCount': group.length,
            'durationMs': stopwatch.elapsedMilliseconds,
            'deletedFromStore': sentIds.length,
          });
        } else {
          // Re-queue this viewId AND all subsequent viewIds we haven't
          // attempted yet — preserves drain-old-before-new ordering on
          // the next tick.
          failed = true;
          for (var j = i; j < orderedViewIds.length; j++) {
            for (final ev in groups[orderedViewIds[j]]!) {
              _failedEvents[ev] = (_failedEvents[ev] ?? 0) + 1;
            }
          }
          _consecutiveFailures++;
          final backoff =
              _isNetworkAvailable ? _backoffDelay() : Duration.zero;
          MetricsLogger.debug('viewBatch:failed', {
            'viewId': viewId,
            'eventCount': group.length,
            'durationMs': stopwatch.elapsedMilliseconds,
            'consecutiveFailures': _consecutiveFailures,
            'parkedForRetry': _failedEvents.length,
            'remainingViewIds':
                orderedViewIds.length - i - 1,
            'nextBackoffMs': backoff.inMilliseconds,
            'networkAvailable': _isNetworkAvailable,
          });
          if (!_isNetworkAvailable) {
            _waitForNetwork();
          } else {
            await Future.delayed(backoff);
          }
          break;
        }
      }

      if (!failed) {
        _consecutiveFailures = 0;
      }
      MetricsLogger.debug('batch:done', {
        'sentBatches': sentBatches,
        'sentEvents': sentEvents,
        'totalViewIds': orderedViewIds.length,
        'parkedForRetry': _failedEvents.length,
      });
    } catch (e) {
      MetricsLogger.logError('Error processing events', e);

      // Check if error was network-related
      if (!_isNetworkAvailable) {
        _log('Network error detected - waiting for connectivity');
        _waitForNetwork();
      }
    } finally {
      _isSending = false;
    }
  }

  Map<String, int> _summarizeByEvna(List<Map<String, dynamic>> events) {
    final counts = <String, int>{};
    for (final e in events) {
      final name = (e['evna'] as String?) ?? '(none)';
      counts[name] = (counts[name] ?? 0) + 1;
    }
    return counts;
  }

  /// Groups events by their `veid` (viewId) while preserving in-group
  /// order. The backend rejects batches that mix viewIds.
  Map<String, List<Map<String, dynamic>>> _groupByViewId(
      List<Map<String, dynamic>> events) {
    final groups = <String, List<Map<String, dynamic>>>{};
    for (final e in events) {
      final vid = (e['veid'] as String?) ?? '';
      groups.putIfAbsent(vid, () => <Map<String, dynamic>>[]).add(e);
    }
    return groups;
  }

  /// Returns viewIds ordered by the oldest event in each group (drains
  /// older sessions before newer ones, matching the SDK brief).
  List<String> _viewIdsOldestFirst(
      Map<String, List<Map<String, dynamic>>> groups) {
    int minTs(List<Map<String, dynamic>> group) {
      var min = 1 << 62;
      for (final e in group) {
        final ts = e['vitp'];
        if (ts is int && ts < min) min = ts;
      }
      return min;
    }

    final ids = groups.keys.toList();
    ids.sort((a, b) => minTs(groups[a]!).compareTo(minTs(groups[b]!)));
    return ids;
  }

  /// Computes exponential backoff: base * 2^(failures-1), capped at max.
  /// 10s, 20s, 40s, 80s, 160s, 300s (cap)...
  Duration _backoffDelay() {
    if (_consecutiveFailures <= 0) return retryBaseDelay;
    final multiplier = 1 << (_consecutiveFailures - 1).clamp(0, 30);
    final ms = retryBaseDelay.inMilliseconds * multiplier;
    return Duration(
        milliseconds: ms.clamp(0, retryMaxDelay.inMilliseconds));
  }

  Future<bool> sendEventsToServer(List<Map<String, dynamic>> events) async {
    try {
      // Double-check network availability before making the request
      if (!_isNetworkAvailable) {
        _log('Network unavailable - skipping API call');
        return false;
      }

      final baseUrl = _configService.baseUrl;
      // Strip the internal _dbId tracking key so it never reaches the server.
      final wireEvents = events
          .map((e) => {
                for (final entry in e.entries)
                  if (entry.key != _dbIdKey) entry.key: entry.value,
              })
          .toList();
      final request = {
        "metadata": {
          "transmission_timestamp":
              _configService.currentTimeStamp(),
        },
        "events": wireEvents
      };
      final body = jsonEncode(request);

      MetricsLogger.debug('http:posting', {
        'url': baseUrl,
        'eventCount': wireEvents.length,
        'bodyBytes': body.length,
        'timeoutMs': httpTimeout.inMilliseconds,
        'body': body,
      });

      final stopwatch = Stopwatch()..start();
      final http.Response response = await http
          .post(Uri.parse(baseUrl), body: body)
          .timeout(httpTimeout);
      stopwatch.stop();

      final bool success = response.statusCode == 200;
      MetricsLogger.debug('http:response', {
        'statusCode': response.statusCode,
        'durationMs': stopwatch.elapsedMilliseconds,
        'responseBytes': response.bodyBytes.length,
        'success': success,
        'body': response.body,
      });
      return success;
    } catch (ex) {
      // Check if the error is network-related
      final errorMessage = ex.toString().toLowerCase();
      final isNetworkErr = errorMessage.contains('socket') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('network') ||
          errorMessage.contains('timeout');
      if (isNetworkErr) {
        _log('Network error detected: $ex');
        _isNetworkAvailable = false;
      } else {
        MetricsLogger.logError(
            'Non-network error sending events to server', ex);
      }
      MetricsLogger.debug('http:exception', {
        'error': ex.toString(),
        'networkRelated': isNetworkErr,
        'eventCount': events.length,
      });
      return false;
    }
  }

  // Get current queue statistics
  Map<String, int> getQueueStats() {
    return {
      'queuedEvents': _eventQueue.length,
      'overflowEvents': _overflowQueue.length,
      'failedEvents': _failedEvents.length,
      'totalEvents':
          _eventQueue.length + _overflowQueue.length + _failedEvents.length,
    };
  }

  // Get network status
  Map<String, dynamic> getNetworkStatus() {
    return {
      'isNetworkAvailable': _isNetworkAvailable,
      'isWaitingForNetwork': _isWaitingForNetwork,
    };
  }

  // Clean up method for tests and app shutdown
  Future<void> dispose(bool force) async {
    try {
      // Step 1: Flush any pending events
      await flush();

      // Step 2: Cancel all timers and subscriptions
      _timer?.cancel();
      _networkRetryTimer?.cancel();
      _connectivitySubscription?.cancel();

      // Step 3: Clear all references
      _timer = null;
      _networkRetryTimer = null;
      _connectivitySubscription = null;

      // Step 4: Clear all queues and state. We do NOT clear the DB here —
      // any events still pending on disk will be replayed on next launch.
      _eventQueue.clear();
      _overflowQueue.clear();
      _failedEvents.clear();

      _currentLock?.complete();
      _currentLock = null;
      _isWaitingForNetwork = false;
      _isNetworkAvailable = true;
      _isSending = false;

      // Step 6: Close log controller
      _logController?.close();
      _logController = null;

      // Step 7: Drop the singleton reference so the next FastPixMetrics
      // session gets a fresh dispatcher (fresh timers, fresh subscriptions).
      _instance = null;
    } catch (e) {
      print('Error during EventDispatcher dispose: $e');
      // Continue with cleanup even if some parts fail
    }
  }


}
