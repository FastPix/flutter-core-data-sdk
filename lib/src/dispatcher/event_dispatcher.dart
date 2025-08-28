import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fastpix_flutter_core_data/src/logger/metrics_logger.dart';
import 'package:fastpix_flutter_core_data/src/services/service_locator.dart';
import 'package:fastpix_flutter_core_data/src/services/configuration/configuration_service.dart';
import 'package:fastpix_flutter_core_data/src/event/pulse_event.dart';
import 'package:fastpix_flutter_core_data/src/util/utils.dart';

class SessionExpiredException implements Exception {
  final String message;

  SessionExpiredException(this.message);

  @override
  String toString() => 'SessionExpiredException: $message';
}

class EventDispatcher {
  EventDispatcher() {
    _configService = ServiceLocator().configurationService;
    _startTimer();
    _initializeNetworkMonitoring();
  }

  // Lock mechanism to prevent race conditions
  Completer<void>? _currentLock;

  final Duration batchInterval = const Duration(seconds: 10);
  int maxBatchSize = 200;
  int maxQueueSize = 1000;
  int maxRetries = 3;
  final Duration retryDelay = const Duration(seconds: 2);
  bool useOverflowQueue = true;

  // final EventDispatcherConfig config;
  late ConfigurationService _configService;

  // Add fields for deduplication and pulse event scheduling
  Map<String, String?>? _lastSentEvent;

  // Use a Set to track unique events and prevent duplicates (excluding pulse events)
  final Set<String> _recentEvents = {};

  // Add ViewWatchTimeCounter instance

  // Network monitoring fields
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isNetworkAvailable = true;
  bool _isWaitingForNetwork = false;
  Timer? _networkRetryTimer;
  static const Duration _networkCheckInterval = Duration(seconds: 5);

  final Queue<Map<String, String?>> _eventQueue = Queue<Map<String, String?>>();
  final Queue<Map<String, String?>> _overflowQueue =
      Queue<Map<String, String?>>(); // New overflow queue
  final Map<Map<String, String?>, int> _failedEvents = {};
  Timer? _timer;
  bool _isSending = false;
  StreamController<String>? _logController;

  // Getter for the log stream
  Stream<String> get logStream {
    _logController ??= StreamController<String>.broadcast();
    return _logController!.stream;
  }

  void _log(String message) {
    MetricsLogger.logEvent('EventDispatcher', {'message': message});
    _logController?.add(message);
  }

  /// Initialize network connectivity monitoring
  void _initializeNetworkMonitoring() async {
    // Check initial network status
    _checkNetworkStatus();

    // Listen to network changes
    _connectivitySubscription =
        Connectivity().onConnectivityChanged.listen(_onNetworkStatusChanged);
  }

  /// Check current network status
  Future<void> _checkNetworkStatus() async {
    try {
      final networkType = await Utils.checkNetworkType();
      final wasNetworkAvailable = _isNetworkAvailable;
      _isNetworkAvailable = networkType != "NA";

      if (wasNetworkAvailable != _isNetworkAvailable) {
        _log(
            'Network status changed: ${_isNetworkAvailable ? "Available" : "Unavailable"}');

        if (_isNetworkAvailable && _isWaitingForNetwork) {
          _log('Network restored - resuming event processing');
          _isWaitingForNetwork = false;
          _networkRetryTimer?.cancel();
          // Trigger immediate processing of queued events
          _processEvents();
        }
      }
    } catch (e) {
      _log('Error checking network status: $e');
      _isNetworkAvailable = false;
    }
  }

  /// Handle network status changes
  void _onNetworkStatusChanged(List<ConnectivityResult> results) {
    final wasNetworkAvailable = _isNetworkAvailable;
    _isNetworkAvailable = results.isNotEmpty &&
        results.any((result) => result != ConnectivityResult.none);

    if (wasNetworkAvailable != _isNetworkAvailable) {
      _log(
          'Network connectivity changed: ${_isNetworkAvailable ? "Connected" : "Disconnected"}');

      if (_isNetworkAvailable && _isWaitingForNetwork) {
        _log('Network restored - resuming event processing');
        _isWaitingForNetwork = false;
        _networkRetryTimer?.cancel();
        // Trigger immediate processing of queued events
        _processEvents();
      }
    }
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

  Future<bool> dispatch(Map<String, String?> event) async {
    if (event['evna'] == PlayerEvent.viewBegin.name ||
        event['evna'] == PlayerEvent.playerReady.name) {
      _eventQueue.add(event);
      _lastSentEvent = event;
      await _processEvents();
      return true;
    }

    if(event['evna'] == PlayerEvent.playing.name){
      _lastSentEvent = event;
      _eventQueue.add(event);
      _schedulePulseEvent();
      return true;
    }

    if (_eventQueue.length >= maxQueueSize) {
      if (useOverflowQueue) {
        print("Event Dispatcher: Using OverFlow queue");
        _overflowQueue.add(event);
      } else {
        _log('Queue full - event dropped');
      }
    } else {
      print("Event Dispatcher: Using Normal queue ${event['evna']}");
      _eventQueue.add(event);
    }
    _lastSentEvent = event;
    _cancelPulseTimer();
    return true;
  }

  Timer? _pulseTimer;

  void _schedulePulseEvent() {
    if (_pulseTimer == null || _pulseTimer?.isActive == false) {
      _log('Scheduling pulse event due to duplicate detection');
      _pulseTimer = Timer.periodic(Duration(seconds: 1), (timer) async {
        final pulseEvent = await PulseEvent.createPulseEvent();
        final pulseEventJson = pulseEvent.toJson();
        _eventQueue.add(pulseEventJson);
      });
    } else {
      _log('Pulse event already scheduled, skipping duplicate request');
    }
  }

  void _cancelPulseTimer() {
    if (_pulseTimer?.isActive == true) {
      _pulseTimer?.cancel();
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

  Future<void> _processEvents() async {
    if (_isSending ||
        (_eventQueue.isEmpty &&
            _failedEvents.isEmpty &&
            _overflowQueue.isEmpty)) {
      return;
    }

    // Check network availability before processing
    if (!_isNetworkAvailable) {
      _log('Network unavailable - waiting for connectivity');
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

      // Prioritize failed events based on retry count
      final retryEvents = _failedEvents.entries
          .where((entry) => entry.value < maxRetries)
          .map((entry) => entry.key)
          .toList();

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
        return;
      }

      final success = await sendEventsToServer(eventsToSend);

      if (!success) {
        // If send fails, add events to failed queue with retry count
        for (final event in eventsToSend) {
          final retryCount = _failedEvents[event] ?? 0;
          if (retryCount < maxRetries) {
            _failedEvents[event] = retryCount + 1;
            _log(
                'Event retry ${retryCount + 1}/$maxRetries | ${eventsToSend.toString()}');
          } else {
            MetricsLogger.logError('Event dropped after $maxRetries retries');
          }
        }

        // Check if failure was due to network issues
        if (!_isNetworkAvailable) {
          _log(
              'Network unavailable after failed request - waiting for connectivity');
          _waitForNetwork();
        } else {
          // Wait before next retry only if network is available
          await Future.delayed(retryDelay);
        }
      }
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

  // Simulated API call with random success/failure
  Future<bool> sendEventsToServer(List<Map<String, String?>> events) async {
    try {
      // Double-check network availability before making the request
      if (!_isNetworkAvailable) {
        _log('Network unavailable - skipping API call');
        return false;
      }

      final baseUrl = _configService.baseUrl;
      final request = {
        "metadata": {
          "transmission_timestamp":
              _configService.currentTimeStamp().toString(),
        },
        "events": events
      };

      final http.Response response =
          await http.post(Uri.parse(baseUrl), body: jsonEncode(request));

      final bool success = response.statusCode == 200;
      return success;
    } catch (ex) {
      // Check if the error is network-related
      final errorMessage = ex.toString().toLowerCase();
      if (errorMessage.contains('socket') ||
          errorMessage.contains('connection') ||
          errorMessage.contains('network') ||
          errorMessage.contains('timeout')) {
        _log('Network error detected: $ex');
        // Update network status to unavailable
        _isNetworkAvailable = false;
      } else {
        MetricsLogger.logError(
            'Non-network error sending events to server', ex);
      }

      MetricsLogger.logError(
          'Failed to send events - will retry. Count: $events');
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
      _cancelPulseTimer();
      _pulseTimer = null;

      // Step 3: Clear all references
      _timer = null;
      _networkRetryTimer = null;
      _connectivitySubscription = null;

      // Step 4: Clear all queues and state
      _eventQueue.clear();
      _overflowQueue.clear();
      _failedEvents.clear();
      _recentEvents.clear();
      _lastSentEvent = null;

      _currentLock?.complete();
      _currentLock = null;
      _isWaitingForNetwork = false;
      _isNetworkAvailable = true;
      _isSending = false;

      // Step 6: Close log controller
      _logController?.close();
      _logController = null;
    } catch (e) {
      print('Error during EventDispatcher dispose: $e');
      // Continue with cleanup even if some parts fail
    }
  }

  /// Clear recent events cache - useful for testing or when you want to reset duplicate detection
  void clearRecentEvents() {
    _recentEvents.clear();
    _log('Recent events cache cleared');
  }

  /// Get duplicate prevention statistics
  Map<String, dynamic> getDuplicatePreventionStats() {
    return {
      'recentEventsCount': _recentEvents.length,
      'lastSentEvent': _lastSentEvent,
      'isDuplicatePreventionActive': true,
      'pulseTimerActive': _pulseTimer?.isActive ?? false,
      'recentEvents': _recentEvents.toList(),
    };
  }
}
