# Changelog

## 0.2.1 — 2026-10-29

- Rage-click capture is off. posthog_flutter turns it on by default on iPhone
  and Mac, where rapid taps would have sent a `$rageclick` event the app never
  asked for.

## 0.2.0 — 2026-10-27

PostHog replaces Aptabase (Albert plan 43).

- `PostHogSink` (posthog_flutter 5.57.1, EU region): no person profiles, and
  none of the SDK's own capture. `AptabaseSink` and `aptabase_flutter` are gone.
- `Analytics.init(token:, app:, ...)` replaces `init(appKey:)`; no token sends
  nothing. Every event carries `app`, `channel` and, in a test build, `build`.
- Consent first in the EU, EEA and UK: `consentFirst`, `hasAnswered`,
  `init(whenUnset:)`, `readSwitch(whenUnset:)`.
- `setEnabled` reaches the sink (`optOut`/`optIn`), so the SDK stops
  everything it would send by itself; `AnalyticsSink.setEnabled` is new.

## 0.1.0 — 2026-10-22

First release.

- `Analytics.init`, `track`, `setEnabled`, `readSwitch`, `firstRunStarted`,
  `firstRunFinished`.
- `AnalyticsRules`: the event-name, property-key and property-value regexes
  and the deny-list, with `checkEvent` and `checkProperty`.
- `Buckets`: `installAge`, `levelsDone`, `balance`, `adsWatched`,
  `sessionLength`.
- `AnalyticsSink` interface, `AptabaseSink` (aptabase_flutter 0.5.0), and
  `FakeSink` in `package:littleduck_analytics/testing.dart`.
- Debug builds send nothing; the off switch is persisted in
  `SharedPreferences` under `littleduck_analytics.enabled`.
