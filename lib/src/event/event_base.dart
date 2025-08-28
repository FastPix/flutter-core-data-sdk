import 'package:fastpix_flutter_core_data/src/util/utils.dart';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';

import '../services/configuration/configuration_service.dart';

abstract class BaseEvent {
  final String? workSpaceId;
  final String? viewId;
  final String? viewSequenceNumber;
  final String? playerSequenceNumber;
  final String? beaconDomain;
  final String? playheadTime;
  final String? viewerTimeStamp;
  final String? playerInstanceId;
  final String? viewWatchTime;
  final String? connectionType;

  const BaseEvent(
      {this.workSpaceId,
      this.viewId,
      this.viewSequenceNumber,
      this.playerSequenceNumber,
      this.beaconDomain,
      this.playheadTime,
      this.viewerTimeStamp,
      this.playerInstanceId,
      this.viewWatchTime,
      this.connectionType});

  Map<String, String?> toJson() {
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
      'vicity': connectionType
    };
  }

  static Future<Map<String, String?>> getBaseEventData(
      ConfigurationService configService) async {
    final viewId = configService.viewId;
    final currentTimeStamp = configService.currentTimeStamp();
    final playerObserver = configService.playerObserver;
    final sequenceNumber = configService.incrementSequenceCounter();
    final workSpaceId = configService.workSpaceId;
    final beaconDomain = configService.beaconUrl;
    final playerId = configService.playerId;
    final playHeadTime = await playerObserver?.playerPlayHeadTime();
    final viewWatchTime = ViewWatchTimeCounter.viewWatchTime.toString();
    final connectionType = await Utils.checkNetworkType();
    if (connectionType != null) {
      configService.updateConnectionType(connectionType);
    }
    return {
      'wsid': workSpaceId,
      'veid': viewId,
      'vesqnu': sequenceNumber,
      'plsqnu': sequenceNumber,
      'bedn': beaconDomain,
      'plphti': playHeadTime?.toString(),
      'vitp': currentTimeStamp.toString(),
      'plinid': playerId,
      'vewati': viewWatchTime,
      'vicity': configService.state.connectionType
    };
  }
}
