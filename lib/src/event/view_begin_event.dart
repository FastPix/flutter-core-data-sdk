import 'package:fastpix_flutter_core_data/src/model/custom_data.dart';
import 'package:fastpix_flutter_core_data/src/util/device_info_helper.dart';
import 'package:fastpix_flutter_core_data/src/util/sdk_info.dart';
import 'package:fastpix_flutter_core_data/src/util/utils.dart';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';

import '../services/service_locator.dart';
import 'event_base.dart';

class ViewBeginEvent extends BaseEvent {
  final String? viewBegin;
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
  final String? cm1;
  final String? cm2;
  final String? viewSessionId;
  final String? deviceName;
  final String? deviceCategory;
  final String? deviceManufacturer;
  final String? deviceModel;
  final String? autoPlay;

  const ViewBeginEvent(
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
      this.viewBegin,
      this.sessionId,
      this.sessionStart,
      this.videoSourceUrl,
      this.sessionExpires,
      this.fpViewerId,
      this.videoTitle,
      this.videoId,
      this.playerName,
      this.deviceName,
      this.deviceCategory,
      this.deviceManufacturer,
      this.deviceModel,
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
      this.streamType,
      this.videoHostName,
      this.cm1,
      this.cm2,
      this.autoPlay,
      this.viewSessionId});

  @override
  Map<String, String?> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vest': viewBegin,
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
      'dena': deviceName,
      'decg': deviceCategory,
      'demr': deviceManufacturer,
      'demo': deviceModel,
      'plfpsdvn': fpSDKVersion,
      'vdsmty': streamType,
      'vdsohn': videoHostName,
      'cm1': cm1,
      'cm2': cm2,
      'plauon': autoPlay,
      'vesnid': viewSessionId,
      'evna': 'viewBegin'
    };
  }

  static Future<ViewBeginEvent> createViewBeginEvent() async {
    final configService = ServiceLocator().configurationService;
    final sessionService = ServiceLocator().sessionService;
    final metrixService = ServiceLocator().metricsStateManager;
    configService.updateViewerTimeStamp(configService.currentTimeStamp());
    final customData = configService.customData;
    final metaData1 = customData?.firstOrNull;
    final metaData2 = _getMetaData2(customData);
    final baseData = await BaseEvent.getBaseEventData(configService);
    final videoData = configService.videoData;
    final playerObserver = configService.playerObserver;
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final packageInfo = SdkInfo.getPackageInformation();
    metrixService.updateViewBeginTime(DateTime.now());
    // Initialize session if not already initialized
    if (!sessionService.isSessionValid) {
      sessionService.initializeSession();
    }
    return ViewBeginEvent(
        workSpaceId: baseData['wsid'],
        viewId: baseData['veid'],
        viewSequenceNumber: baseData['vesqnu'],
        playerSequenceNumber: baseData['plsqnu'],
        beaconDomain: baseData['bedn'],
        playheadTime: baseData['plphti'],
        viewerTimeStamp: _getViewerTimeStamp(baseData['vitp']),
        playerInstanceId: baseData['plinid'],
        connectionType: baseData['vicity'],
        viewWatchTime: ViewWatchTimeCounter.viewWatchTime.toString(),
        autoPlay: playerObserver?.isPlayerAutoPlayOn().toString(),
        viewBegin: configService.currentTimeStamp().toString(),
        sessionId: sessionService.sessionId,
        sessionStart: sessionService.sessionStartTime?.toString(),
        sessionExpires: sessionService.sessionExpiryTime?.toString(),
        videoSourceUrl: videoData?.videoUrl,
        fpViewerId: configService.viewerId,
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
        streamType:
            playerObserver?.isVideoSourceLive() == true ? 'Live' : 'on-demand',
        videoHostName: Utils.getDomain(videoData?.videoUrl),
        cm1: metaData1?.value ?? '',
        cm2: metaData2,
        deviceName: deviceInfo['deviceName'],
        deviceModel: deviceInfo['deviceModel'],
        deviceCategory: 'Mobile',
        deviceManufacturer: deviceInfo['deviceManufacturer'],
        viewSessionId: sessionService.sessionId);
  }

  static _getMetaData2(List<CustomData>? customData) {
    if (customData != null && customData.length >= 2) {
      return customData[1].value;
    } else {
      return '';
    }
  }

  static _getViewerTimeStamp(String? baseData) {
    int epoch = int.parse(baseData!);
    int newEpoch = epoch - 1;
    return newEpoch.toString();
  }
}
