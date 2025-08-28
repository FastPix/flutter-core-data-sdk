import '../services/service_locator.dart';
import 'event_base.dart';

class SeekedEvent extends BaseEvent {
  final String? viewSeekDuration;
  final String? viewMaxSeekDuration;
  final String? viewSeekCount;
  final String? viewMaxUpScalePercentage;
  final String? viewMaxDownScalePercentage;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScaling;

  const SeekedEvent(
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
      this.viewSeekDuration,
      this.viewMaxSeekDuration,
      this.viewSeekCount});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'vesedu': viewSeekDuration,
      'vemaseti': viewMaxSeekDuration,
      'veseco': viewSeekCount,
      'evna': 'seeked',
    };
  }

  static Future<SeekedEvent> createSeekedEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = await BaseEvent.getBaseEventData(configService);
    await metrix.handleSeeked(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final viewMaxUpScalePercentage =
        configService.state.viewMaxUpScalePercentage;
    final viewMaxDownScalePercentage =
        configService.state.viewMaxDownScalePercentage;
    final viewTotalUpScaling = metrix.viewTotalUpscaling;
    final viewTotalDownScaling = metrix.viewTotalDownscaling;
    final seekDuration = metrix.viewSeekDuration.toString();

    return SeekedEvent(
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
      viewSeekDuration: seekDuration,
      viewMaxSeekDuration: seekDuration,
      viewSeekCount: metrix.viewSeekCount.toString(),
      viewMaxUpScalePercentage: viewMaxUpScalePercentage.toString(),
      viewMaxDownScalePercentage: viewMaxDownScalePercentage.toString(),
      viewTotalUpScaling: viewTotalUpScaling.toString(),
      viewTotalDownScaling: viewTotalDownScaling.toString(),
    );
  }
}
