import 'package:fastpix_flutter_core_data/src/metrics/metrics_state_manager.dart';
import 'package:fastpix_flutter_core_data/src/util/scaling_tracker.dart';

import '../services/service_locator.dart';
import 'event_base.dart';

class BufferingEvent extends BaseEvent {
  final String? viewRebufferDuration;
  final String? viewRebufferCount;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? viewTotalContentPlayBackTime;
  final double? viewMaxUpScalePercentage;
  final double? viewMaxDownScalePercentage;
  final double? viewTotalUpScaling;
  final double? viewTotalDownScaling;

  BufferingEvent({
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
    this.viewRebufferDuration,
    this.viewRebufferCount,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.viewTotalContentPlayBackTime,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
  }) : super(eventName: 'buffering');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'verbdu': viewRebufferDuration,
      'verbco': viewRebufferCount,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
    };
  }

  static Future<BufferingEvent> createBufferingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = BaseEvent.getBaseEventData(configService);
    await metricsManager.handleBuffering(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    configService.calculateScalingForCurrentInterval();
    final tracker = ScalingTracker.instance;
    return BufferingEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      viewWatchTime: baseData.viewWatchTime,
      beaconDomain: baseData.beaconDomain,
      playheadTime: baseData.playheadTime,
      connectionType: baseData.connectionType,
      viewerTimeStamp: baseData.viewerTimeStamp,
      playerInstanceId: baseData.playerInstanceId,
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewRebufferCount: metricsManager.viewRebufferCount.toString(),
      viewBufferFrequency: metricsManager.getRebufferFrequency().toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      viewTotalContentPlayBackTime: tracker.totalPlaybackTime.toString(),
      viewMaxUpScalePercentage: tracker.currentMaxUpscale,
      viewMaxDownScalePercentage: tracker.currentMaxDownscale,
      viewTotalUpScaling: tracker.totalUpscalingTimeWeighted,
      viewTotalDownScaling: tracker.totalDownscalingTimeWeighted,
    );
  }
}
