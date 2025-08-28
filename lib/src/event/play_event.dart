
import '../metrics/metrics_state_manager.dart';
import '../services/service_locator.dart';
import '../util/device_info_helper.dart';
import 'event_base.dart';

class PlayEvent extends BaseEvent {
  final String? videoId;
  final String? viewRebufferDuration;
  final String? mimeType;
  final String? fastPixApiVersion;
  final String? videoCodec;
  final String? hostName;
  final String? viewBufferFrequency;
  final String? videoHeight;
  final String? videoWidth;
  final String? videoLanguage;
  final String? viewBufferPercentage;

  const PlayEvent({
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
    this.videoId,
    this.viewRebufferDuration,
    this.mimeType,
    this.fastPixApiVersion,
    this.videoCodec,
    this.hostName,
    this.viewBufferFrequency,
    this.videoWidth,
    this.videoHeight,
    this.videoLanguage,
    this.viewBufferPercentage,
  });

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'evna': 'play',
      'vdid': videoId,
      'verbdu': viewRebufferDuration,
      'vdsomity': mimeType,
      'fpaivn': fastPixApiVersion,
      'vdsocc': videoCodec,
      'vdsohn': hostName,
      'vdsoht': videoHeight,
      'vdsowt': videoWidth,
      'vdlncd': videoLanguage,
      'verbfq': viewBufferFrequency,
      'verbpg': viewBufferPercentage,
    };
  }

  static Future<PlayEvent> createPlayEvent() async {
    final configService = ServiceLocator().configurationService;
    final metricsManager = MetricsStateManager();
    final baseData = await BaseEvent.getBaseEventData(configService);
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final videoData = configService.videoData;
    // Update metrics state
    await metricsManager.handlePlay(
      DateTime.fromMillisecondsSinceEpoch(configService.currentTimeStamp()),
    );
    final bufferFrequency = metricsManager.getRebufferFrequency();
    return PlayEvent(
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
      videoId:
          videoData?.videoId ?? configService.generateRandomIdOf24Characters(),
      viewRebufferDuration: metricsManager.viewRebufferDuration.toString(),
      viewBufferFrequency: bufferFrequency.toString(),
      mimeType: "",
      fastPixApiVersion: "1.0",
      videoCodec: "",
      hostName: "",
      videoHeight: configService.changeTrack?.height == null
          ? configService.playerObserver?.videoSourceHeight().toString()
          : configService.changeTrack?.height?.toString(),
      videoWidth: configService.changeTrack?.width == null
          ? configService.playerObserver?.videoSourceWidth().toString()
          : configService.changeTrack?.width?.toString(),
      viewBufferPercentage: metricsManager.viewRebufferPercentage.toString(),
      videoLanguage: configService.playerObserver?.playerLanguageCode(),
    );
  }
}
