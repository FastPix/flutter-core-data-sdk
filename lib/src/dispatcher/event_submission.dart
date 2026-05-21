import 'package:fastpix_flutter_core_data/fastpix_flutter_core_data.dart';

/// One unit of work for [SubmissionPipeline]. Stamped synchronously inside
/// `dispatchEvent` so the host's call returns immediately; the pipeline
/// processes these in submission order regardless of how long each build
/// takes.
///
/// (A richer observer-snapshot model is planned for Phase 2b; for now
/// we just carry the event type + attributes and let the builder read
/// from the live observer at build time. The pipeline's serialisation
/// already buys us the ordering guarantee — snapshots will buy us
/// resilience against the observer being mutated between submission and
/// build.)
class EventSubmission {
  final PlayerEvent eventType;
  final Map<String, String>? attributes;

  const EventSubmission(this.eventType, this.attributes);
}
