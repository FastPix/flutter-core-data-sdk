import '../services/service_locator.dart';
import 'event_base.dart';

class PulseEvent extends BaseEvent {
  final String? viewMaxUpScalePercentage;
  final String? viewMaxDownScalePercentage;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScaling;
  final String? isPlayerFullScreen;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoWidth;
  final String? videoHeight;

  const PulseEvent({
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
    this.viewTotalUpScaling,
    this.isPlayerFullScreen,
    this.viewTotalDownScaling,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.playerWidth,
    this.playerHeight,
    this.videoWidth,
    this.videoHeight,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'plisfl': isPlayerFullScreen,
      'vewati': viewWatchTime,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
      'evna': 'pulse',
    };
  }

  static Future<PulseEvent> createPulseEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = await BaseEvent.getBaseEventData(configService);
    await configService.calculateViewScaling();
    final viewMaxUpScalePercentage =
        configService.state.viewMaxUpScalePercentage;
    final isFullScreen = configService.playerObserver?.isPlayerFullScreen();
    if (isFullScreen == true) {
      metrix.updatePlayerOrientationChange();
    }
    final playerObserver = configService.playerObserver;
    final bufferFrequency = metrix.getRebufferFrequency();
    final viewMaxDownScalePercentage =
        configService.state.viewMaxDownScalePercentage;
    final viewTotalUpScaling = configService.state.viewTotalUpScaling;
    final viewTotalDownScaling = configService.state.viewTotalDownScaling;
    return PulseEvent(
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
      viewTotalUpScaling: viewTotalUpScaling.toString(),
      isPlayerFullScreen: metrix.isPlayerOrientationChanged ? 'true' : 'false',
      viewTotalDownScaling: viewTotalDownScaling.toString(),
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      playerWidth: playerObserver?.playerWidth().round().toString(),
      playerHeight: playerObserver?.playerHeight().round().toString(),
      videoHeight: configService.changeTrack?.height == null
          ? playerObserver?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
      videoWidth: configService.changeTrack?.width == null
          ? playerObserver?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
    );
  }
}
