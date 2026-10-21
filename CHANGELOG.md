# Changelog

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
