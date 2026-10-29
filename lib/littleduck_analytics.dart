/// Little Duck's one analytics door.
///
/// Anonymous usage counting through PostHog (EU), with the studio's rules built
/// in: no identifiers, no free text, no amounts; an off switch the app puts in
/// Settings, off until consent in the EU and EEA; debug builds send
/// nothing; every event says which app, channel and build sent it.
///
/// Copyright Little Duck Interactive Pty Ltd.
library;

export 'src/analytics.dart';
export 'src/buckets.dart';
export 'src/posthog_sink.dart';
export 'src/rules.dart';
export 'src/sink.dart';
