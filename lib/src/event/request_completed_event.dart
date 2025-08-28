import '../services/service_locator.dart';
import 'event_base.dart';

class RequestCompletedEvent extends BaseEvent {
  final String? requestId;
  final String? requestUrl;
  final String? requestMethod;
  final String? requestResponseCode;
  final String? requestResponseTime;
  final String? requestResponseSize;
  final String? requestResponseHeaders;
  final String? requestResponseBody;

  const RequestCompletedEvent({
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
    this.requestResponseCode,
    this.requestResponseTime,
    this.requestResponseSize,
    this.requestResponseHeaders,
    this.requestResponseBody,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'requestCompleted',
      'reqid': requestId,
      'requrl': requestUrl,
      'reqmet': requestMethod,
      'reqrsc': requestResponseCode,
      'reqrst': requestResponseTime,
      'reqrsz': requestResponseSize,
      'reqrsh': requestResponseHeaders,
      'reqrsb': requestResponseBody,
    };
  }

  static Future<RequestCompletedEvent> createRequestCompletedEvent({
    required String requestId,
    required String requestUrl,
    required String requestMethod,
    required String requestResponseCode,
    required String requestResponseTime,
    required String requestResponseSize,
    required String requestResponseHeaders,
    required String requestResponseBody,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);

    return RequestCompletedEvent(
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
        requestResponseCode: requestResponseCode,
        requestResponseTime: requestResponseTime,
        requestResponseSize: requestResponseSize,
        requestResponseHeaders: requestResponseHeaders,
        requestResponseBody: requestResponseBody);
  }
}
