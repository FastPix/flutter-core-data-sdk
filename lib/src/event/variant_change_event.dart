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
    final observer = configService.playerObserver;
    final videoId = configService.videoData?.videoId ??
        configService.generateRandomIdOf24Characters();
    final track = configService.changeTrack;

    // Treat null AND empty strings as missing. BetterPlayer's HLS parser
    // populates frameRate/codec/mimeType as 0/'' on the init defaultTrack
    // dispatch, which would otherwise mask the observer fallback.
    String? coalesce(String? trackValue, String? observerValue) {
      if (trackValue != null && trackValue.isNotEmpty && trackValue != '0') {
        return trackValue;
      }
      return observerValue;
    }

    final frameRateFromTrack = track?.frameRate;
    final frameRateInt =
        (frameRateFromTrack != null && frameRateFromTrack.isNotEmpty
                ? int.tryParse(frameRateFromTrack)
                : null) ??
            observer?.sourceAdvertiseFrameRate();

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
      videoSourceHeight:
          coalesce(track?.height, observer?.videoSourceHeight()?.toString()),
      videoSourceWidth:
          coalesce(track?.width, observer?.videoSourceWidth()?.toString()),
      frameRate: frameRateInt,
      mimeType: coalesce(track?.mimeType, observer?.mimeType()),
      bitrate: coalesce(track?.bitrate, observer?.sourceAdvertisedBitrate()),
      videoId: videoId,
    );
  }
}
