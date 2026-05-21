import 'dart:async';

import 'package:fastpix_flutter_core_data/src/dispatcher/event_submission.dart';
import 'package:fastpix_flutter_core_data/src/dispatcher/submission_pipeline.dart';
import 'package:fastpix_flutter_core_data/src/event/ended_event.dart';
import 'package:fastpix_flutter_core_data/src/logger/metrics_logger.dart';
import 'package:fastpix_flutter_core_data/src/model/change_track.dart';
import 'package:fastpix_flutter_core_data/src/util/scaling_tracker.dart';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';
import '../fastpix_flutter_core_data.dart';
import 'event/event_exposer.dart';
import 'metrics/metrics_state_manager.dart';
import 'services/service_locator.dart';
import 'services/configuration/configuration_service.dart';
import 'lifecycle/app_lifecycle_handler.dart';

class FastPixMetrics {
  final MetricsConfiguration? metricsConfiguration;
  final PlayerObserver playerObserver;
  late final EventDispatcher _eventDispatcher;
  final MetricsStateManager _metricsStateManager;
  final ConfigurationService _configService;
  ViewWatchTimeCounter? _viewWatchTimeCounter;

  // dispose() can legitimately be called twice: once by the host (back press
  // → State.dispose() → disposeMetrix()) and once by AppLifecycleHandler on
  // detached (OS-driven app kill). Guard so the second call is a no-op.
  bool _isDisposed = false;

  // Drains EventSubmissions in submission order. Replaces the old dispatch
  // lock, which deadlocked when an event's builder hung (e.g., a player
  // platform-channel call during codec init). The pipeline serialises
  // build+enqueue without holding any lock across awaits.
  late final SubmissionPipeline _pipeline;

  FastPixMetrics._builder(FastPixMetricsBuilder builder)
      : metricsConfiguration = builder._metricsConfiguration,
        playerObserver = builder._playerObserver!,
        _metricsStateManager = MetricsStateManager(),
        _configService = ServiceLocator().configurationService {
    // Plumb the host's debug-logging preference into the logger before any
    // pipeline activity so the very first events show up in the console.
    MetricsLogger.enabled =
        builder._metricsConfiguration?.enableLogging ?? false;
    MetricsLogger.debug('sdk:init', {
      'workspaceId': builder._metricsConfiguration?.workspaceId,
      'beaconUrl': builder._metricsConfiguration?.beaconUrl,
    });
    _eventDispatcher = EventDispatcher();
    ViewWatchTimeCounter.viewWatchTime = 0;
    // Initialize ConfigurationService for new video session
    _configService.initializeForNewVideoSession();
    _viewWatchTimeCounter = ViewWatchTimeCounter();
    // Configure the configuration service with the metrics configuration
    _configService.updatePlayerObserver(playerObserver);
    if (metricsConfiguration?.workspaceId != null) {
      _configService.updateWorkSpaceId(metricsConfiguration!.workspaceId!);
    }
    if (metricsConfiguration?.beaconUrl != null) {
      _configService.updateBeaconUrl(url: metricsConfiguration!.beaconUrl!);
    } else {
      _configService.updateBeaconUrl();
    }
    if (metricsConfiguration?.customData != null) {
      _configService.updateCustomData(metricsConfiguration?.customData);
    }
    if (metricsConfiguration?.videoData != null) {
      _configService.updateVideoData(metricsConfiguration?.videoData);
    }
    if (metricsConfiguration?.playerData != null) {
      _configService.updatePlayerData(metricsConfiguration!.playerData!);
    }
    if (metricsConfiguration?.viewerId != null) {
      _configService.updateViewerId(metricsConfiguration!.viewerId!);
    }
    _configService.updateViewId(_configService.generateUUID());
    _configService.setPlayerId(_configService.generateUUID());
    _configService.updateBaseURL();

    // Reset metrics state when initializing
    _metricsStateManager.reset();
    ScalingTracker.instance.reset();

    _pipeline = SubmissionPipeline(handler: _processSubmission);

    // Register an "OS is killing the app" callback so that even if the host
    // never calls dispose() (e.g. user swipes the app away on iOS), the SDK
    // still gets a chance to fire viewCompleted before the process dies.
    AppLifecycleHandler().setOnAppKill(() async {
      MetricsLogger.debug('sdk:onAppKill:triggered');
      await dispose(true);
    });
  }

  void _cancelViewWatchTime() {
    if (_viewWatchTimeCounter?.isRunning ?? false) {
      _viewWatchTimeCounter?.cancel();
    }
  }

  /// Handles ViewWatchTimeCounter start/stop based on event type
  void _startViewWatchTime() {
    if (!(_viewWatchTimeCounter?.isRunning ?? false)) {
      _viewWatchTimeCounter?.start();
    }
  }

  /// Public entry point the host calls for every player event.
  ///
  /// Runs in two phases:
  ///   1. **Synchronous** (this method): logs, updates ChangeTrack if the
  ///      event carries quality-change attributes, hands an
  ///      [EventSubmission] to [_pipeline]. Returns the submission's
  ///      completion future so callers like `dispose()` can await
  ///      end-of-build.
  ///   2. **Asynchronous** ([_processSubmission], driven by the pipeline
  ///      in submission order): builds the event, persists it, hands it to
  ///      [_eventDispatcher] to upload.
  Future<void> dispatchEvent(PlayerEvent event,
      {Map<String, String>? attributes}) async {
    MetricsLogger.debug('dispatch:received', {
      'event': event.name,
      if (attributes != null) 'attributes': attributes,
    });
    // ChangeTrack is only meaningful for variant/quality changes — and
    // VariantChangedEvent reads it at build time. Update synchronously
    // here so the queued submission sees the right data even if the host
    // fires a follow-up dispatchEvent that mutates ChangeTrack again
    // before the variantChanged submission gets built.
    if (attributes != null &&
        (attributes.containsKey('height') ||
            attributes.containsKey('width') ||
            attributes.containsKey('bitrate') ||
            attributes.containsKey('frameRate') ||
            attributes.containsKey('codecs') ||
            attributes.containsKey('mimeType'))) {
      final changeTrack = ChangeTrack();
      changeTrack.height = attributes['height'];
      changeTrack.width = attributes['width'];
      changeTrack.bitrate = attributes['bitrate'];
      changeTrack.frameRate = attributes['frameRate'];
      changeTrack.codec = attributes['codecs'];
      changeTrack.mimeType = attributes['mimeType'];
      _configService.updateChangeTrack(changeTrack);
    }
    return _pipeline.submit(EventSubmission(event, attributes));
  }

  /// Called by [_pipeline] for each submission, strictly one at a time
  /// in submission order. Builds the event, queues it, and for
  /// session-start events triggers an immediate flush.
  Future<void> _processSubmission(EventSubmission s) async {
    MetricsLogger.debug('process:start', {'event': s.eventType.name});
    final event = s.eventType;
    final attributes = s.attributes;
    Map<String, dynamic>? builtJson;
    switch (event) {
      case PlayerEvent.playerReady:
        _startViewWatchTime();
        builtJson = (await PlayerReadyEvent.createPlayerReadyEvent()).toJson();
        break;
      case PlayerEvent.viewBegin:
        if (!_configService.state.isViewBeginCalled) {
          _startViewWatchTime();
          _configService.updateIsViewBeginCalled();
          _configService
              .updateViewPlayTimeStamp(_configService.currentTimeStamp());
        }
        builtJson = (await ViewBeginEvent.createViewBeginEvent()).toJson();
        break;
      case PlayerEvent.play:
        _startViewWatchTime();
        builtJson = (await PlayEvent.createPlayEvent()).toJson();
        break;
      case PlayerEvent.pause:
        _cancelViewWatchTime();
        builtJson = (await PauseEvent.createPauseEvent()).toJson();
        break;
      case PlayerEvent.playing:
        _startViewWatchTime();
        builtJson = (await PlayingEvent.createPlayingEvent()).toJson();
        break;
      case PlayerEvent.buffering:
        _startViewWatchTime();
        builtJson = (await BufferingEvent.createBufferingEvent()).toJson();
        break;
      case PlayerEvent.buffered:
        builtJson = (await BufferedEvent.createBufferedEvent()).toJson();
        break;
      case PlayerEvent.seeking:
        builtJson = (await SeekingEvent.createSeekingEvent()).toJson();
        break;
      case PlayerEvent.seeked:
        builtJson = (await SeekedEvent.createSeekedEvent()).toJson();
        break;
      case PlayerEvent.pulse:
        builtJson = (await PulseEvent.createPulseEvent()).toJson();
        break;
      case PlayerEvent.ended:
        _cancelViewWatchTime();
        builtJson = (await EndedEvent.createEndedEvent()).toJson();
        break;
      case PlayerEvent.viewCompleted:
        MetricsLogger.debug('process:viewCompleted:building');
        _cancelViewWatchTime();
        final overrideStr = attributes?['playheadOverride'];
        final override = overrideStr == null ? null : int.tryParse(overrideStr);
        try {
          // Sync build — no `await`, no microtask hop. See the doc on
          // ViewCompletedEvent.createViewCompletedEvent for why.
          builtJson = ViewCompletedEvent.createViewCompletedEvent(
            playheadOverride: override,
          ).toJson();
          MetricsLogger.debug('process:viewCompleted:built', {
            'bodyKeys': builtJson.keys.length,
          });
        } catch (e, st) {
          MetricsLogger.logError(
              'process:viewCompleted:build_failed', '$e\n$st');
          rethrow;
        }
        break;
      case PlayerEvent.variantChanged:
        builtJson =
            (await VariantChangedEvent.createVariantChangeEvent()).toJson();
        break;
      case PlayerEvent.error:
        builtJson = (await ErrorEvent.createErrorEvent()).toJson();
        break;
      case PlayerEvent.requestCompleted:
        builtJson = (await RequestCompletedEvent.createRequestCompletedEvent(
          requestId: attributes?['requestId'] ?? '',
          requestUrl: attributes?['requestUrl'] ?? '',
          requestMethod: attributes?['requestMethod'] ?? '',
          requestResponseHeaders: attributes?['requestResponseHeaders'],
          requestHostName: attributes?['requestHostName'],
          requestCancel: attributes?['requestCancel'],
        ))
            .toJson();
        break;
      case PlayerEvent.requestCanceled:
        builtJson = (await RequestCancelledEvent.createRequestCancelledEvent(
          requestId: attributes?['requestId'] ?? '',
          requestUrl: attributes?['requestUrl'] ?? '',
          requestMethod: attributes?['requestMethod'] ?? '',
          requestHostName: attributes?['requestHostName'],
          requestCancel: attributes?['requestCancel'],
        ))
            .toJson();
        break;
      case PlayerEvent.requestFailed:
        builtJson = (await RequestFailedEvent.createRequestFailedEvent(
          requestId: attributes?['requestId'] ?? '',
          requestUrl: attributes?['requestUrl'] ?? '',
          requestMethod: attributes?['requestMethod'] ?? '',
          requestError: attributes?['requestError'] ?? '',
          requestHostName: attributes?['requestHostName'],
          requestErrorText: attributes?['requestErrorText'],
        ))
            .toJson();
        break;
    }

    MetricsLogger.debug('process:dispatching', {'event': event.name});
    await _eventDispatcher.dispatch(builtJson);

    // Session-start events are time-sensitive — kick a flush right away
    // (fire-and-forget; the dispatcher serialises its own sends via
    // `_isSending`). viewCompleted also gets an immediate flush because
    // it's the terminal event of the session and dispose() needs it on
    // the wire before tearing down.
    if (event == PlayerEvent.playerReady ||
        event == PlayerEvent.viewBegin ||
        event == PlayerEvent.viewCompleted) {
      unawaited(_eventDispatcher.flushNow());
    }
    MetricsLogger.debug('process:done', {'event': event.name});
  }

  /// Builds and dispatches viewCompleted at dispose time, **bypassing the
  /// SubmissionPipeline**.
  ///
  /// Rationale: at dispose() time the host has already detached its
  /// player-event listeners, so no concurrent submissions can arrive that
  /// would need ordering. Empirically (Android `detached` window) the
  /// pipeline's `Stream.asyncMap` indirection sometimes fails to deliver
  /// the final event in time before the OS reclaims the process. Calling
  /// `_processSubmission` directly here removes that indirection — the
  /// event is built, persisted, queued, and flushed synchronously to the
  /// dispose Future.
  Future<void> _throwViewCompletedEvent({int? playheadOverride}) async {
    MetricsLogger.debug('sdk:viewCompleted:building', {
      'playheadOverride': playheadOverride,
    });
    final attrs = playheadOverride == null
        ? null
        : <String, String>{'playheadOverride': playheadOverride.toString()};
    await _processSubmission(
      EventSubmission(PlayerEvent.viewCompleted, attrs),
    );
  }

  /// Tears the SDK down for this video session.
  ///
  /// IMPORTANT: the host should NOT dispose its player controller before
  /// calling this — the viewCompleted event is built from `playerObserver`
  /// queries (player width/height, playhead, duration, etc.) and needs the
  /// player alive. Call this first, then dispose the player.
  ///
  /// [playheadOverride] mirrors Android's `release(playheadTimeOverride)`:
  /// pass a final playhead in ms if you've already advanced past it locally
  /// (e.g. on a `finished` event where the player has reset to 0).
  Future<void> dispose(bool force, {int? playheadOverride}) async {
    // Idempotent — see [_isDisposed] declaration.
    if (_isDisposed) {
      MetricsLogger.debug(
          'sdk:dispose:skipped', {'reason': 'already_disposed'});
      return;
    }
    _isDisposed = true;
    MetricsLogger.debug('sdk:dispose:start', {
      'force': force,
      'playheadOverride': playheadOverride,
    });
    // 0. Unhook lifecycle FIRST so a concurrent app-kill callback can't
    //    re-enter dispose mid-shutdown.
    AppLifecycleHandler().setOnAppKill(null);
    // 1. Submit viewCompleted via the pipeline. await returns once it's
    //    been built + persisted + queued (lands AFTER any in-flight pre-
    //    dispose submissions).
    await _throwViewCompletedEvent(playheadOverride: playheadOverride);
    // 2. Stop accepting new submissions. Any host calls after this point
    //    are no-ops (logged).
    await _pipeline.close();
    // 3. Drain the upload queue (incl. viewCompleted) to the wire with a
    //    bounded wait so we don't hang on a flaky network.
    await _eventDispatcher.flushUntilEmptyOrGiveUp();
    // 4. Stop ticking the watch-time counter.
    _cancelViewWatchTime();
    _viewWatchTimeCounter?.dispose();
    _viewWatchTimeCounter = null;
    // 5. Tear down the dispatcher (timers, subscriptions, queues). Any
    //    events still on disk will be replayed on next SDK init.
    await _eventDispatcher.dispose(true);
    await DisposeManager.disposeAll(force);
    MetricsLogger.debug('sdk:dispose:done');
  }
}

/// Comprehensive dispose manager to ensure proper cleanup order and complete state reset
class DisposeManager {
  static Future<void> disposeAll(bool force) async {
    try {
      // Step 1: Dispose event dispatcher first (stops all event processing)
      final eventDispatcher = EventDispatcher();
      await eventDispatcher.dispose(force);

      // Step 2: Reset all singleton services
      final serviceLocator = ServiceLocator();
      await serviceLocator.dispose();

      // Step 4: Force reset metrics state manager
      MetricsStateManager.forceResetForVideoSwitch();

      // Step 5: Clear the lifecycle hook (set during _builder). We do NOT
      // detach the WidgetsBindingObserver — the handler is a process-wide
      // singleton; the next FastPixMetrics session needs the observer still
      // wired so it can re-register its own onAppKill callback.
      AppLifecycleHandler().setOnAppKill(null);

      // Step 6: Global dispose of ViewWatchTimeCounter (do this last to ensure no timers are running)
      ViewWatchTimeCounter.disposeAll();
    } catch (e) {
      print('Error during comprehensive dispose: $e');
      // Continue with cleanup even if some parts fail
    }
  }
}

class FastPixMetricsBuilder {
  MetricsConfiguration? _metricsConfiguration;
  PlayerObserver? _playerObserver;

  FastPixMetricsBuilder setMetricsConfiguration(
      MetricsConfiguration metricsConfiguration) {
    _metricsConfiguration = metricsConfiguration;
    return this;
  }

  FastPixMetricsBuilder setPlayerObserver(PlayerObserver playerObserver) {
    _playerObserver = playerObserver;
    return this;
  }

  FastPixMetrics build() {
    if (_metricsConfiguration == null) {
      throw Exception("MetricsConfiguration is required");
    }
    if (_playerObserver == null) {
      throw Exception("PlayerObserver is required");
    }
    return FastPixMetrics._builder(this);
  }
}
