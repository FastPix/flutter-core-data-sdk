import '../services/service_locator.dart';
import '../util/scaling_tracker.dart';
import 'event_base.dart';

class SeekingEvent extends BaseEvent {
  final String? viewTotalContentPlayBackTime;
  final double? viewMaxUpScalePercentage;
  final double? viewMaxDownScalePercentage;
  final double? viewTotalUpScaling;
  final double? viewTotalDownScaling;

  SeekingEvent({
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
    this.viewTotalContentPlayBackTime,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
  }) : super(eventName: 'seeking');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
    };
  }

  static Future<SeekingEvent> createSeekingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = BaseEvent.getBaseEventData(configService);
    await metrix.handleSeeking(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    configService.calculateScalingForCurrentInterval();
    final tracker = ScalingTracker.instance;

    return SeekingEvent(
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
      viewTotalContentPlayBackTime: tracker.totalPlaybackTime.toString(),
      viewMaxUpScalePercentage: tracker.currentMaxUpscale,
      viewMaxDownScalePercentage: tracker.currentMaxDownscale,
      viewTotalUpScaling: tracker.totalUpscalingTimeWeighted,
      viewTotalDownScaling: tracker.totalDownscalingTimeWeighted,
    );
  }
}
