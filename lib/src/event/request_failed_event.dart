import '../services/service_locator.dart';
import 'event_base.dart';

class RequestFailedEvent extends BaseEvent {
  final String? requestId;
  final String? requestUrl;
  final String? requestMethod;
  final String? requestError;
  final String? requestHostName;
  final String? requestErrorText;

  RequestFailedEvent({
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
    this.requestId,
    this.requestUrl,
    this.requestMethod,
    this.requestError,
    this.requestHostName,
    this.requestErrorText,
  }) : super(eventName: 'requestFailed');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'rqid': requestId,
      'rqur': requestUrl,
      'rqty': requestMethod,
      'rqercd': requestError,
      'rqhn': requestHostName,
      'rqerte': requestErrorText,
    };
  }

  static Future<RequestFailedEvent> createRequestFailedEvent({
    required String requestId,
    required String requestUrl,
    required String requestMethod,
    required String requestError,
    String? requestHostName,
    String? requestErrorText,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);
    return RequestFailedEvent(
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
      requestId: requestId,
      requestUrl: requestUrl,
      requestMethod: requestMethod,
      requestError: requestError,
      requestHostName: requestHostName,
      requestErrorText: requestErrorText,
    );
  }
}
