import 'package:fastpix_flutter_core_data/src/util/device_info_helper.dart';
import '../services/service_locator.dart';
import '../metrics/metrics_state_manager.dart';
import 'event_base.dart';

class PauseEvent extends BaseEvent {
  final String? viewMaxUpScalePercentage;
  final String? viewMaxDownScalePercentage;
  final String? viewTotalContentPlayBackTime;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScaling;
  final String? mimeType;
  final String? videoId;
  final String? playerIsPaused;
  final String? playerPreloadOn;
  final String? fastPixApiVersion;
  final String? sessionExpiredTime;
  final String? deviceManufacturer;
  final String? deviceModel;

  const PauseEvent({
    super.workSpaceId,
    super.viewId,
    super.viewSequenceNumber,
    super.playerSequenceNumber,
    super.beaconDomain,
    super.playheadTime,
    super.viewerTimeStamp,
    super.playerInstanceId,
    super.viewWatchTime,
    super.connectionType,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalContentPlayBackTime,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
    this.mimeType,
    this.videoId,
    this.playerIsPaused,
    this.playerPreloadOn,
    this.fastPixApiVersion,
    this.sessionExpiredTime,
    this.deviceManufacturer,
    this.deviceModel,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'pause',
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'fpaivn': fastPixApiVersion,
      'vdsomity': mimeType,
      'vdid': videoId,
      'plispu': playerIsPaused,
      'plpron': playerPreloadOn,
      'snepti': sessionExpiredTime,
      'demr': deviceManufacturer,
      'demo': deviceModel
    };
  }

  static Future<PauseEvent> createPauseEvent() async {
    final configService = ServiceLocator().configurationService;
    final sessionService = ServiceLocator().sessionService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    await configService.calculateViewScaling();
    // Update metrics state
    await MetricsStateManager().handlePause(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    // Get metrics from state manager
    final metricsState = MetricsStateManager();
    final viewTotalContentPlaybackTime =
        metricsState.viewTotalContentPlaybackTime;
    final viewMaxUpScalePercentage =
        configService.state.viewMaxUpScalePercentage;
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final viewMaxDownScalePercentage =
        configService.state.viewMaxDownScalePercentage;
    final viewTotalUpScaling = metricsState.viewTotalUpscaling;
    final viewTotalDownScaling = metricsState.viewTotalDownscaling;
    final videoData = configService.videoData;
    final playerIsPaused = configService.playerObserver?.isPlayerPaused();
    final sessionExpiredTime = sessionService.sessionExpiryTime;

    return PauseEvent(
      workSpaceId: baseData['wsid'],
      viewId: baseData['veid'],
      viewSequenceNumber: baseData['vesqnu'],
      playerSequenceNumber: baseData['plsqnu'],
      beaconDomain: baseData['bedn'],
      playheadTime: baseData['plphti'],
      viewerTimeStamp: baseData['vitp'],
      playerInstanceId: baseData['plinid'],
      viewWatchTime: baseData['vewati'],
      connectionType: baseData['vicity'],
      viewMaxUpScalePercentage: viewMaxUpScalePercentage.toString(),
      viewMaxDownScalePercentage: viewMaxDownScalePercentage.toString(),
      viewTotalContentPlayBackTime: viewTotalContentPlaybackTime.toString(),
      viewTotalUpScaling: viewTotalUpScaling.toString(),
      viewTotalDownScaling: viewTotalDownScaling.toString(),
      mimeType: "",
      videoId:
          videoData?.videoId ?? configService.generateRandomIdOf24Characters(),
      playerIsPaused: playerIsPaused.toString(),
      playerPreloadOn: "false",
      fastPixApiVersion: "1.0",
      sessionExpiredTime: sessionExpiredTime.toString(),
      deviceModel: deviceInfo['deviceModel'],
      deviceManufacturer: deviceInfo['deviceManufacturer'],
    );
  }
}
