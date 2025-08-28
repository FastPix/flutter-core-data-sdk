import '../services/service_locator.dart';
import 'event_base.dart';

class SeekingEvent extends BaseEvent {
  const SeekingEvent(
      {super.workSpaceId,
      super.viewId,
      super.viewSequenceNumber,
      super.playerSequenceNumber,
      super.beaconDomain,
      super.playheadTime,
      super.viewerTimeStamp,
      super.playerInstanceId,
      super.connectionType});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'seeking',
    };
  }

  static Future<SeekingEvent> createSeekingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = await BaseEvent.getBaseEventData(configService);
    // Update metrics state
    await metrix.handleSeeking(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );

    return SeekingEvent(
      workSpaceId: baseData['wsid'],
      viewId: baseData['veid'],
      viewSequenceNumber: baseData['vesqnu'],
      playerSequenceNumber: baseData['plsqnu'],
      beaconDomain: baseData['bedn'],
      playheadTime: baseData['plphti'],
      viewerTimeStamp: baseData['vitp'],
      playerInstanceId: baseData['plinid'],
      connectionType: baseData['vicity'],
    );
  }
}
