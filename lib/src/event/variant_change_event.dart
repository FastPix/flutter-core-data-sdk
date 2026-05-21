import '../services/service_locator.dart';
import 'event_base.dart';

class VariantChangedEvent extends BaseEvent {
  final String? videoSourceWidth;
  final String? videoSourceHeight;
  final String? videoId;
  final int? frameRate;
  final String? mimeType;
  final String? bitrate;

  VariantChangedEvent({
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
    this.videoSourceWidth,
    this.videoSourceHeight,
    this.videoId,
    this.frameRate,
    this.mimeType,
    this.bitrate,
  }) : super(eventName: 'variantChanged');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vdsowt': videoSourceWidth,
      'vdsoht': videoSourceHeight,
      'vdid': videoId,
      'vdsofs': frameRate,
      'vdsomity': mimeType,
      'vdsobi': bitrate,
    };
  }

  static Future<VariantChangedEvent> createVariantChangeEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = BaseEvent.getBaseEventData(configService);
    final playerObserver = configService.playerObserver;
    final videoId = configService.videoData?.videoId ??
        configService.generateRandomIdOf24Characters();
    final frameRateString = configService.changeTrack?.frameRate;
    final frameRateInt = frameRateString == null
        ? null
        : int.tryParse(frameRateString);
    return VariantChangedEvent(
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
      videoSourceHeight: configService.changeTrack?.height == null
          ? playerObserver?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
      videoSourceWidth: configService.changeTrack?.width == null
          ? playerObserver?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
      frameRate: frameRateInt,
      mimeType: configService.changeTrack?.mimeType,
      bitrate: configService.changeTrack?.bitrate,
      videoId: videoId,
    );
  }
}
