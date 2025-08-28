import '../services/service_locator.dart';
import 'event_base.dart';

class RequestFailedEvent extends BaseEvent {
  final String? requestId;
  final String? requestUrl;
  final String? requestMethod;
  final String? requestError;

  const RequestFailedEvent({
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
    this.requestError,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'requestFailed',
      'reqid': requestId,
      'requrl': requestUrl,
      'reqmet': requestMethod,
      'reqerr': requestError,
    };
  }

  static Future<RequestFailedEvent> createRequestFailedEvent({
    required String requestId,
    required String requestUrl,
    required String requestMethod,
    required String requestError,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    return RequestFailedEvent(
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
        requestMethod: requestMethod,
        requestError: requestError);
  }
}
