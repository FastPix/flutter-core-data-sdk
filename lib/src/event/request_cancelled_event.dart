import '../services/service_locator.dart';
import 'event_base.dart';

class RequestCancelledEvent extends BaseEvent {
  final String? requestId;
  final String? requestUrl;
  final String? requestMethod;
  final String? requestHostName;
  final String? requestCancel;

  RequestCancelledEvent({
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
    this.requestHostName,
    this.requestCancel,
  }) : super(eventName: 'requestCanceled');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'rqid': requestId,
      'rqur': requestUrl,
      'rqty': requestMethod,
      'rqhn': requestHostName,
      'rqca': requestCancel,
    };
  }

  static Future<RequestCancelledEvent> createRequestCancelledEvent({
    required String requestId,
    required String requestUrl,
    required String requestMethod,
    String? requestHostName,
    String? requestCancel,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);

    return RequestCancelledEvent(
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
      requestHostName: requestHostName,
      requestCancel: requestCancel,
    );
  }
}
