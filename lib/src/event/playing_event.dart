import '../services/service_locator.dart';
import 'event_base.dart';
import '../metrics/metrics_state_manager.dart';

class PlayingEvent extends BaseEvent {
  final String? videoStartTime;
  final String? videoDuration;
  final String? videoThumbnail;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;

  const PlayingEvent(
      {super.workSpaceId,
      super.viewId,
      super.viewSequenceNumber,
      super.playerSequenceNumber,
      super.beaconDomain,
      super.playheadTime,
      super.viewerTimeStamp,
      super.playerInstanceId,
      super.connectionType,
      super.viewWatchTime,
      this.videoStartTime,
      this.videoDuration,
      this.videoThumbnail,
      this.viewRebufferDuration,
      this.viewBufferFrequency,
      this.viewBufferPercentage});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vetitofifr': videoStartTime,
      'vdsodu': videoDuration,
      'vdpour': videoThumbnail,
      'vewati': viewWatchTime,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'evna': 'playing',
    };
  }

  static Future<PlayingEvent> createPlayingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = await BaseEvent.getBaseEventData(configService);
    var isViewTimeToFirstFrame = 0;
    if (!metricsManager.isViewTimeToFirstFrameSent) {
      metricsManager.updateIsViewTimeToFirstFrameSent(true);
      isViewTimeToFirstFrame =
          configService.currentTimeStamp() - metricsManager.viewBeginTime;
    }
    final videoDuration = configService.playerObserver?.videoSourceDuration();
    final videoThumbnail = configService.videoData?.videoThumbnailUrl;

    // Update watch time tracking when playing event is created
    await metricsManager.handlePlaying(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );

    // Use safe viewWatchTime calculation
    final bufferFrequency = metricsManager.getRebufferFrequency();
    return PlayingEvent(
      workSpaceId: baseData['wsid'],
      viewId: baseData['veid'],
      viewSequenceNumber: baseData['vesqnu'],
      playerSequenceNumber: baseData['plsqnu'],
      beaconDomain: baseData['bedn'],
      playheadTime: baseData['plphti'],
      viewerTimeStamp: baseData['vitp'],
      playerInstanceId: baseData['plinid'],
      viewWatchTime: baseData['vewati'] == "0"
          ? isViewTimeToFirstFrame.toString()
          : baseData['vewati'],
      connectionType: baseData['vicity'],
      videoStartTime: isViewTimeToFirstFrame.toString(),
      videoDuration: videoDuration.toString(),
      videoThumbnail: videoThumbnail,
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
    );
  }
}
