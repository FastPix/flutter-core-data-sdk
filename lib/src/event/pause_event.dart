import '../services/service_locator.dart';
import '../metrics/metrics_state_manager.dart';
import '../util/scaling_tracker.dart';
import 'event_base.dart';

class PauseEvent extends BaseEvent {
  final double? viewMaxUpScalePercentage;
  final double? viewMaxDownScalePercentage;
  final double? viewTotalUpScaling;
  final double? viewTotalDownScaling;
  final String? viewTotalContentPlayBackTime;
  final String? playerIsPaused;
  final String? sessionExpiredTime;

  PauseEvent({
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
    super.isPlayerFullScreen,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
    this.viewTotalContentPlayBackTime,
    this.playerIsPaused,
    this.sessionExpiredTime,
  }) : super(eventName: 'pause');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'plispu': playerIsPaused,
      'snepti': sessionExpiredTime,
    };
  }

  static Future<PauseEvent> createPauseEvent() async {
    final configService = ServiceLocator().configurationService;
    final sessionService = ServiceLocator().sessionService;
    final baseData = BaseEvent.getBaseEventData(configService);
    configService.calculateScalingForCurrentInterval();
    await MetricsStateManager().handlePause(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final tracker = ScalingTracker.instance;
    final playerIsPaused = configService.playerObserver?.isPlayerPaused();
    final sessionExpiredTime = sessionService.sessionExpiryTime;

    return PauseEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      beaconDomain: baseData.beaconDomain,
      playheadTime: baseData.playheadTime,
      viewerTimeStamp: baseData.viewerTimeStamp,
      playerInstanceId: baseData.playerInstanceId,
      viewWatchTime: baseData.viewWatchTime,
      connectionType: baseData.connectionType,
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      viewMaxUpScalePercentage: tracker.currentMaxUpscale,
      viewMaxDownScalePercentage: tracker.currentMaxDownscale,
      viewTotalUpScaling: tracker.totalUpscalingTimeWeighted,
      viewTotalDownScaling: tracker.totalDownscalingTimeWeighted,
      viewTotalContentPlayBackTime: tracker.totalPlaybackTime.toString(),
      playerIsPaused: playerIsPaused.toString(),
      sessionExpiredTime: sessionExpiredTime?.toString(),
    );
  }
}
