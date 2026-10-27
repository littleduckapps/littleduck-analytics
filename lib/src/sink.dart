/// Where validated events go.
///
/// The package validates and gates; a sink only sends. `PostHogSink` is the
/// production sink; `FakeSink` (in `package:littleduck_analytics/testing.dart`)
/// records calls for tests. Swapping the analytics service means writing one
/// more sink, nothing else.
abstract class AnalyticsSink {
  /// Prepares the sink for the project [token], optionally against [host].
  Future<void> init(String token, {String? host});

  /// Sends one event. [props] has already passed every rule.
  void track(String event, Map<String, Object> props);

  /// Stops (`false`) or resumes (`true`) everything the sink sends on its
  /// own, not just [track]: the Settings switch.
  Future<void> setEnabled(bool value);
}
