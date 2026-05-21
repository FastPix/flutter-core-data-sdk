import 'package:fastpix_flutter_core_data/src/metrics/metrics_state_manager.dart';

import '../services/service_locator.dart';
import 'event_base.dart';
// Android's BufferedEventBuilder does not interact with scalingTracker, so
// neither do we.

class BufferedEvent extends BaseEvent {
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  BufferedEvent({
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
    this.viewBufferFrequency,
    this.viewBufferPercentage,
  }) : super(eventName: 'buffered');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
    };
  }

  static Future<BufferedEvent> createBufferedEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = BaseEvent.getBaseEventData(configService);
    await metricsManager.handleBuffered(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final bufferFrequency = metricsManager.getRebufferFrequency();
    return BufferedEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      beaconDomain: baseData.beaconDomain,
      playheadTime: baseData.playheadTime,
      viewerTimeStamp: baseData.viewerTimeStamp,
      connectionType: baseData.connectionType,
      playerInstanceId: baseData.playerInstanceId,
      viewWatchTime: baseData.viewWatchTime,
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
    );
  }
}
