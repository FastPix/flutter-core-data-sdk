import '../services/service_locator.dart';
import '../util/scaling_tracker.dart';
import '../util/utils.dart';
import 'event_base.dart';

class PulseEvent extends BaseEvent {
  final String? viewBufferFrequency;
  final String? viewBufferPercentage;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoWidth;
  final String? videoHeight;
  final String? viewRebufferDuration;
  final String? videoDuration;
  final String? viewTotalContentPlayBackTime;
  final double? viewMaxUpScalePercentage;
  final double? viewMaxDownScalePercentage;
  final double? viewTotalUpScaling;
  final double? viewTotalDownScaling;
  final String? videoSourceUrl;
  final String? videoHostName;
  final String? videoCDN;

  PulseEvent({
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
    this.viewBufferFrequency,
    this.viewBufferPercentage,
    this.playerWidth,
    this.playerHeight,
    this.videoWidth,
    this.videoHeight,
    this.viewRebufferDuration,
    this.videoDuration,
    this.viewTotalContentPlayBackTime,
    this.viewMaxUpScalePercentage,
    this.viewMaxDownScalePercentage,
    this.viewTotalUpScaling,
    this.viewTotalDownScaling,
    this.videoSourceUrl,
    this.videoHostName,
    this.videoCDN,
  }) : super(eventName: 'pulse');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
      'verbdu': viewRebufferDuration,
      'vdsodu': videoDuration,
      'vetlctpbti': viewTotalContentPlayBackTime,
      'vemauppg': viewMaxUpScalePercentage,
      'vemadopg': viewMaxDownScalePercentage,
      'vetlug': viewTotalUpScaling,
      'vetldg': viewTotalDownScaling,
      'vdsour': videoSourceUrl,
      'vdsohn': videoHostName,
      'vdcn': videoCDN,
    };
  }

  static Future<PulseEvent> createPulseEvent() async {
    final configService = ServiceLocator().configurationService;
    final metrix = ServiceLocator().metricsStateManager;
    final baseData = BaseEvent.getBaseEventData(configService);
    configService.collectDataForScaling();
    final tracker = ScalingTracker.instance;
    final isFullScreen = configService.playerObserver?.isPlayerFullScreen();
    if (isFullScreen == true) {
      metrix.updatePlayerOrientationChange();
    }
    final playerObserver = configService.playerObserver;
    final videoData = configService.videoData;
    final bufferFrequency = metrix.getRebufferFrequency();
    return PulseEvent(
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
      isPlayerFullScreen: metrix.isPlayerOrientationChanged ? 'true' : 'false',
      viewRebufferDuration: metrix.viewRebufferDuration.toString(),
      viewBufferPercentage: metrix.viewRebufferPercentage.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      playerWidth: playerObserver?.playerWidth().round().toString(),
      playerHeight: playerObserver?.playerHeight().round().toString(),
      videoHeight: configService.changeTrack?.height == null
          ? playerObserver?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
      videoWidth: configService.changeTrack?.width == null
          ? playerObserver?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
      videoDuration: playerObserver?.videoSourceDuration().toString(),
      viewTotalContentPlayBackTime: tracker.totalPlaybackTime.toString(),
      viewMaxUpScalePercentage: tracker.currentMaxUpscale,
      viewMaxDownScalePercentage: tracker.currentMaxDownscale,
      viewTotalUpScaling: tracker.totalUpscalingTimeWeighted,
      viewTotalDownScaling: tracker.totalDownscalingTimeWeighted,
      videoSourceUrl: videoData?.videoUrl,
      videoHostName: Utils.getDomain(videoData?.videoUrl),
      videoCDN: null,
    );
  }
}
