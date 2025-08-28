import '../services/service_locator.dart';
import 'event_base.dart';

class RequestCancelledEvent extends BaseEvent {
  final String? requestId;
  final String? requestUrl;
  final String? requestMethod;

  const RequestCancelledEvent({
    super.workSpaceId,
    super.viewId,
    super.viewSequenceNumber,
    super.playerSequenceNumber,
    super.beaconDomain,
    super.playheadTime,
    super.viewerTimeStamp,
    super.playerInstanceId,
    this.requestId,
    this.requestUrl,
    this.requestMethod,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'requestCancelled',
      'reqid': requestId,
      'requrl': requestUrl,
      'reqmet': requestMethod,
    };
  }

  static Future<RequestCancelledEvent> createRequestCancelledEvent({
    required String requestId,
    required String requestUrl,
    required String requestMethod,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);

    return RequestCancelledEvent(
        workSpaceId: baseData['wsid'],
        viewId: baseData['veid'],
        viewSequenceNumber: baseData['vesqnu'],
        playerSequenceNumber: baseData['plsqnu'],
        beaconDomain: baseData['bedn'],
        playheadTime: baseData['plphti'],
        viewerTimeStamp: baseData['vitp'],
        playerInstanceId: baseData['plinid'],
        requestId: requestId,
        requestUrl: requestUrl,
        requestMethod: requestMethod);
  }
}
