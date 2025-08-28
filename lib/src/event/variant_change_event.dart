import '../services/service_locator.dart';
import 'event_base.dart';

class VariantChangeEvent extends BaseEvent {
  final String? videoSourceWidth;
  final String? videoSourceHeight;
  final String? videoId;
  final String? frameRate;
  final String? codec;
  final String? bitrate;
  final String? mimeType;

  const VariantChangeEvent(
      {super.workSpaceId,
      super.viewId,
      super.viewSequenceNumber,
      super.playerSequenceNumber,
      super.beaconDomain,
      super.playheadTime,
      super.viewerTimeStamp,
      super.playerInstanceId,
      super.connectionType,
      this.frameRate,
      this.codec,
      this.bitrate,
      this.mimeType,
      this.videoSourceWidth,
      this.videoSourceHeight,
      this.videoId});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vdsowt': videoSourceWidth,
      'vdsoht': videoSourceHeight,
      'vdid': videoId,
      'vdsofs': frameRate,
      'vdsocc': codec,
      'vdsomity': mimeType,
      'vdsobi': bitrate,
      'evna': 'variantChanged',
    };
  }

  static Future<VariantChangeEvent> createVariantChangeEvent() async {
    final configService = ServiceLocator().configurationService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    final playerObserver = configService.playerObserver;
    final videoId = configService.videoData?.videoId ??
        configService.generateRandomIdOf24Characters();
    return VariantChangeEvent(
        workSpaceId: baseData['wsid'],
        viewId: baseData['veid'],
        viewSequenceNumber: baseData['vesqnu'],
        playerSequenceNumber: baseData['plsqnu'],
        beaconDomain: baseData['bedn'],
        playheadTime: baseData['plphti'],
        viewerTimeStamp: baseData['vitp'],
        playerInstanceId: baseData['plinid'],
        connectionType: baseData['vicity'],
        videoSourceHeight: configService.changeTrack?.height == null
            ? playerObserver?.videoSourceHeight().toString()
            : configService.changeTrack?.height?.toString(),
        videoSourceWidth: configService.changeTrack?.width == null
            ? playerObserver?.videoSourceWidth().toString()
            : configService.changeTrack?.width?.toString(),
        frameRate: configService.changeTrack?.frameRate,
        codec: configService.changeTrack?.codec,
        bitrate: configService.changeTrack?.bitrate,
        mimeType: configService.changeTrack?.mimeType,
        videoId: videoId);
  }
}
