import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:fastpix_flutter_core_data/src/util/scaling_tracker.dart';
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
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

  CustomData? get customData => _state.customData;

  String? get playerId => _state.playerId;

  PlayerObserver? get playerObserver => _state.playerObserver;

  String? get workSpaceId => _state.workSpaceId;

  String? get beaconUrl => _state.beaconUrl;

  String? get viewId => _state.viewId;

  bool get isSeeking => _state.isSeeking;

  String baseUrl = "stream.fastpix.com";

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

  void updateVideoData(VideoData? videoData) {
    _state = _state.copyWith(videoData: videoData);
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

  void updateBeaconUrl({String url = "anlytix.io"}) {
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

  // Counter methods — view and player sequences are independent (matches Android).
  String incrementViewSequenceCounter() {
    final newCounter = _state.viewSequenceCounter + 1;
    _state = _state.copyWith(viewSequenceCounter: newCounter);
    notifyListeners();
    return newCounter.toString();
  }

  int incrementPlayerSequenceCounter() {
    final newCounter = _state.playerSequenceCounter + 1;
    _state = _state.copyWith(playerSequenceCounter: newCounter);
    notifyListeners();
    return newCounter;
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

  void updateCustomData(CustomData? customData) {
    _state = _state.copyWith(customData: customData);
    notifyListeners();
  }

  // Reset method
  Future<void> reset() async {
    _state = ConfigurationState();
    resetSeekTracking();
    ScalingTracker.instance.reset();
    notifyListeners();
  }

  /// Collects a sampling point for the scaling tracker. Call on
  /// `play`/`playing`/`pulse`. Sync — reads cached playhead from the
  /// observer.
  void collectDataForScaling() {
    final observer = _state.playerObserver;
    if (observer == null) return;
    ScalingTracker.instance.collectDataForScaling(
      currentPlayheadTime: observer.playHeadTime() ?? 0,
      playerWidth: observer.playerWidth() ?? 0,
      playerHeight: observer.playerHeight() ?? 0,
      videoSourceWidth: _getVideoWidth().toInt(),
      videoSourceHeight: _getVideoHeight().toInt(),
    );
  }

  /// Closes the current scaling interval and accumulates the result. Call on
  /// `pause`/`buffering`/`seeking`/`error`/`viewCompleted`. Sync — reads
  /// cached playhead from the observer.
  void calculateScalingForCurrentInterval({int? playheadOverride}) {
    final observer = _state.playerObserver;
    if (observer == null) return;
    final playhead = (playheadOverride ?? observer.playHeadTime()) ?? 0;
    ScalingTracker.instance.calculateScalingForCurrentInterval(playhead);
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
