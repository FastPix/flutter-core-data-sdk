import 'package:fastpix_flutter_core_data/src/metrics/metrics_state_manager.dart';

import 'configuration/configuration_service.dart';
import 'session/session_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();

  factory ServiceLocator() => _instance;

  ServiceLocator._internal();

  ConfigurationService? _configurationService;
  SessionService? _sessionService;
  MetricsStateManager? _metricsStateManager;

  ConfigurationService get configurationService {
    _configurationService ??= ConfigurationService();
    return _configurationService!;
  }

  MetricsStateManager get metricsStateManager {
    _metricsStateManager ??= MetricsStateManager();
    return _metricsStateManager!;
  }

  SessionService get sessionService {
    _sessionService ??= SessionService();
    return _sessionService!;
  }

  // Reset method for testing
  void reset() {
    _configurationService?.reset();
    _metricsStateManager?.reset();
    _sessionService?.reset();

    // Clear all references
    _configurationService = null;
    _sessionService = null;
    _metricsStateManager = null;
  }

  // Comprehensive dispose method for complete cleanup
  Future<void> dispose() async {
    try {
      // Reset all services
      await _configurationService?.reset();
      await _metricsStateManager?.reset();
      _sessionService?.reset();

      // Clear all references
      _configurationService = null;
      _sessionService = null;
      _metricsStateManager = null;
    } catch (e) {
      print('Error during ServiceLocator dispose: $e');
    }
  }
}
