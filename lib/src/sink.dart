/// Where validated events go.
///
/// The package validates and gates; a sink only sends. `AptabaseSink` is the
/// production sink; `FakeSink` (in `package:littleduck_analytics/testing.dart`)
/// records calls for tests. Swapping the analytics SDK means writing one more
/// sink, nothing else.
abstract class AnalyticsSink {
  /// Prepares the sink for [appKey], optionally against a self-hosted [host].
  Future<void> init(String appKey, {String? host});

  /// Sends one event. [props] has already passed every rule.
  void track(String event, Map<String, Object> props);
}
