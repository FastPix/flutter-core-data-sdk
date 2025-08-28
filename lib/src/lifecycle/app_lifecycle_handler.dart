import 'package:flutter/widgets.dart';
import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
import '../dispatcher/event_dispatcher.dart';

class AppLifecycleHandler with WidgetsBindingObserver {
  static final AppLifecycleHandler _instance = AppLifecycleHandler._internal();
  final EventDispatcher _eventDispatcher = EventDispatcher();

  factory AppLifecycleHandler() {
    return _instance;
  }

  AppLifecycleHandler._internal() {
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.detached ||
        state == AppLifecycleState.paused) {
      try {
        await _eventDispatcher.flush(); // Ens
      } catch (e) {
        // Log error but don't throw since this is during app termination
        print('Error sending view completed event during app termination: $e');
      }
    }
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
  }
}
