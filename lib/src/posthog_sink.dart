import 'dart:async';

import 'package:posthog_flutter/posthog_flutter.dart';

import 'sink.dart';

/// The production sink: hands validated events to `posthog_flutter`, in
/// PostHog's EU region.
///
/// PostHog receives the event, a time, the OS, the app version and a random
/// install id the SDK keeps on the phone, so a return visit counts as the same
/// install. The install id is linked to no name, account, device id or
/// advertising id. No person profiles are made, and every capture the SDK
/// offers on its own is off: no session replay, no screen views, no app
/// lifecycle events, no rage clicks (iPhone), no exceptions (a stack trace can carry what someone
/// typed), no feature flags, no surveys, no push notifications. The app's
/// own events, through `Analytics.track`, are all that is sent.
class PostHogSink implements AnalyticsSink {
  /// Creates the sink. Nothing happens until [init].
  const PostHogSink();

  /// PostHog's EU ingestion address.
  static const String euHost = 'https://eu.i.posthog.com';

  /// The SDK's settings for [token]: what [init] sets up.
  static PostHogConfig config(String token, {String? host}) =>
      PostHogConfig(token)
        ..host = host ?? euHost
        ..personProfiles = PostHogPersonProfiles.never
        ..captureApplicationLifecycleEvents = false
        ..sessionReplay = false
        ..preloadFeatureFlags = false
        ..sendFeatureFlagEvent = false
        ..surveys = false
        ..capturePushNotificationSubscriptions = false
        ..capturePushNotificationOpened = false
        ..rageClickConfig.enabled = false;

  @override
  Future<void> init(String token, {String? host}) =>
      Posthog().setup(config(token, host: host));

  @override
  void track(String event, Map<String, Object> props) {
    unawaited(Posthog().capture(eventName: event, properties: props));
  }

  @override
  Future<void> setEnabled(bool value) =>
      value ? Posthog().optIn() : Posthog().optOut();
}
