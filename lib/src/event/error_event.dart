import 'package:fastpix_flutter_core_data/src/util/sdk_info.dart';

import '../services/service_locator.dart';
import '../util/device_info_helper.dart';
import '../util/utils.dart';
import 'event_base.dart';

class ErrorEvent extends BaseEvent {
  final String? playerErrorCode;
  final String? playerErrorMessage;
  final String? videoSourceUrl;
  final String? sessionId;
  final String? sessionStart;
  final String? sessionExpires;
  final String? fpViewerId;
  final String? videoTitle;
  final String? videoId;
  final String? playerName;
  final String? playerWidth;
  final String? playerHeight;
  final String? playerVersion;
  final String? videoWidth;
  final String? videoHeight;
  final String? softwareName;
  final String? softwareVersion;
  final String? osName;
  final String? osVersion;
  final String? fpSDKName;
  final String? fpSDKVersion;
  final String? streamType;
  final String? videoHostName;
  final String? deviceName;
  final String? deviceCategory;
  final String? deviceManufacturer;
  final String? deviceModel;

  const ErrorEvent(
      {super.workSpaceId,
      super.viewId,
      super.viewSequenceNumber,
      super.playerSequenceNumber,
      super.beaconDomain,
      super.playheadTime,
      super.viewerTimeStamp,
      super.playerInstanceId,
      super.viewWatchTime,
      super.connectionType,
      this.playerErrorCode,
      this.playerErrorMessage,
      this.sessionId,
      this.sessionStart,
      this.videoSourceUrl,
      this.sessionExpires,
      this.fpViewerId,
      this.videoTitle,
      this.videoId,
      this.playerName,
      this.playerVersion,
      this.playerWidth,
      this.playerHeight,
      this.videoWidth,
      this.videoHeight,
      this.softwareName,
      this.softwareVersion,
      this.osName,
      this.osVersion,
      this.fpSDKName,
      this.fpSDKVersion,
      this.deviceName,
      this.deviceCategory,
      this.deviceManufacturer,
      this.deviceModel,
      this.streamType,
      this.videoHostName});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'plercd': playerErrorCode,
      'plerms': playerErrorMessage,
      'snid': sessionId,
      'snst': sessionStart,
      'snepti': sessionExpires,
      'vdsour': videoSourceUrl,
      'fpviid': fpViewerId,
      'vdtt': videoTitle,
      'vdid': videoId,
      'plna': playerName,
      'plvn': playerVersion,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
      'plswna': softwareName,
      'plswvn': softwareVersion,
      'vicity': connectionType,
      'osna': osName,
      'osvn': osVersion,
      'plfpsdna': fpSDKName,
      'plfpsdvn': fpSDKVersion,
      'vdsmty': streamType,
      'vdsohn': videoHostName,
      'dena': deviceName,
      'decg': deviceCategory,
      'demr': deviceManufacturer,
      'demo': deviceModel,
      'evna': 'error',
    };
  }

  static Future<ErrorEvent> createErrorEvent() async {
    final configService = ServiceLocator().configurationService;
    final sessionService = ServiceLocator().sessionService;
    final baseData = await BaseEvent.getBaseEventData(configService);
    final playerObserver = configService.playerObserver;
    final videoData = configService.videoData;
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final packageInfo = SdkInfo.getPackageInformation();
    // Initialize session if not already initialized
    if (!sessionService.isSessionValid) {
      sessionService.initializeSession();
    }
    return ErrorEvent(
        workSpaceId: baseData['wsid'],
        viewId: baseData['veid'],
        viewSequenceNumber: baseData['vesqnu'],
        playerSequenceNumber: baseData['plsqnu'],
        beaconDomain: baseData['bedn'],
        playheadTime: baseData['plphti'],
        viewerTimeStamp: baseData['vitp'],
        playerInstanceId: baseData['plinid'],
        connectionType: baseData['vicity'],
        viewWatchTime: baseData['vewati'],
        playerErrorCode: playerObserver?.getPlayerError()?.errorCode,
        playerErrorMessage: playerObserver?.getPlayerError()?.errorMessage,
        sessionId: sessionService.sessionId,
        sessionStart: sessionService.sessionStartTime?.toString(),
        sessionExpires: sessionService.sessionExpiryTime?.toString(),
        videoSourceUrl: videoData?.videoUrl,
        fpViewerId: configService.generateUUID(),
        videoTitle: videoData?.videoTitle,
        videoId: videoData?.videoId ??
            configService.generateRandomIdOf24Characters(),
        playerName: configService.playerData?.playerName,
        playerVersion: configService.playerData?.playerVersion,
        playerWidth: playerObserver?.playerWidth().round().toString(),
        playerHeight: playerObserver?.playerHeight().round().toString(),
        videoHeight: configService.changeTrack?.height == null
            ? playerObserver?.videoSourceHeight().toString()
            : configService.changeTrack?.height?.toString(),
        videoWidth: configService.changeTrack?.width == null
            ? playerObserver?.videoSourceWidth().toString()
            : configService.changeTrack?.width?.toString(),
        softwareName: configService.playerData?.playerName,
        softwareVersion: configService.playerData?.playerVersion,
        osName: deviceInfo['osName'],
        osVersion: deviceInfo['osVersion'],
        fpSDKName: packageInfo.sdkName,
        fpSDKVersion: packageInfo.sdkVersion,
        deviceName: deviceInfo['deviceName'],
        deviceModel: deviceInfo['deviceModel'],
        deviceCategory: 'Mobile',
        deviceManufacturer: deviceInfo['deviceManufacturer'],
        streamType:
            playerObserver?.isVideoSourceLive() == true ? 'Live' : 'on-demand',
        videoHostName: Utils.getDomain(videoData?.videoUrl));
  }
}
