import '../services/service_locator.dart';
import 'event_base.dart';

class EndedEvent extends BaseEvent {
  final String? videoContentPlaybackTime;
  final String? viewTotalContentPlayBackTime;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  EndedEvent({
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
    this.videoContentPlaybackTime,
    this.viewTotalContentPlayBackTime,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
  }) : super(eventName: 'ended');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vectpbti': videoContentPlaybackTime,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
    };
  }

  static Future<EndedEvent> createEndedEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);
    final metrix = ServiceLocator().metricsStateManager;
    final bufferFrequency = metrix.getRebufferFrequency();
    return EndedEvent(
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
      videoContentPlaybackTime:
          configService.state.viewTotalContentPlayBackTime.toString(),
      viewTotalContentPlayBackTime:
          configService.state.viewTotalContentPlayBackTime.toString(),
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
    );
  }
}
