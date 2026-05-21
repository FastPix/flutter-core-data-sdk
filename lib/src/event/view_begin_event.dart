import 'package:fastpix_flutter_core_data/src/model/custom_data.dart';
import 'package:fastpix_flutter_core_data/src/util/device_info_helper.dart';
import 'package:fastpix_flutter_core_data/src/util/sdk_info.dart';
import 'package:fastpix_flutter_core_data/src/util/utils.dart';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';

import '../services/service_locator.dart';
import 'event_base.dart';

class ViewBeginEvent extends BaseEvent {
  final int? viewBegin;
  final String? sessionId;
  final String? sessionStart;
  final String? videoSourceUrl;
  final String? videoHostName;
  final String? sessionExpires;
  final String? fpViewerId;
  final String? videoTitle;
  final String? videoId;
  final String? playerName;
  final String? deviceName;
  final String? deviceCategory;
  final String? deviceManufacturer;
  final String? deviceModel;
  final String? playerVersion;
  final String? playerWidth;
  final String? playerHeight;
  final String? videoWidth;
  final String? videoHeight;
  final String? softwareName;
  final String? softwareVersion;
  final String? osName;
  final String? osVersion;
  final String? fpSDKName;
  final String? fpSDKVersion;
  final String? streamType;
  final String? autoPlay;
  final String? viewSessionId;
  final String? mimeType;
  final String? fastPixApiVersion;
  final String? videoCodec;
  final String? videoLanguage;
  final String? videoDuration;
  final String? videoThumbnail;
  final String? videoSeries;
  final String? videoProducer;
  final String? videoContentType;
  final String? videoVariant;
  final String? applicationName;
  final String? applicationVersion;
  final String? drmType;
  final String? preLoad;
  final String? cm1;
  final String? cm2;
  final String? cm3;
  final String? cm4;
  final String? cm5;
  final String? cm6;
  final String? cm7;
  final String? cm8;
  final String? cm9;
  final String? cm10;
  final String? videoCDN;

  ViewBeginEvent({
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
    this.viewBegin,
    this.sessionId,
    this.sessionStart,
    this.videoSourceUrl,
    this.videoHostName,
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
    this.autoPlay,
    this.viewSessionId,
    this.mimeType,
    this.fastPixApiVersion,
    this.videoCodec,
    this.videoLanguage,
    this.videoDuration,
    this.videoThumbnail,
    this.videoSeries,
    this.videoProducer,
    this.videoContentType,
    this.videoVariant,
    this.applicationName,
    this.applicationVersion,
    this.drmType,
    this.preLoad,
    this.cm1,
    this.cm2,
    this.cm3,
    this.cm4,
    this.cm5,
    this.cm6,
    this.cm7,
    this.cm8,
    this.cm9,
    this.cm10,
    this.videoCDN,
  }) : super(eventName: 'viewBegin');

  @override
  Map<String, dynamic> toJson() {
    final baseJson = super.toJson();
    return {
      ...baseJson,
      'vest': viewBegin,
      'snid': sessionId,
      'snst': sessionStart,
      'vdsour': videoSourceUrl,
      'vdsohn': videoHostName,
      'snepti': sessionExpires,
      'fpviid': fpViewerId,
      'vdtt': videoTitle,
      'vdid': videoId,
      'plna': playerName,
      'dena': deviceName,
      'decg': deviceCategory,
      'demr': deviceManufacturer,
      'demo': deviceModel,
      'plvn': playerVersion,
      'plwt': playerWidth,
      'plht': playerHeight,
      'rqvdwt': videoWidth,
      'rqvdht': videoHeight,
      'plswna': softwareName,
      'plswvn': softwareVersion,
      'osna': osName,
      'osvn': osVersion,
      'plfpsdna': fpSDKName,
      'plfpsdvn': fpSDKVersion,
      'vdsmty': streamType,
      'plauon': autoPlay,
      'vesnid': viewSessionId,
      'vdsomity': mimeType,
      'fpaivn': fastPixApiVersion,
      'vdsocc': videoCodec,
      'vdlncd': videoLanguage,
      'vdsodu': videoDuration,
      'vdpour': videoThumbnail,
      'vdsr': videoSeries,
      'vdpd': videoProducer,
      'vdctty': videoContentType,
      'vdvana': videoVariant,
      'br': applicationName,
      'brvn': applicationVersion,
      'vddmty': drmType,
      'plpron': preLoad,
      'cm1': cm1,
      'cm2': cm2,
      'cm3': cm3,
      'cm4': cm4,
      'cm5': cm5,
      'cm6': cm6,
      'cm7': cm7,
      'cm8': cm8,
      'cm9': cm9,
      'cm10': cm10,
      'vdcn': videoCDN,
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
    final baseData = BaseEvent.getBaseEventData(configService);
    final videoData = configService.videoData;
    final playerObserver = configService.playerObserver;
    final deviceInfo = await DeviceInfoHelper.getDeviceInfo();
    final packageInfo = SdkInfo.getPackageInformation();
    metrixService.updateViewBeginTime(DateTime.now());
    if (!sessionService.isSessionValid) {
      sessionService.initializeSession();
    }
    return ViewBeginEvent(
      workSpaceId: baseData.workSpaceId,
      viewId: baseData.viewId,
      viewSequenceNumber: baseData.viewSequenceNumber,
      playerSequenceNumber: baseData.playerSequenceNumber,
      beaconDomain: baseData.beaconDomain,
      playheadTime: baseData.playheadTime,
      viewerTimeStamp: _decrementedViewerTimeStamp(baseData.viewerTimeStamp),
      playerInstanceId: baseData.playerInstanceId,
      connectionType: baseData.connectionType,
      viewWatchTime: ViewWatchTimeCounter.viewWatchTime.toString(),
      isPlayerFullScreen: baseData.isPlayerFullScreen,
      autoPlay: playerObserver?.isPlayerAutoPlayOn().toString(),
      viewBegin: configService.currentTimeStamp(),
      sessionId: sessionService.sessionId,
      sessionStart: sessionService.sessionStartTime?.toString(),
      sessionExpires: sessionService.sessionExpiryTime?.toString(),
      videoSourceUrl: playerObserver?.videoSourceUrl() ?? videoData?.videoUrl,
      fpViewerId: configService.viewerId,
      videoTitle: videoData?.videoTitle,
      videoId:
          videoData?.videoId ?? configService.generateRandomIdOf24Characters(),
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
      cm3: null,
      cm4: null,
      cm5: null,
      cm6: null,
      cm7: null,
      cm8: null,
      cm9: null,
      cm10: null,
      deviceName: deviceInfo['deviceName'],
      deviceModel: deviceInfo['deviceModel'],
      deviceCategory: 'Mobile',
      deviceManufacturer: deviceInfo['deviceManufacturer'],
      viewSessionId: sessionService.sessionId,
      mimeType: playerObserver?.videoSourceMimeType(),
      fastPixApiVersion: '1.0',
      videoCodec: null,
      videoLanguage: null,
      videoDuration: playerObserver?.videoSourceDuration().toString(),
      videoThumbnail: videoData?.videoThumbnailUrl,
      videoSeries: null,
      videoProducer: null,
      videoContentType: null,
      videoVariant: null,
      applicationName: null,
      applicationVersion: null,
      drmType: null,
      preLoad: null,
      videoCDN: null,
    );
  }

  static _getMetaData2(List<CustomData>? customData) {
    if (customData != null && customData.length >= 2) {
      return customData[1].value;
    } else {
      return '';
    }
  }

  static int? _decrementedViewerTimeStamp(int? value) {
    if (value == null) return null;
    return value - 1;
  }
}
