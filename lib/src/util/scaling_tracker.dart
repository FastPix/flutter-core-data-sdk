import 'dart:math';

/// Mirrors Android's ScalingTracker: two-phase, time-weighted scaling stats.
///
/// Phase 1 — [collectDataForScaling] is called on `play`/`playing`/`pulse` to
/// stamp the interval start (playhead position + current player/video dims).
///
/// Phase 2 — [calculateScalingForCurrentInterval] is called on
/// `pause`/`buffering`/`seeking`/`error`/`viewCompleted`. It closes the
/// interval, computes the up/down-scale percentage from the smaller of the
/// width/height ratios (preserving aspect), and accumulates
/// `percentage * Δtime` into running totals.
class ScalingTracker {
  ScalingTracker._();

  static final ScalingTracker instance = ScalingTracker._();

  int? _intervalStartPlayheadMs;
  int? _intervalPlayerWidth;
  int? _intervalPlayerHeight;
  int? _intervalVideoSourceWidth;
  int? _intervalVideoSourceHeight;

  double _currentMaxUpscale = 0;
  double _currentMaxDownscale = 0;
  int _totalPlaybackTimeMs = 0;
  double _totalUpscalingTimeWeighted = 0;
  double _totalDownscalingTimeWeighted = 0;

  void collectDataForScaling({
    required int currentPlayheadTime,
    required int playerWidth,
    required int playerHeight,
    required int videoSourceWidth,
    required int videoSourceHeight,
  }) {
    _intervalStartPlayheadMs = currentPlayheadTime;
    _intervalPlayerWidth = playerWidth;
    _intervalPlayerHeight = playerHeight;
    _intervalVideoSourceWidth = videoSourceWidth;
    _intervalVideoSourceHeight = videoSourceHeight;
  }

  void calculateScalingForCurrentInterval(int currentPlayheadTime) {
    final start = _intervalStartPlayheadMs;
    final playerW = _intervalPlayerWidth;
    final playerH = _intervalPlayerHeight;
    final videoW = _intervalVideoSourceWidth;
    final videoH = _intervalVideoSourceHeight;
    if (start == null ||
        playerW == null ||
        playerH == null ||
        videoW == null ||
        videoH == null ||
        videoW == 0 ||
        videoH == 0) {
      _clearIntervalData();
      return;
    }
    final timeDelta = currentPlayheadTime - start;
    if (timeDelta <= 0) {
      _clearIntervalData();
      return;
    }
    final widthRatio = playerW / videoW;
    final heightRatio = playerH / videoH;
    final minRatio = min(widthRatio, heightRatio);
    final upscale = max(0.0, minRatio - 1.0);
    final downscale = max(0.0, 1.0 - minRatio);

    _currentMaxUpscale = max(_currentMaxUpscale, upscale);
    _currentMaxDownscale = max(_currentMaxDownscale, downscale);
    _totalPlaybackTimeMs += timeDelta;
    _totalUpscalingTimeWeighted += upscale * timeDelta;
    _totalDownscalingTimeWeighted += downscale * timeDelta;

    _clearIntervalData();
  }

  double get currentMaxUpscale => _currentMaxUpscale;
  double get currentMaxDownscale => _currentMaxDownscale;
  int get totalPlaybackTime => _totalPlaybackTimeMs;
  double get totalUpscalingTimeWeighted => _totalUpscalingTimeWeighted;
  double get totalDownscalingTimeWeighted => _totalDownscalingTimeWeighted;

  void reset() {
    _clearIntervalData();
    _currentMaxUpscale = 0;
    _currentMaxDownscale = 0;
    _totalPlaybackTimeMs = 0;
    _totalUpscalingTimeWeighted = 0;
    _totalDownscalingTimeWeighted = 0;
  }

  void _clearIntervalData() {
    _intervalStartPlayheadMs = null;
    _intervalPlayerWidth = null;
    _intervalPlayerHeight = null;
    _intervalVideoSourceWidth = null;
    _intervalVideoSourceHeight = null;
  }
}
