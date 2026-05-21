import '../metrics/metrics_state_manager.dart';
import '../services/service_locator.dart';
import '../util/utils.dart';
import 'event_base.dart';

class PlayEvent extends BaseEvent {
  final String? videoId;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? videoDuration;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoWidth;
  final String? videoHeight;
  final String? videoSourceUrl;
  final String? videoHostName;

  PlayEvent({
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
    this.videoId,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.videoDuration,
    this.playerWidth,
    this.playerHeight,
    this.videoWidth,
    this.videoHeight,
    this.videoSourceUrl,
    this.videoHostName,
  }) : super(eventName: 'play');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vdid': videoId,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'vdsodu': videoDuration,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
      'vdsour': videoSourceUrl,
      'vdsohn': videoHostName,
    };
  }

  static Future<PlayEvent> createPlayEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = BaseEvent.getBaseEventData(configService);
    final videoData = configService.videoData;
    final observer = configService.playerObserver;
    await metricsManager.handlePlay(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final bufferFrequency = metricsManager.getRebufferFrequency();
    return PlayEvent(
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
      videoId:
          videoData?.videoId ?? configService.generateRandomIdOf24Characters(),
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      videoDuration: observer?.sourceDuration().toString(),
      playerWidth: observer?.playerWidth()?.round().toString(),
      playerHeight: observer?.playerHeight()?.round().toString(),
      videoHeight: configService.changeTrack?.height == null
          ? observer?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
      videoWidth: configService.changeTrack?.width == null
          ? observer?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
      videoSourceUrl: videoData?.videoSourceUrl,
      videoHostName: Utils.getDomain(videoData?.videoSourceUrl),
    );
  }
}
