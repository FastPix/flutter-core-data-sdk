import '../services/service_locator.dart';
import 'event_base.dart';

class EndedEvent extends BaseEvent {
  final String? videoContentPlaybackTime;
  final String? viewTotalContentPlayBackTime;
  final String? viewTotalDownScaling;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScalePercentage;
  final String? viewTotalUpScalePercentage;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  const EndedEvent({
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
    this.videoContentPlaybackTime,
    this.viewTotalContentPlayBackTime,
    this.viewTotalDownScaling,
    this.viewTotalUpScaling,
    this.viewTotalDownScalePercentage,
    this.viewTotalUpScalePercentage,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vectpbti': videoContentPlaybackTime,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vetldg': viewTotalDownScaling,
      'vetlug': viewTotalUpScaling,
      'vemadopg': viewTotalDownScalePercentage,
      'vemauppg': viewTotalUpScalePercentage,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'evna': 'ended',
    };
  }

  static Future<EndedEvent> createEndedEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    final metrix = ServiceLocator().metricsStateManager;
    final bufferFrequency = metrix.getRebufferFrequency();
    return EndedEvent(
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
      videoContentPlaybackTime:
          configService.state.viewTotalContentPlayBackTime.toString(),
      viewTotalContentPlayBackTime:
          configService.state.viewTotalContentPlayBackTime.toString(),
      viewTotalDownScaling: configService.state.viewTotalDownScaling.toString(),
      viewTotalUpScaling: configService.state.viewTotalUpScaling.toString(),
      viewTotalDownScalePercentage:
          configService.state.viewTotalDownScaling.toString(),
      viewTotalUpScalePercentage:
          configService.state.viewTotalUpScaling.toString(),
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
    );
  }
}
