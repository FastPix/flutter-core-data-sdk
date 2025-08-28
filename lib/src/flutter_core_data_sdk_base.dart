import 'package:fastpix_flutter_core_data/src/event/ended_event.dart';
import 'package:fastpix_flutter_core_data/src/model/change_track.dart';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';
import '../flutter_core_data_sdk.dart';
import 'event/event_exposer.dart';
import 'metrics/metrics_state_manager.dart';
import 'services/service_locator.dart';
import 'services/configuration/configuration_service.dart';
import 'lifecycle/app_lifecycle_handler.dart';
import 'util/helper.dart';

class FastPixMetrics {
  final MetricsConfiguration? metricsConfiguration;
  final PlayerObserver playerObserver;
  late final EventDispatcher _eventDispatcher;
  final MetricsStateManager _metricsStateManager;
  final ConfigurationService _configService;
  late final AppLifecycleHandler _lifecycleHandler;
  ViewWatchTimeCounter? _viewWatchTimeCounter;

  FastPixMetrics._builder(FastPixMetricsBuilder builder)
      : metricsConfiguration = builder._metricsConfiguration,
        playerObserver = builder._playerObserver!,
        _metricsStateManager = MetricsStateManager(),
        _configService = ServiceLocator().configurationService {
    _eventDispatcher = EventDispatcher();
    _lifecycleHandler = AppLifecycleHandler();
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
      _configService.updateBeaconUrl(metricsConfiguration!.beaconUrl!);
    }
    if (metricsConfiguration?.customData != null) {
      _configService.updateCustomData(metricsConfiguration!.customData!);
    }
    if (metricsConfiguration?.videoData != null) {
      _configService.updateVideoData(metricsConfiguration!.videoData!);
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

  Future<void> dispatchEvent(PlayerEvent event,
      {Map<String, String>? attributes}) async {
    if (attributes != null) {
      final changeTrack = ChangeTrack();
      changeTrack.height = attributes['height'];
      changeTrack.width = attributes['width'];
      changeTrack.bitrate = attributes['bitrate'];
      changeTrack.frameRate = attributes['frameRate'];
      changeTrack.codec = attributes['codecs'];
      changeTrack.mimeType = attributes['mimeType'];
      _configService.updateChangeTrack(changeTrack);
    }
    switch (event) {
      case PlayerEvent.playerReady:
      case PlayerEvent.viewBegin:
      case PlayerEvent.play:
        _startViewWatchTime();
        if (!_configService.state.isViewBeginCalled) {
          _configService.updateIsViewBeginCalled();
          _configService
              .updateViewPlayTimeStamp(_configService.currentTimeStamp());
          final playerReadyEvent =
              await PlayerReadyEvent.createPlayerReadyEvent();
          _eventDispatcher.dispatch(playerReadyEvent.toJson());
          final viewBeginEvent = await ViewBeginEvent.createViewBeginEvent();
          _eventDispatcher.dispatch(viewBeginEvent.toJson());
        }
        final playEvent = await PlayEvent.createPlayEvent();
        _eventDispatcher.dispatch(playEvent.toJson());
        break;
      case PlayerEvent.pause:
        _cancelViewWatchTime();
        final pauseEvent = await PauseEvent.createPauseEvent();
        _eventDispatcher.dispatch(pauseEvent.toJson());
        break;
      case PlayerEvent.playing:
        _startViewWatchTime();
        final playingEvent = await PlayingEvent.createPlayingEvent();
        _eventDispatcher.dispatch(playingEvent.toJson());
        break;
      case PlayerEvent.buffering:
        _startViewWatchTime();
        final bufferingEvent = await BufferingEvent.createBufferingEvent();
        _eventDispatcher.dispatch(bufferingEvent.toJson());
        break;
      case PlayerEvent.buffered:
        final bufferedEvent = await BufferedEvent.createBufferedEvent();
        _eventDispatcher.dispatch(bufferedEvent.toJson());
        break;
      case PlayerEvent.seeking:
        final seekingEvent = await SeekingEvent.createSeekingEvent();
        _eventDispatcher.dispatch(seekingEvent.toJson());
        break;
      case PlayerEvent.seeked:
        final seekedEvent = await SeekedEvent.createSeekedEvent();
        _eventDispatcher.dispatch(seekedEvent.toJson());
        break;
      case PlayerEvent.pulse:
        break;
      case PlayerEvent.ended:
        _cancelViewWatchTime();
        final endedEvent = await EndedEvent.createEndedEvent();
        _eventDispatcher.dispatch(endedEvent.toJson());
        break;
      case PlayerEvent.viewCompleted:
        break;
      case PlayerEvent.variantChanged:
        _startViewWatchTime();
        final variantChangedEvent =
            await VariantChangeEvent.createVariantChangeEvent();
        _eventDispatcher.dispatch(variantChangedEvent.toJson());
        break;
      case PlayerEvent.error:
        _cancelViewWatchTime();
        final errorEvent = await ErrorEvent.createErrorEvent();
        _eventDispatcher.dispatch(errorEvent.toJson());
        break;
    }
  }

  Future<void> _throwViewCompletedEvent() async {
    final viewCompletedEvent =
        await ViewCompletedEvent.createViewCompletedEvent(
      videoContentPlaybackTime:
          _configService.state.viewTotalContentPlayBackTime.toString(),
      viewTotalContentPlayBackTime:
          _configService.state.viewTotalContentPlayBackTime.toString(),
      viewTotalDownScaling:
          _configService.state.viewTotalDownScaling.toString(),
      viewTotalUpScaling: _configService.state.viewTotalUpScaling.toString(),
      viewTotalDownScalePercentage:
          _configService.state.viewMaxDownScalePercentage.toString(),
      viewTotalUpScalePercentage:
          _configService.state.viewMaxUpScalePercentage.toString(),
    );
    _eventDispatcher.dispatch(viewCompletedEvent.toJson());
  }

  Future<void> dispose(bool force) async {
    await _throwViewCompletedEvent();
    _cancelViewWatchTime();
    // Dispose the ViewWatchTimeCounter instance
    _viewWatchTimeCounter?.dispose();
    _viewWatchTimeCounter = null;
    _eventDispatcher.dispose(true);
    // Use the comprehensive dispose manager
    await DisposeManager.disposeAll(force);
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

      // Step 3: Reset ConfigurationHelper singleton
      ConfigurationHelper.instance.reset();

      // Step 4: Force reset metrics state manager
      MetricsStateManager.forceResetForVideoSwitch();

      // Step 5: Dispose lifecycle handler
      final lifecycleHandler = AppLifecycleHandler();
      await lifecycleHandler.dispose();

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
