import '../services/service_locator.dart';
import 'event_base.dart';

class PlayerReadyEvent extends BaseEvent {
  final String? playerInitTime;
  final int? playerWidth;
  final int? playerHeight;
  final String? videoDuration;

  PlayerReadyEvent({
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
    this.playerInitTime,
    this.playerWidth,
    this.playerHeight,
    this.videoDuration,
  }) : super(eventName: 'playerReady');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'plitti': playerInitTime,
      'plwt': playerWidth,
      'plht': playerHeight,
      'vdsodu': videoDuration,
    };
  }

  static Future<PlayerReadyEvent> createPlayerReadyEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);
    final playerObserver = configService.playerObserver;
    final playerInitTime =
        configService.currentTimeStamp() - configService.state.lastPlayHeadTime;
    return PlayerReadyEvent(
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
      playerInitTime: playerInitTime.toString(),
      playerWidth: playerObserver?.playerWidth()?.round(),
      playerHeight: playerObserver?.playerHeight()?.round(),
      videoDuration: playerObserver?.sourceDuration().toString(),
    );
  }
}
