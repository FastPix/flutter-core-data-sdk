import 'package:flutter/widgets.dart';

import '../dispatcher/event_dispatcher.dart';
import '../logger/metrics_logger.dart';

/// Translates Flutter's `WidgetsBindingObserver` callbacks into SDK actions.
///
/// On `paused` / `hidden` the app is backgrounded but still alive — we just
/// flush the queue so anything buffered is on the wire (and on disk) before a
/// possible OS kill.
///
/// On `detached` the engine is being torn down (typical for app kill / final
/// activity finish). We invoke the registered [_onAppKill] callback if any,
/// which `FastPixMetrics` uses to fire a final `viewCompleted` event before
/// the process dies. Because `detached` is best-effort on mobile (the OS may
/// kill without firing it), the SDK still relies on sqflite persistence as
/// the ultimate safety net — anything queued/inserted before kill is replayed
/// on next SDK init.
class AppLifecycleHandler with WidgetsBindingObserver {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();

  factory AppLifecycleHandler() => _instance;

  AppLifecycleHandler._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  /// Single registered "app is dying, do whatever shutdown you need" callback.
  /// FastPixMetrics sets this on construction and clears it on its own
  /// dispose() so we don't double-fire.
  Future<void> Function()? _onAppKill;

  void setOnAppKill(Future<void> Function()? handler) {
    _onAppKill = handler;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    MetricsLogger.debug('lifecycle:state', {'state': state.name});
    switch (state) {
      case AppLifecycleState.detached:
        // Process is about to die — fire viewCompleted + flush via the
        // registered SDK callback. Best-effort; OS may kill before we finish.
        try {
          if (_onAppKill != null) {
            MetricsLogger.debug('lifecycle:detached:dispose');
            await _onAppKill!();
          } else {
            // No active SDK session — still flush whatever the singleton
            // dispatcher has, in case events are stranded.
            await EventDispatcher().flush();
          }
        } catch (e) {
          MetricsLogger.logError(
              'AppLifecycleHandler.detached handler threw', e);
        }
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
        // App is backgrounded but still running. Don't dispose — user may
        // return. Just flush so queued events survive a subsequent kill.
        try {
          MetricsLogger.debug('lifecycle:${state.name}:flush');
          await EventDispatcher().flush();
        } catch (e) {
          MetricsLogger.logError(
              'AppLifecycleHandler.${state.name} flush failed', e);
        }
        break;
      case AppLifecycleState.resumed:
      case AppLifecycleState.inactive:
        // Nothing to do — playback events from the host will drive the SDK.
        break;
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    _onAppKill = null;
  }
}
