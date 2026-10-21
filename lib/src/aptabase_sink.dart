import 'dart:async';

import 'package:aptabase_flutter/aptabase_flutter.dart';

import 'sink.dart';

/// The production sink: hands validated events to `aptabase_flutter`.
///
/// Aptabase sends an event name, a time, a random session id that resets
/// every launch and after an hour idle, the OS, locale and app version. No
/// device id, no advertising id, no user id.
class AptabaseSink implements AnalyticsSink {
  /// Creates the sink. Nothing happens until [init].
  const AptabaseSink();

  @override
  Future<void> init(String appKey, {String? host}) =>
      Aptabase.init(appKey, InitOptions(host: host));

  @override
  void track(String event, Map<String, Object> props) {
    unawaited(Aptabase.instance.trackEvent(event, props));
  }
}
