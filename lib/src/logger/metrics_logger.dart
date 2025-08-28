import 'package:logging/logging.dart';

class MetricsLogger {
  static final _logger = Logger('FastPixMetrics');
  
  static void logEvent(String eventType, Map<String, dynamic> data) {
    _logger.info('Event: $eventType', data);
  }
  
  static void logError(String message, [dynamic error]) {
    _logger.severe(message, error);
  }
}