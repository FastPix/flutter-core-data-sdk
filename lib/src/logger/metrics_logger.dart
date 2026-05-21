import 'package:logging/logging.dart';

/// Thin facade over `package:logging` plus a console-print path for SDK
/// pipeline debugging.
///
/// Two ways to consume output:
///   1. Wire `Logger.root.onRecord.listen(...)` to receive structured records
///      (works regardless of [enabled]).
///   2. Set [enabled] = true (typically via `MetricsConfiguration.enableLogging`)
///      and every [debug] call also prints to the platform console with a
///      `[FastPix]` tag and an ANSI color picked from the stage prefix.
class MetricsLogger {
  static final _logger = Logger('FastPixMetrics');

  /// Toggles the console-print side of [debug]. Set during SDK init from
  /// `MetricsConfiguration.enableLogging`.
  static bool enabled = false;

  /// Disable to drop ANSI colors (e.g. when piping to a log collector that
  /// doesn't understand escape codes).
  static bool useColors = true;

  // ANSI escape codes. Work in Android Studio's Run console, VS Code's
  // debug console, and most terminals. Stripped automatically when
  // [useColors] is false.
  static const _reset = '\x1B[0m';
  static const _bold = '\x1B[1m';
  static const _red = '\x1B[31m';
  static const _green = '\x1B[32m';
  static const _yellow = '\x1B[33m';
  static const _blue = '\x1B[34m';
  static const _magenta = '\x1B[35m';
  static const _cyan = '\x1B[36m';
  static const _gray = '\x1B[90m';

  static void logEvent(String eventType, Map<String, dynamic> data) {
    _logger.info('Event: $eventType', data);
  }

  static void logError(String message, [dynamic error]) {
    _logger.severe(message, error);
    if (enabled) {
      final tail = error != null ? ' | $error' : '';
      // ignore: avoid_print
      print(_paint('$_bold$_red', '[FastPix][ERROR] $message$tail'));
    }
  }

  /// Pipeline trace point. Use a `stage:action` style label so logs read like
  /// a transcript: `dispatch:received`, `queue:enqueued`, `batch:starting`,
  /// `batch:success`, etc. The first segment (`dispatch`, `queue`, ...) picks
  /// the color.
  static void debug(String stage, [Map<String, dynamic>? data]) {
    _logger.fine(stage, data);
    if (enabled) {
      final payload = data == null || data.isEmpty ? '' : ' $data';
      // ignore: avoid_print
      print(_paint(_colorFor(stage), '[FastPix] $stage$payload'));
    }
  }

  /// Picks a color by stage. Outcome-bearing stages (`*:success`,
  /// `*:failed`, `*:dropped`) override the prefix so wins/losses pop.
  static String _colorFor(String stage) {
    // Outcome-first overrides
    if (stage.endsWith(':success') ||
        stage == 'network:online' ||
        stage == 'flush:done') {
      return _green;
    }
    if (stage.endsWith(':failed') ||
        stage.endsWith(':dropped') ||
        stage.endsWith(':exception') ||
        stage == 'network:offline') {
      return _red;
    }
    // Prefix-based defaults
    final prefix = stage.split(':').first;
    switch (prefix) {
      case 'sdk':
        return '$_bold$_blue';
      case 'dispatch':
        return _cyan;
      case 'queue':
        return _cyan;
      case 'store':
        return _magenta;
      case 'batch':
        return _yellow;
      case 'http':
        return _yellow;
      case 'network':
        return _yellow;
      case 'seed':
        return _magenta;
      case 'flush':
        return _blue;
      case 'dispatcher':
        return _gray;
      default:
        return _gray;
    }
  }

  static String _paint(String color, String text) {
    if (!useColors || color.isEmpty) return text;
    return '$color$text$_reset';
  }
}
