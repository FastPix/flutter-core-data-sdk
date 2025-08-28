import 'package:fastpix_flutter_core_data/src/metrics/metrics_state_manager.dart';

import '../services/service_locator.dart';
import 'event_base.dart';

class BufferingEvent extends BaseEvent {
  final String? viewRebufferDuration;
  final String? viewRebufferCount;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  const BufferingEvent(
      {super.workSpaceId,
      super.viewId,
      super.viewSequenceNumber,
      super.playerSequenceNumber,
      super.beaconDomain,
      super.playheadTime,
      super.viewerTimeStamp,
      super.playerInstanceId,
      super.viewWatchTime,
      super.connectionType,
      this.viewRebufferCount,
      this.viewRebufferDuration,
      this.viewBufferFrequency,
      this.viewBufferPercentage});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'verbco': viewRebufferCount,
      'evna': 'buffering',
    };
  }

  static Future<BufferingEvent> createBufferingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = await BaseEvent.getBaseEventData(configService);
    await metricsManager.handleBuffering(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    return BufferingEvent(
      workSpaceId: baseData['wsid'],
      viewId: baseData['veid'],
      viewSequenceNumber: baseData['vesqnu'],
      playerSequenceNumber: baseData['plsqnu'],
      viewWatchTime: baseData['vewati'],
      viewRebufferCount: metricsManager.viewRebufferCount.toString(),
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferFrequency: metricsManager.getRebufferFrequency().toString(),
      beaconDomain: baseData['bedn'],
      playheadTime: baseData['plphti'],
      connectionType: baseData['vicity'],
      viewerTimeStamp: baseData['vitp'],
      playerInstanceId: baseData['plinid'],
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
    );
  }
}
