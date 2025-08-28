import 'dart:async';
import 'package:fastpix_flutter_core_data/src/util/view_watch_time_counter.dart';
import 'package:synchronized/synchronized.dart';
import 'package:fastpix_flutter_core_data/src/logger/metrics_logger.dart';
import 'package:fastpix_flutter_core_data/src/services/service_locator.dart';

class MetricsStateManager {
  static final MetricsStateManager _instance = MetricsStateManager._internal();
  final _lock = Lock();

  factory MetricsStateManager() => _instance;

  MetricsStateManager._internal();

  // Event tracking
  DateTime? _lastPlayTimestamp;
  DateTime? _lastSeekTimestamp;
  DateTime? _lastBufferStartTimestamp;

  // Enhanced watch time tracking
  double _watchedTimeInSeconds = 0.0;
  double _lastPosition = 0.0;
  bool _isTracking = false;
  bool _isEnhancedSeeking = false;
  double _seekStartPosition = 0.0;

  // Metrics state
  int _viewWatchTime = 0;
  int _viewSeekCount = 0;
  int _viewSeekDuration = 0;
  int _viewRebufferCount = 0;
  int _viewRebufferDuration = 0;
  int _viewTotalContentPlaybackTime = 0;
  double _viewMaxUpscalePercentage = 0.0;
  double _viewMaxDownscalePercentage = 0.0;
  double _viewTotalUpscaling = 0.0;
  double _viewTotalDownscaling = 0.0;
  bool _isPlayerOrientationChanged = false;

  int get viewBeginTime => _viewBegintime;
  int _viewBegintime = 0;

  // Event validation
  bool _isPlaying = false;
  bool _isBuffering = false;

  // Getters for metrics
  int get viewWatchTime => _viewWatchTime;

  /// Get the current cumulative watch time in seconds (excluding seeked time)
  double get watchedTimeInSeconds => _watchedTimeInSeconds;

  bool get isPlayerOrientationChanged => _isPlayerOrientationChanged;

  int get viewSeekCount => _viewSeekCount;

  int get viewSeekDuration => _viewSeekDuration;

  int get viewRebufferCount => _viewRebufferCount;

  int get viewRebufferDuration => _viewRebufferDuration;

  int get viewTotalContentPlaybackTime => _viewTotalContentPlaybackTime;

  double get viewMaxUpscalePercentage => _viewMaxUpscalePercentage;

  double get viewMaxDownscalePercentage => _viewMaxDownscalePercentage;

  double get viewTotalUpscaling => _viewTotalUpscaling;

  double get viewTotalDownscaling => _viewTotalDownscaling;

  // Additional getters for metrics
  int getVideoContentPlaybackTime() => _viewTotalContentPlaybackTime;

  int getViewTotalContentPlayBackTime() => _viewTotalContentPlaybackTime;

  double getViewTotalDownScaling() => _viewTotalDownscaling;

  double getViewTotalUpScaling() => _viewTotalUpscaling;

  double getViewTotalDownScalePercentage() => _viewMaxDownscalePercentage;

  double getViewTotalUpScalePercentage() => _viewMaxUpscalePercentage;

  int getViewMaxSeekDuration() => _viewSeekDuration;

  // Reset all metrics
  Future<void> reset() async {
    await _lock.synchronized(() {
      _lastPlayTimestamp = null;
      _lastSeekTimestamp = null;
      _lastBufferStartTimestamp = null;

      isViewTimeToFirstFrameSent = false;

      // Reset enhanced watch time tracking
      _watchedTimeInSeconds = 0.0;
      _lastPosition = 0.0;
      _isTracking = false;
      _isEnhancedSeeking = false;
      _seekStartPosition = 0.0;

      _isPlayerOrientationChanged = false;

      _viewWatchTime = 0;
      _viewSeekCount = 0;
      _viewSeekDuration = 0;
      _viewRebufferCount = 0;
      _viewRebufferDuration = 0;
      _viewTotalContentPlaybackTime = 0;
      _viewMaxUpscalePercentage = 0.0;
      _viewMaxDownscalePercentage = 0.0;
      _viewTotalUpscaling = 0.0;
      _viewTotalDownscaling = 0.0;

      _isPlaying = false;
      _isBuffering = false;

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'reset',
        'message': 'All metrics reset',
        'watchedTimeInSeconds': _watchedTimeInSeconds
      });
    });
  }

  void updatePlayerOrientationChange() {
    _isPlayerOrientationChanged = true;
  }

  /// Force reset watch time tracking for video switching
  /// This should be called when switching to a new video
  void resetWatchTimeForVideoSwitch() {
    _watchedTimeInSeconds = 0.0;
    _lastPosition = 0.0;
    _isTracking = false;
    _isEnhancedSeeking = false;
    _seekStartPosition = 0.0;
    _isPlaying = false;
    _isBuffering = false;

    MetricsLogger.logEvent('MetricsStateManager', {
      'action': 'resetWatchTimeForVideoSwitch',
      'message': 'Watch time tracking reset for video switch',
      'watchedTimeInSeconds': _watchedTimeInSeconds
    });
  }

  /// Force reset the singleton instance for video switching
  /// This ensures clean state when switching between videos
  static void forceResetForVideoSwitch() {
    _instance.resetWatchTimeForVideoSwitch();
    _instance.reset();

    // Also reset ConfigurationService seek tracking to ensure synchronization
    try {
      final configService = ServiceLocator().configurationService;
      configService.resetSeekTracking();
    } catch (e) {
      MetricsLogger.logError(
          'Error resetting ConfigurationService seek tracking: $e');
    }
  }

  // Play event handling
  Future<void> handlePlay(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (_isPlaying) {
        MetricsLogger.logError('Invalid play event - already playing');
        return;
      }

      _lastPlayTimestamp = timestamp;
      _isPlaying = true;

      MetricsLogger.logEvent('MetricsStateManager',
          {'action': 'play', 'timestamp': timestamp.toIso8601String()});
    });
  }

  // Playing event handling - this is where we update watch time
  Future<void> handlePlaying(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (!_isPlaying) {
        MetricsLogger.logError('Invalid playing event - not playing');
        return;
      }

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'playing',
        'timestamp': timestamp.toIso8601String(),
        'watchedTimeInSeconds': _watchedTimeInSeconds
      });
    });
  }

  bool isViewTimeToFirstFrameSent = false;

  void updateIsViewTimeToFirstFrameSent(bool isViewTimeToFirstFrameSent) {
    this.isViewTimeToFirstFrameSent = isViewTimeToFirstFrameSent;
  }

  void updateViewBeginTime(DateTime timestamp) {
    _viewBegintime = timestamp.millisecondsSinceEpoch;
  }

  // Pause event handling
  Future<void> handlePause(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (!_isPlaying) {
        MetricsLogger.logError('Invalid pause event - not playing');
        return;
      }
      _isPlaying = false;

      if (_lastPlayTimestamp != null) {
        _viewWatchTime +=
            timestamp.difference(_lastPlayTimestamp!).inMilliseconds;
      }

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'pause',
        'timestamp': timestamp.toIso8601String(),
        'watchTime': _viewWatchTime,
        'watchedTimeInSeconds': _watchedTimeInSeconds
      });
    });
  }

  // Seek event handling
  Future<void> handleSeeking(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (_isEnhancedSeeking) {
        MetricsLogger.logError('Invalid seeking event - already seeking');
        return;
      }

      _lastSeekTimestamp = timestamp;
      _isEnhancedSeeking = true;
      _viewSeekCount++;

      // Handle seek start for enhanced tracking
      _handleSeekStart();

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'seeking',
        'timestamp': timestamp.toIso8601String(),
        'seekCount': _viewSeekCount
      });
    });
  }

  Future<void> handleSeeked(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (!_isEnhancedSeeking) {
        MetricsLogger.logError('Invalid seeked event - not seeking');
        return;
      }

      _isEnhancedSeeking = false;

      if (_lastSeekTimestamp != null) {
        final seekDuration =
            timestamp.difference(_lastSeekTimestamp!).inMilliseconds;
        _viewSeekDuration += seekDuration;
      }

      // Handle seek completion for enhanced tracking
      _handleSeekComplete();

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'seeked',
        'timestamp': timestamp.toIso8601String(),
        'seekDuration': _viewSeekDuration,
        'watchedTimeInSeconds': _watchedTimeInSeconds
      });
    });
  }

  /// Handle seek start event
  void _handleSeekStart() {
    if (_isTracking) {
      _isEnhancedSeeking = true;
      _seekStartPosition = _lastPosition;
      MetricsLogger.logEvent('MetricsStateManager',
          {'action': 'seekStart', 'seekStartPosition': _seekStartPosition});
    }
  }

  /// Handle seek complete event
  void _handleSeekComplete() {
    if (_isEnhancedSeeking) {
      _isEnhancedSeeking = false;

      // Note: We need to get the current position from the player observer
      // This will be updated when the progress event is handled
      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'seekComplete',
        'watchedTimeInSeconds': _watchedTimeInSeconds
      });
    }
  }

  // Buffer event handling
  Future<void> handleBuffering(DateTime timestamp) async {
    await _lock.synchronized(() {
      _lastBufferStartTimestamp = timestamp;
      _isBuffering = true;
      _viewRebufferCount++;

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'buffering',
        'timestamp': timestamp.toIso8601String(),
        'rebufferCount': _viewRebufferCount
      });
    });
  }

  Future<void> handleBuffered(DateTime timestamp) async {
    await _lock.synchronized(() {
      if (!_isBuffering) {
        MetricsLogger.logError('Invalid buffered event - not buffering');
        return;
      }

      _isBuffering = false;

      if (_lastBufferStartTimestamp != null) {
        final bufferDuration =
            timestamp.difference(_lastBufferStartTimestamp!).inMilliseconds;
        _viewRebufferDuration += bufferDuration;
      }

      MetricsLogger.logEvent('MetricsStateManager', {
        'action': 'buffered',
        'timestamp': timestamp.toIso8601String(),
        'rebufferDuration': _viewRebufferDuration
      });
    });
  }

  // Helper method to calculate rebuffer frequency
  double getRebufferFrequency() {
    final frequency = _viewRebufferCount /
        (ViewWatchTimeCounter.viewWatchTime); // Convert to seconds
    return frequency;
  }

  // Helper method to calculate rebuffer percentage
  double getRebufferPercentage() {
    if (ViewWatchTimeCounter.viewWatchTime == 0) return 0.0;
    return (_viewRebufferDuration / ViewWatchTimeCounter.viewWatchTime);
  }

  // Getter for rebuffer percentage
  double get viewRebufferPercentage => getRebufferPercentage();
}
