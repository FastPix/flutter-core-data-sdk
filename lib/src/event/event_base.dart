import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';

import '../services/configuration/configuration_service.dart';

abstract class BaseEvent {
  final String? workSpaceId;
  final String? viewId;
  final String? viewSequenceNumber;
  final int? playerSequenceNumber;
  final String? beaconDomain;
  final int? playheadTime;
  final int? viewerTimeStamp;
  final String? playerInstanceId;
  final String? viewWatchTime;
  final String? connectionType;
  String? eventName;
  String? isPlayerFullScreen;

  BaseEvent({
    this.workSpaceId,
    this.viewId,
    this.viewSequenceNumber,
    this.playerSequenceNumber,
    this.beaconDomain,
    this.playheadTime,
    this.viewerTimeStamp,
    this.playerInstanceId,
    this.viewWatchTime,
    this.connectionType,
    this.eventName,
    this.isPlayerFullScreen,
  });

  Map<String, dynamic> toJson() {
    return {
      'wsid': workSpaceId,
      'veid': viewId,
      'vesqnu': viewSequenceNumber,
      'plsqnu': playerSequenceNumber,
      'bedn': beaconDomain,
      'plphti': playheadTime,
      'vitp': viewerTimeStamp,
      'plinid': playerInstanceId,
      'vewati': viewWatchTime,
      'vicity': connectionType,
      'evna': eventName,
      'plisfl': isPlayerFullScreen,
    };
  }

  /// Synchronous snapshot of the base fields shared by every event.
  ///
  /// Every method called here is sync — `playerPlayHeadTime()` is now an
  /// `int` getter cached by the host (see [PlayerObserver]). No awaits, no
  /// platform-channel hangs, no dispatch-pipeline freezes.
  static BaseEventData getBaseEventData(ConfigurationService configService) {
    final playerObserver = configService.playerObserver;
    return BaseEventData(
      workSpaceId: configService.workSpaceId,
      viewId: configService.viewId,
      viewSequenceNumber: configService.incrementViewSequenceCounter(),
      playerSequenceNumber: configService.incrementPlayerSequenceCounter(),
      beaconDomain: configService.beaconUrl,
      playheadTime: playerObserver?.playHeadTime(),
      viewerTimeStamp: configService.currentTimeStamp(),
      playerInstanceId: configService.playerId,
      viewWatchTime: ViewWatchTimeCounter.viewWatchTime.toString(),
      // Connection type is refreshed in the background by EventDispatcher's
      // connectivity_plus listener and cached in ConfigurationState. Reading
      // it from cache here avoids a system call on every event.
      connectionType: configService.state.connectionType,
      eventName: '',
      isPlayerFullScreen: playerObserver?.isFullScreen().toString(),
    );
  }
}

class BaseEventData {
  final String? workSpaceId;
  final String? viewId;
  final String? viewSequenceNumber;
  final int? playerSequenceNumber;
  final String? beaconDomain;
  final int? playheadTime;
  final int? viewerTimeStamp;
  final String? playerInstanceId;
  final String? viewWatchTime;
  final String? connectionType;
  String? eventName;
  String? isPlayerFullScreen;

  BaseEventData({
    this.workSpaceId,
    this.viewId,
    this.viewSequenceNumber,
    this.playerSequenceNumber,
    this.beaconDomain,
    this.playheadTime,
    this.viewerTimeStamp,
    this.playerInstanceId,
    this.viewWatchTime,
    this.connectionType,
    this.eventName,
    this.isPlayerFullScreen,
  });
}
