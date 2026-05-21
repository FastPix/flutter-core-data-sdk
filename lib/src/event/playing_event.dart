import '../services/service_locator.dart';
import '../util/utils.dart';
import 'event_base.dart';
import '../metrics/metrics_state_manager.dart';

class PlayingEvent extends BaseEvent {
  final String? videoStartTime;
  final String? viewRebufferDuration;
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoDuration;
  final String? videoSourceWidth;
  final String? videoSourceHeight;
  final String? videoSourceUrl;
  final String? videoHostName;

  PlayingEvent({
    super.workSpaceId,
    super.viewId,
    super.viewSequenceNumber,
    super.playerSequenceNumber,
    super.beaconDomain,
    super.playheadTime,
    super.viewerTimeStamp,
    super.playerInstanceId,
    super.connectionType,
    super.viewWatchTime,
    super.isPlayerFullScreen,
    this.videoStartTime,
    this.viewRebufferDuration,
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.playerWidth,
    this.playerHeight,
    this.videoDuration,
    this.videoSourceWidth,
    this.videoSourceHeight,
    this.videoSourceUrl,
    this.videoHostName,
  }) : super(eventName: 'playing');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vetitofifr': videoStartTime,
      'verbdu': viewRebufferDuration,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'plwt': playerWidth,
      'plht': playerHeight,
      'vdsodu': videoDuration,
      'vdsowt': videoSourceWidth,
      'vdsoht': videoSourceHeight,
      'vdsour': videoSourceUrl,
      'vdsohn': videoHostName,
    };
  }

  static Future<PlayingEvent> createPlayingEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = BaseEvent.getBaseEventData(configService);
    final playerObserver = configService.playerObserver;
    final videoData = configService.videoData;
    var isViewTimeToFirstFrame = 0;
    if (!metricsManager.isViewTimeToFirstFrameSent) {
      metricsManager.updateIsViewTimeToFirstFrameSent(true);
      isViewTimeToFirstFrame =
          configService.currentTimeStamp() - metricsManager.viewBeginTime;
    }
    final videoDuration = playerObserver?.sourceDuration();

    await metricsManager.handlePlaying(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    configService.collectDataForScaling();

    final bufferFrequency = metricsManager.getRebufferFrequency();
    return PlayingEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      beaconDomain: baseData.beaconDomain,
      playheadTime: baseData.playheadTime,
      viewerTimeStamp: baseData.viewerTimeStamp,
      playerInstanceId: baseData.playerInstanceId,
      viewWatchTime: baseData.viewWatchTime == '0'
          ? isViewTimeToFirstFrame.toString()
          : baseData.viewWatchTime,
      connectionType: baseData.connectionType,
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      videoStartTime: isViewTimeToFirstFrame.toString(),
      videoDuration: videoDuration.toString(),
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      playerWidth: playerObserver?.playerWidth()?.round().toString(),
      playerHeight: playerObserver?.playerHeight()?.round().toString(),
      videoSourceWidth: playerObserver?.videoSourceWidth().toString(),
      videoSourceHeight: playerObserver?.videoSourceHeight().toString(),
      videoSourceUrl: videoData?.videoSourceUrl,
      videoHostName: Utils.getDomain(videoData?.videoSourceUrl),
    );
  }
}
