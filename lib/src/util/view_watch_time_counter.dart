import 'dart:async';

class ViewWatchTimeCounter {
  static int viewWatchTime = 0;
  static bool _isDisposed = false;

  Timer? _timer;

  /// Starts or restarts the counter with thread safety
  void start() {
    _timer = Timer.periodic(Duration(milliseconds: 250), (timer) {
      if (!_isDisposed) {
        viewWatchTime = viewWatchTime + 250;
      }
    });
  }

  /// Cancels the counter with thread safety
  void cancel() {
    if (_timer != null) {
      _timer?.cancel();
      _timer = null;
    }
  }

  /// Returns whether the counter is active
  bool get isRunning => _timer?.isActive ?? false;

  /// Reset the static view watch time with thread safety
  static void reset() {
    viewWatchTime = 0;
    _isDisposed = false;
  }

  /// Dispose the counter and prevent further operations
  void dispose() {
    cancel();
  }

  /// Global dispose - stops all instances
  static void disposeAll() {
    _isDisposed = true;
    reset();
  }
}
