import 'package:flutter/foundation.dart';
import 'package:fastpix_flutter_core_data/flutter_core_data_sdk.dart';
import 'package:fastpix_flutter_core_data/src/model/change_track.dart';

@immutable
class ConfigurationState {
  final PlayerData? playerData;
  final VideoData? videoData;
  final String? viewerId;
  final PlayerObserver? playerObserver;
  final bool isViewBeginCalled;
  final String? playerId;
  final String? workSpaceId;
  final String? beaconUrl;
  final String? baseURL;
  final String? viewId;
  final int? viewPlayTimeStamp;
  final int? viewPauseTimeStamp;
  final int? viewerTimeStamp;
  final ChangeTrack? changeTrack;
  final String? connectionType;
  final int viewSeekCount;
  final int sequenceCounter;
  final Map<String, int> seekMap;
  final int viewRebufferCount;
  final int bufferStartedTimeStamp;
  final int lastPlayHeadTime;
  final int viewTotalContentPlayBackTime;
  final int viewTotalDownScaling;
  final int viewTotalUpScaling;
  final int viewMaxDownScalePercentage;
  final int viewMaxUpScalePercentage;
  final String viewReBufferDuration;
  final bool isViewTimeToFirstFrameSent;
  final bool isSeeking;
  int viewWatchTime = 0;
  final List<CustomData> customData;

  ConfigurationState(
      {this.playerData,
      this.videoData,
      this.viewerId,
      this.playerId,
      this.playerObserver,
      this.workSpaceId,
      this.beaconUrl,
      this.viewId,
      this.baseURL,
      this.viewPlayTimeStamp,
      this.connectionType,
      this.viewPauseTimeStamp,
      this.changeTrack,
      this.isViewBeginCalled = false,
      this.viewerTimeStamp,
      this.viewSeekCount = 0,
      this.sequenceCounter = 0,
      this.seekMap = const {},
      this.customData = const [],
      this.viewRebufferCount = 0,
      this.bufferStartedTimeStamp = 0,
      this.lastPlayHeadTime = 0,
      this.viewTotalContentPlayBackTime = 0,
      this.viewTotalDownScaling = 0,
      this.viewTotalUpScaling = 0,
      this.viewMaxDownScalePercentage = 0,
      this.viewMaxUpScalePercentage = 0,
      this.viewReBufferDuration = "0",
      this.isViewTimeToFirstFrameSent = false,
      this.isSeeking = false,
      this.viewWatchTime = 0});

  ConfigurationState copyWith(
      {PlayerData? playerData,
      VideoData? videoData,
      String? viewerId,
      PlayerObserver? playerObserver,
      String? workSpaceId,
      String? beaconUrl,
      String? playerId,
      String? baseURL,
      int? viewPlayTimeStamp,
      int? viewPauseTimeStamp,
      int? viewerTimeStamp,
      int? viewSeekCount,
      int? sequenceCounter,
      Map<String, int>? seekMap,
      int? viewRebufferCount,
      int? bufferStartedTimeStamp,
      int? lastPlayHeadTime,
      int? viewTotalContentPlayBackTime,
      int? viewTotalDownScaling,
      int? viewTotalUpScaling,
      int? viewMaxDownScalePercentage,
      int? viewMaxUpScalePercentage,
      String? viewId,
      String? viewReBufferDuration,
      bool? isViewTimeToFirstFrameSent,
      bool? isSeeking,
      int? viewWatchTime,
      List<CustomData>? customData,
      String? connectionType,
      ChangeTrack? changeTrack,
      bool? isViewBeginCalled}) {
    return ConfigurationState(
        playerData: playerData ?? this.playerData,
        videoData: videoData ?? this.videoData,
        viewerId: viewerId ?? this.viewerId,
        playerObserver: playerObserver ?? this.playerObserver,
        playerId: playerId ?? this.playerId,
        workSpaceId: workSpaceId ?? this.workSpaceId,
        beaconUrl: beaconUrl ?? this.beaconUrl,
        baseURL: baseURL ?? this.baseURL,
        viewPlayTimeStamp: viewPlayTimeStamp ?? this.viewPlayTimeStamp,
        viewPauseTimeStamp: viewPauseTimeStamp ?? this.viewPauseTimeStamp,
        viewerTimeStamp: viewerTimeStamp ?? this.viewerTimeStamp,
        viewSeekCount: viewSeekCount ?? this.viewSeekCount,
        sequenceCounter: sequenceCounter ?? this.sequenceCounter,
        seekMap: seekMap ?? this.seekMap,
        viewRebufferCount: viewRebufferCount ?? this.viewRebufferCount,
        bufferStartedTimeStamp:
            bufferStartedTimeStamp ?? this.bufferStartedTimeStamp,
        lastPlayHeadTime: lastPlayHeadTime ?? this.lastPlayHeadTime,
        viewTotalContentPlayBackTime:
            viewTotalContentPlayBackTime ?? this.viewTotalContentPlayBackTime,
        viewTotalDownScaling: viewTotalDownScaling ?? this.viewTotalDownScaling,
        viewTotalUpScaling: viewTotalUpScaling ?? this.viewTotalUpScaling,
        viewMaxDownScalePercentage:
            viewMaxDownScalePercentage ?? this.viewMaxDownScalePercentage,
        viewMaxUpScalePercentage:
            viewMaxUpScalePercentage ?? this.viewMaxUpScalePercentage,
        viewReBufferDuration: viewReBufferDuration ?? this.viewReBufferDuration,
        viewId: viewId ?? this.viewId,
        isViewTimeToFirstFrameSent:
            isViewTimeToFirstFrameSent ?? this.isViewTimeToFirstFrameSent,
        isSeeking: isSeeking ?? this.isSeeking,
        changeTrack: changeTrack ?? this.changeTrack,
        viewWatchTime: viewWatchTime ?? this.viewWatchTime,
        customData: customData ?? this.customData,
        connectionType: connectionType ?? this.connectionType,
        isViewBeginCalled: isViewBeginCalled ?? this.isViewBeginCalled);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConfigurationState &&
        other.playerData == playerData &&
        other.videoData == videoData &&
        other.viewerId == viewerId &&
        other.playerObserver == playerObserver &&
        other.workSpaceId == workSpaceId &&
        other.beaconUrl == beaconUrl &&
        other.baseURL == baseURL &&
        other.viewPlayTimeStamp == viewPlayTimeStamp &&
        other.viewPauseTimeStamp == viewPauseTimeStamp &&
        other.viewerTimeStamp == viewerTimeStamp &&
        other.viewSeekCount == viewSeekCount &&
        other.sequenceCounter == sequenceCounter &&
        mapEquals(other.seekMap, seekMap) &&
        other.viewRebufferCount == viewRebufferCount &&
        other.bufferStartedTimeStamp == bufferStartedTimeStamp &&
        other.lastPlayHeadTime == lastPlayHeadTime &&
        other.viewTotalContentPlayBackTime == viewTotalContentPlayBackTime &&
        other.viewTotalDownScaling == viewTotalDownScaling &&
        other.viewTotalUpScaling == viewTotalUpScaling &&
        other.playerId == playerId &&
        other.viewMaxDownScalePercentage == viewMaxDownScalePercentage &&
        other.viewReBufferDuration == viewReBufferDuration &&
        other.viewId == viewId &&
        other.isViewTimeToFirstFrameSent == isViewTimeToFirstFrameSent &&
        other.isSeeking == isSeeking &&
        other.viewWatchTime == viewWatchTime &&
        other.customData == customData &&
        other.isViewBeginCalled == isViewBeginCalled &&
        other.connectionType == connectionType &&
        other.changeTrack == changeTrack &&
        other.viewMaxUpScalePercentage == viewMaxUpScalePercentage;
  }
}
