import 'sink.dart';

/// One recorded `init` call.
class FakeInit {
  /// Creates a record of an `init` call.
  const FakeInit(this.appKey, this.host);

  /// The app key the sink was initialised with.
  final String appKey;

  /// The host passed, if any.
  final String? host;
}

/// One recorded `track` call.
class FakeEvent {
  /// Creates a record of a `track` call.
  const FakeEvent(this.name, this.props);

  /// The event name.
  final String name;

  /// The properties as the sink received them, after validation.
  final Map<String, Object> props;

  @override
  String toString() => 'FakeEvent($name, $props)';
}

/// A sink that records every call and sends nothing. For tests.
class FakeSink implements AnalyticsSink {
  /// Every `init` call, in order.
  final List<FakeInit> inits = [];

  /// Every `track` call, in order.
  final List<FakeEvent> events = [];

  @override
  Future<void> init(String appKey, {String? host}) async {
    inits.add(FakeInit(appKey, host));
  }

  @override
  void track(String event, Map<String, Object> props) {
    events.add(FakeEvent(event, Map.unmodifiable(props)));
  }

  /// The names of the recorded events, in order.
  List<String> get eventNames => [for (final e in events) e.name];
}
