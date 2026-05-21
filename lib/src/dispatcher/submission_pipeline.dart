import 'dart:async';

import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';
import 'package:fastpix_flutter_core_data/src/logger/metrics_logger.dart';

import 'event_submission.dart';

/// Serialises [EventSubmission]s so they're built, persisted, and queued
/// **in submission order**, regardless of how long each build takes.
///
/// Why this exists:
///   The host fires `fastPixMetrics.dispatchEvent(...)` fire-and-forget
///   from synchronous player callbacks. Different event builders have
///   wildly different async costs (`viewBegin` awaits DeviceInfo, `play`
///   doesn't). Without serialisation, the order events finish ≠ the order
///   they were submitted, so they enter the send queue in the wrong order
///   and the backend sees a malformed transition graph.
///
///   This pipeline drains a single stream with `asyncMap`, which awaits
///   each handler before pulling the next item. No locks held across
///   awaits, so a slow HTTP backoff inside [EventDispatcher] can't freeze
///   the SDK (that was the previous fix's bug). The only thing serialised
///   is the build-and-enqueue step itself.
class SubmissionPipeline {
  SubmissionPipeline({required Future<void> Function(EventSubmission) handler})
      : _handler = handler {
    _subscription = _controller.stream.asyncMap(_runHandler).listen(
      (_) {},
      onError: (Object e, StackTrace s) {
        MetricsLogger.logError('SubmissionPipeline stream error', '$e\n$s');
      },
    );
  }

  final Future<void> Function(EventSubmission) _handler;
  final _controller = StreamController<_PendingSubmission>();
  late final StreamSubscription<dynamic> _subscription;
  bool _closed = false;

  /// Hand a submission to the pipeline. Returns a [Future] that completes
  /// when this specific submission has finished being handled (built +
  /// persisted + queued). `dispose()` uses this to await the terminal
  /// viewCompleted event before tearing down.
  Future<void> submit(EventSubmission submission) {
    if (_closed) {
      MetricsLogger.debug('pipeline:submit:rejected', {
        'reason': 'pipeline_closed',
        'event': submission.eventType.name,
      });
      return Future.value();
    }
    final completer = Completer<void>();
    MetricsLogger.debug('pipeline:submit:add', {
      'event': submission.eventType.name,
    });
    _controller.add(_PendingSubmission(submission, completer));
    return completer.future;
  }

  Future<void> _runHandler(_PendingSubmission p) async {
    MetricsLogger.debug('pipeline:handler:start', {
      'event': p.submission.eventType.name,
    });
    try {
      await _handler(p.submission);
    } catch (e, st) {
      MetricsLogger.logError(
          'pipeline:${p.submission.eventType.name} handler threw', '$e\n$st');
    } finally {
      MetricsLogger.debug('pipeline:handler:finish', {
        'event': p.submission.eventType.name,
      });
      if (!p.completer.isCompleted) p.completer.complete();
    }
  }

  /// Stop accepting new submissions and wait for the in-flight one (if
  /// any) to finish. Used by FastPixMetrics.dispose().
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _controller.close();
    await _subscription.cancel();
  }
}

class _PendingSubmission {
  final EventSubmission submission;
  final Completer<void> completer;
  _PendingSubmission(this.submission, this.completer);
}
