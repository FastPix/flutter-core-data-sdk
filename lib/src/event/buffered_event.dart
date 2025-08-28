import 'package:fastpix_flutter_core_data/src/metrics/metrics_state_manager.dart';

import '../services/service_locator.dart';
import 'event_base.dart';

class BufferedEvent extends BaseEvent {
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? viewMaxUpScalePercentage;
  final String? viewMaxDownScalePercentage;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScaling;

  const BufferedEvent(
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
      this.viewMaxUpScalePercentage,
      this.viewMaxDownScalePercentage,
      this.viewTotalUpScaling,
      this.viewTotalDownScaling,
      this.viewRebufferDuration,
      this.viewBufferFrequency,
      this.viewBufferPercentage});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'evna': 'buffered',
    };
  }

  static Future<BufferedEvent> createBufferedEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = await BaseEvent.getBaseEventData(configService);
    await configService.calculateViewScaling();
    await metricsManager.handleBuffered(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final bufferFrequency = metricsManager.getRebufferFrequency();
    final viewMaxUpScalePercentage =
        configService.state.viewMaxUpScalePercentage;
    final viewMaxDownScalePercentage =
        configService.state.viewMaxDownScalePercentage;
    final viewTotalUpScaling = metricsManager.viewTotalUpscaling;
    final viewTotalDownScaling = metricsManager.viewTotalDownscaling;
    return BufferedEvent(
      workSpaceId: baseData['wsid'],
      viewId: baseData['veid'],
      viewSequenceNumber: baseData['vesqnu'],
      playerSequenceNumber: baseData['plsqnu'],
      beaconDomain: baseData['bedn'],
      playheadTime: baseData['plphti'],
      viewerTimeStamp: baseData['vitp'],
      connectionType: baseData['vicity'],
      playerInstanceId: baseData['plinid'],
      viewWatchTime: baseData['vewati'],
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      viewMaxUpScalePercentage: viewMaxUpScalePercentage.toString(),
      viewMaxDownScalePercentage: viewMaxDownScalePercentage.toString(),
      viewTotalUpScaling: viewTotalUpScaling.toString(),
      viewTotalDownScaling: viewTotalDownScaling.toString(),
    );
  }
}
