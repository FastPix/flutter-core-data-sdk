import '../services/service_locator.dart';
import 'event_base.dart';

class SeekedEvent extends BaseEvent {
  final int? viewSeekDuration;
  final int? viewMaxSeekDuration;
  final String? viewSeekCount;

  SeekedEvent({
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
    this.viewSeekDuration,
    this.viewMaxSeekDuration,
    this.viewSeekCount,
  }) : super(eventName: 'seeked');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vesedu': viewSeekDuration,
      'vemaseti': viewMaxSeekDuration,
      'veseco': viewSeekCount,
    };
  }

  static Future<SeekedEvent> createSeekedEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = BaseEvent.getBaseEventData(configService);
    await metrix.handleSeeked(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final seekDuration = metrix.viewSeekDuration;

    return SeekedEvent(
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
      viewSeekDuration: seekDuration,
      viewMaxSeekDuration: seekDuration,
      viewSeekCount: metrix.viewSeekCount.toString(),
    );
  }
}
