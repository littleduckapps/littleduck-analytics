# littleduck_analytics

Little Duck's one analytics door: anonymous usage counting through
[PostHog](https://posthog.com) in its EU region, with the rules built in.

Every Little Duck app counts how it is used through this package and nothing
else. No app imports `posthog_flutter` directly, so the service can be swapped
in one file, and no app can send something the rules forbid, because the rules
run before anything leaves the phone.

Copyright Little Duck Interactive Pty Ltd. Private; not for publishing.

## What gets sent

PostHog (EU) receives the app's own events, each with a time, the OS, the app
version, the labels below, and a random install id the SDK keeps on the phone
so a return visit counts as the same install. The install id is linked to no
name, account, device id or advertising id, and no person profile is made.
Everything else the SDK can capture by itself is off: session replay, screen
views, app lifecycle events, rage clicks (iPhone), exceptions, feature flags, surveys, push
notifications.

Every event carries three labels: `app` (the product key, e.g. `even-split`),
`channel` (`store`, or the build's `LITTLEDUCK_CHANNEL`, e.g. `qa` for an
epic's test build) and, in a test build, `build` (`LITTLEDUCK_BUILD`, e.g.
`e2-58bb4fb`). The studio has one PostHog project for every app; the labels
tell them apart, and `channel != qa` keeps test builds out of the real numbers.

Storing an install id for counting needs consent in the EU and the EEA:
there, counting starts off until the person says yes
(`Analytics.consentFirst`). Elsewhere it starts on, with the off switch in
Settings. That includes the UK, whose law since 5 February 2026 lets an app
count how it is used to improve itself without asking first, as long as it
says so and gives an off switch.

## The build

```sh
flutter build apk --release \
  --dart-define=POSTHOG_PROJECT_TOKEN=$POSTHOG_PROJECT_TOKEN \
  --dart-define=LITTLEDUCK_CHANNEL=qa --dart-define=LITTLEDUCK_BUILD=e2-58bb4fb
```

A store build passes the token only. A build with no token (the emulator QA's)
sends nothing. The app turns off the SDK's own start-up so the package decides
everything: `com.posthog.posthog.AUTO_INIT` `false` as `<meta-data>` in
`AndroidManifest.xml`'s `<application>`, and as a Boolean in iOS's
`Info.plist`.

## The rules

1. **No identifiers.** No API takes a user id, and the package never reads a
   device identifier. Property keys `email`, `name`, `amount`, `query`,
   `text`, `id`, `user`, `user_id`, `device`, `device_id`, `ip`, `phone`,
   `address`, `location`, `lat` and `lng` are refused outright.
2. **No free text.** A property value is a `bool`, an `int`, or a short token
   matching `^[a-z0-9_.-]{1,32}$`. Nothing a person typed can get through.
3. **No amounts.** Money, balances and other counts that could single someone
   out go through a `Buckets` helper first and arrive as one of a few fixed
   tokens.
4. **Events are decided in the PRD.** The product's `analytics` section names
   every event and the question it answers; the app sends those and no
   others. Event names match `^[a-z][a-z0-9_]{2,40}$`, property keys
   `^[a-z][a-z0-9_]{1,32}$`.
5. **The off switch belongs in Settings.** `Analytics.setEnabled(false)`
   stops counting at once and is remembered for every later launch.
6. **Debug builds send nothing.** Whatever the switch says, a `kDebugMode`
   build never initialises the sink and never sends an event. Neither does a
   build without a token.
7. **Consent first in the EU and EEA.** Until the person answers, the
   switch reads `whenUnset`; their answer is `setEnabled`.

What happens to a call that breaks a rule: in a debug build it throws
`ArgumentError` with a plain message, so the mistake is found at the desk. In
a release build a bad property is dropped, a bad event name drops the whole
event, and each offending name is `debugPrint`ed once.

## The three standard questions

Every phone app answers these three; the PRD adds the app's own on top.

| Question | Event |
| --- | --- |
| Did first run finish? | `first_run_finished` (with `first_run_started` to see the drop-off) |
| Did they do the core thing? | one core action named for the app, e.g. `bill_split`, `level_won` |
| Did they come back? | PostHog's retention, from the install id: no event of its own |

## Use

```dart
import 'package:littleduck_analytics/littleduck_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final country = PlatformDispatcher.instance.locale.countryCode;
  await Analytics.init(
    token: const String.fromEnvironment('POSTHOG_PROJECT_TOKEN'),
    app: 'even-split',
    whenUnset: !Analytics.consentFirst(country), // reads the saved switch
  );
  runApp(const App());
}

// The consent question, while `await Analytics.hasAnswered()` is false in a
// consent-first country: "Yes" is `Analytics.setEnabled(true)`, "No"
// `Analytics.setEnabled(false)`.

// First run, exactly once per install:
await Analytics.firstRunStarted();
// ... the tutorial ...
await Analytics.firstRunFinished();

// The core action:
Analytics.track('level_won', {
  'level': 12,
  'first_try': true,
  'install_age': Buckets.installAge(installedAt),
  'session': Buckets.sessionLength(stopwatch.elapsed),
});

// The Settings switch:
Switch(
  value: Analytics.isEnabled,
  onChanged: (on) => Analytics.setEnabled(on),
);
```

`Analytics.init` reads the persisted switch when `enabled` is not given;
`Analytics.readSwitch(whenUnset: ...)` reads it on its own. `channel` and
`build` default to what the build says; `host:` overrides the EU address.

## The bucket helpers

| Helper | Tokens |
| --- | --- |
| `Buckets.installAge(installedAt)` | `d0`, `d1_3`, `d4_7`, `d8_30`, `d30_plus` (whole days) |
| `Buckets.levelsDone(n)` | `0`, `1_10`, `11_50`, `51_plus` |
| `Buckets.balance(v, low: 100, high: 1000)` | `empty` (≤ 0), `low` (< low), `mid` (< high), `high` |
| `Buckets.adsWatched(n)` | `0`, `1_5`, `6_20`, `21_plus` |
| `Buckets.sessionLength(duration)` | `under_1`, `1_5`, `5_15`, `over_15` (minutes) |

## The privacy sentence

Every app's privacy page carries this, with its name filled in:

> \<App\> counts how it's used, so we can make it better. It doesn't know who
> you are: no advertising ID, no account, nothing that follows you across
> apps. A random number on your phone lets it tell a return visit from a new
> one. You can turn the counting off in Settings.

## Testing an app that uses it

```dart
import 'package:littleduck_analytics/testing.dart';

final sink = FakeSink();
Analytics.resetForTesting();
Analytics.isDebug = false; // flutter test runs in debug, which sends nothing
SharedPreferences.setMockInitialValues({});
await Analytics.init(token: 'phc_test', app: 'even-split', sink: sink);
// ... drive the app ...
expect(sink.eventNames, ['first_run_started', 'first_run_finished']);
```

Another service is one more `AnalyticsSink`; the rules, the switch and the
first-run flags stay where they are.

## Developing

With the host's Flutter (`~/sdks/flutter`), or in the studio's Flutter image:

```sh
docker run --rm --entrypoint sh -v "$PWD":/work -w /work \
  ghcr.io/littleduckapps/albert-agent-flutter:latest \
  -c '/sdks/flutter/bin/flutter pub get && /sdks/flutter/bin/flutter analyze && /sdks/flutter/bin/flutter test'
```
