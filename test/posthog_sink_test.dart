import 'package:flutter_test/flutter_test.dart';
import 'package:littleduck_analytics/littleduck_analytics.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

void main() {
  test(
    "PostHog is set to the EU, anonymous, and sends only the app's events",
    () {
      final config = PostHogSink.config('phc_test');
      expect(config.projectToken, 'phc_test');
      expect(config.host, 'https://eu.i.posthog.com');
      expect(config.personProfiles, PostHogPersonProfiles.never);
      expect(config.captureApplicationLifecycleEvents, isFalse);
      expect(config.sessionReplay, isFalse);
      expect(config.preloadFeatureFlags, isFalse);
      expect(config.sendFeatureFlagEvent, isFalse);
      expect(config.surveys, isFalse);
      expect(config.capturePushNotificationSubscriptions, isFalse);
      expect(config.capturePushNotificationOpened, isFalse);
    },
  );
}
