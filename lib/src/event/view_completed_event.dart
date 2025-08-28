import '../services/service_locator.dart';
import 'event_base.dart';

class ViewCompletedEvent extends BaseEvent {
  final String? videoContentPlaybackTime;
  final String? viewTotalContentPlayBackTime;
  final String? viewTotalDownScaling;
  final String? viewTotalUpScaling;
  final String? viewTotalDownScalePercentage;
  final String? viewTotalUpScalePercentage;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  const ViewCompletedEvent({
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
    this.videoContentPlaybackTime,
    this.viewTotalContentPlayBackTime,
    this.viewTotalDownScaling,
    this.viewTotalUpScaling,
    this.viewTotalDownScalePercentage,
    this.viewTotalUpScalePercentage,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vectpbti': videoContentPlaybackTime,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vetldg': viewTotalDownScaling,
      'vetlug': viewTotalUpScaling,
      'vemadopg': viewTotalDownScalePercentage,
      'vemauppg': viewTotalUpScalePercentage,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'evna': 'viewCompleted',
    };
  }

  static Future<ViewCompletedEvent> createViewCompletedEvent({
    required String videoContentPlaybackTime,
    required String viewTotalContentPlayBackTime,
    required String viewTotalDownScaling,
    required String viewTotalUpScaling,
    required String viewTotalDownScalePercentage,
    required String viewTotalUpScalePercentage,
  }) async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    final metrix = ServiceLocator().metricsStateManager;
    final bufferFrequency = metrix.getRebufferFrequency();
    return ViewCompletedEvent(
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
      videoContentPlaybackTime: videoContentPlaybackTime,
      viewTotalContentPlayBackTime: viewTotalContentPlayBackTime,
      viewTotalDownScaling: viewTotalDownScaling,
      viewTotalUpScaling: viewTotalUpScaling,
      viewTotalDownScalePercentage: viewTotalDownScalePercentage,
      viewTotalUpScalePercentage: viewTotalUpScalePercentage,
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
    );
  }
}
