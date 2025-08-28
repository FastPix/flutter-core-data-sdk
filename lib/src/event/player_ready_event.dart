import '../services/service_locator.dart';
import 'event_base.dart';

class PlayerReadyEvent extends BaseEvent {
  final String? playerInitTime;

  const PlayerReadyEvent(
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
      this.playerInitTime});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'plitti': playerInitTime,
      'evna': 'playerReady',
    };
  }

  static Future<PlayerReadyEvent> createPlayerReadyEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    final playerInitTime =
        configService.currentTimeStamp() - configService.state.lastPlayHeadTime;
    return PlayerReadyEvent(
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
        playerInitTime: playerInitTime.toString());
  }
}
