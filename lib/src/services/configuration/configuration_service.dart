import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fastpix_flutter_core_data/flutter_core_data_sdk.dart';
import 'package:fastpix_flutter_core_data/src/model/change_track.dart';
import 'package:uuid/uuid.dart';
import 'configuration_state.dart';

class ConfigurationService extends ChangeNotifier {
  ConfigurationState _state = ConfigurationState();
  final _uuid = Uuid();

  ConfigurationState get state => _state;

  // Getters for commonly accessed values
  PlayerData? get playerData => _state.playerData;

  VideoData? get videoData => _state.videoData;

  ChangeTrack? get changeTrack => _state.changeTrack;

  String? get connectionType => _state.connectionType;

  String? get viewerId => _state.viewerId;

  List<CustomData>? get customData => _state.customData;

  String? get playerId => _state.playerId;

  PlayerObserver? get playerObserver => _state.playerObserver;

  String? get workSpaceId => _state.workSpaceId;

  String? get beaconUrl => _state.beaconUrl;

  String? get viewId => _state.viewId;

  bool get isSeeking => _state.isSeeking;

  String baseUrl = "stream.fastpix.io";

  void updateSeeking(bool value) {
    _state = _state.copyWith(isSeeking: value);
    notifyListeners();
  }

  int _seekingPlayHeadTime = 0;
  int _seekedPlayHeadTime = 0;
  int _totalSeekTime = 0;

  // Update methods
  void updatePlayerData(PlayerData data) {
    _state = _state.copyWith(playerData: data);
    notifyListeners();
  }

  void updateConnectionType(String connectionType) {
    _state = _state.copyWith(connectionType: connectionType);
    notifyListeners();
  }

  void updateChangeTrack(ChangeTrack changeTrack) {
    _state = _state.copyWith(changeTrack: changeTrack);
    notifyListeners();
  }

  void updateVideoData(VideoData data) {
    _state = _state.copyWith(videoData: data);
    notifyListeners();
  }

  void updateViewerId(String id) {
    _state = _state.copyWith(viewerId: id);
    notifyListeners();
  }

  void updateViewId(String id) {
    _state = _state.copyWith(viewId: id);
    notifyListeners();
  }

  void updateIsViewBeginCalled() {
    _state = _state.copyWith(isViewBeginCalled: true);
    notifyListeners();
  }

  void updatePlayerObserver(PlayerObserver observer) {
    _state = _state.copyWith(playerObserver: observer);
    notifyListeners();
  }

  void setPlayerId(String id) {
    _state = _state.copyWith(playerId: id);
    notifyListeners();
  }

  void updateWorkSpaceId(String id) {
    _state = _state.copyWith(workSpaceId: id);
    notifyListeners();
  }

  void updateBeaconUrl(String url) {
    _state = _state.copyWith(beaconUrl: url);
    notifyListeners();
  }

  void updateBaseURL() {
    if (_state.workSpaceId != null && _state.beaconUrl != null) {
      baseUrl = 'https://${_state.workSpaceId}.${_state.beaconUrl}';
    }
  }

  // Timestamp methods
  void updateViewPlayTimeStamp(int timestamp) {
    _state = _state.copyWith(viewPlayTimeStamp: timestamp);
    notifyListeners();
  }

  void updateViewerTimeStamp(int timestamp) {
    _state = _state.copyWith(viewerTimeStamp: timestamp);
    notifyListeners();
  }

  // Counter methods
  String incrementSequenceCounter() {
    final newCounter = _state.sequenceCounter + 1;
    _state = _state.copyWith(sequenceCounter: newCounter);
    notifyListeners();
    return newCounter.toString();
  }

  // Utility methods
  int currentTimeStamp() {
    return DateTime.now().millisecondsSinceEpoch;
  }

  String generateUUID() {
    return _uuid.v4();
  }

  String generateRandomIdOf24Characters() {
    const chars = '0123456789abcdef';
    final rand = Random.secure();
    return List.generate(24, (_) => chars[rand.nextInt(16)]).join();
  }

  void updateViewTotalDownScaling(int scaling) {
    _state = _state.copyWith(viewTotalDownScaling: scaling);
    notifyListeners();
  }

  void updateViewTotalUpScaling(int scaling) {
    _state = _state.copyWith(viewTotalUpScaling: scaling);
    notifyListeners();
  }

  void updateViewMaxDownScalePercentage(int percentage) {
    _state = _state.copyWith(viewMaxDownScalePercentage: percentage);
    notifyListeners();
  }

  void updateCustomData(List<CustomData> list) {
    _state = _state.copyWith(customData: list);
    notifyListeners();
  }

  void updateViewMaxUpScalePercentage(int percentage) {
    _state = _state.copyWith(viewMaxUpScalePercentage: percentage);
    notifyListeners();
  }

  // Reset method
  Future<void> reset() async {
    _state = ConfigurationState();
    // Reset instance variables that are not part of the state
    resetSeekTracking();
    notifyListeners();
  }

  Future<void> calculateViewScaling() async {
    final playerHeight = _state.playerObserver?.playerHeight() ?? 0;
    final playerWidth = _state.playerObserver?.playerWidth() ?? 0;
    final videoHeight = _getVideoHeight();
    final videoWidth = _getVideoWidth();
    final widthScale = playerWidth / videoWidth;
    final heightScale = playerHeight / videoHeight;

    // average scale factor
    final scale = (widthScale + heightScale) / 2;

    double upscalePercentage = 0;
    double downscalePercentage = 0;

    if (scale > 1) {
      upscalePercentage = (scale - 1);
    } else if (scale < 1) {
      downscalePercentage = (1 - scale);
    }
    updateViewTotalDownScaling(downscalePercentage.toInt());
    updateViewTotalUpScaling(upscalePercentage.toInt());
    updateViewMaxUpScalePercentage(upscalePercentage.toInt());
    updateViewMaxDownScalePercentage(downscalePercentage.toInt());
  }

  int calculateTotalSeekedTime() {
    if (_seekedPlayHeadTime != 0 && _seekingPlayHeadTime != 0) {
      final seekDuration = _seekedPlayHeadTime - _seekingPlayHeadTime;
      // Only add positive seek durations to prevent negative values
      if (seekDuration > 0) {
        _totalSeekTime += seekDuration;
      }
      _seekingPlayHeadTime = 0;
      _seekedPlayHeadTime = 0;
    }
    // Ensure we never return negative values
    return _totalSeekTime > 0 ? _totalSeekTime : 0;
  }

  /// Reset seek tracking state completely
  void resetSeekTracking() {
    _seekingPlayHeadTime = 0;
    _seekedPlayHeadTime = 0;
    _totalSeekTime = 0;
  }

  /// Initialize for new video session
  /// This ensures proper synchronization between ConfigurationService and MetricsStateManager
  void initializeForNewVideoSession() {
    // Reset seek tracking
    resetSeekTracking();

    // Reset state
    _state = ConfigurationState();
    notifyListeners();
  }

  int _getVideoWidth() {
    if (_state.changeTrack?.width != null) {
      return int.parse(_state.changeTrack!.width!);
    }
    return _state.playerObserver?.videoSourceWidth() ?? 0;
  }

  int _getVideoHeight() {
    if (_state.changeTrack?.height != null) {
      return int.parse(_state.changeTrack!.height!);
    }
    return _state.playerObserver?.videoSourceHeight() ?? 0;
  }
}
