# littleduck_analytics

Little Duck's one analytics door: anonymous usage counting through
[Aptabase](https://aptabase.com), with the rules built in.

Every Little Duck app counts how it is used through this package and nothing
else. No app imports `aptabase_flutter` directly, so the SDK can be swapped in
one file, and no app can send something the rules forbid, because the rules
run before anything leaves the phone.

Copyright Little Duck Interactive Pty Ltd. Private; not for publishing.

## What gets sent

Aptabase receives an event name, a time, a random session id that resets every
launch and after an hour idle, the OS, the locale and the app version. That is
all. No device id, no advertising id, no account, no user id, so there is no
consent gate: the app offers an off switch in Settings instead.

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
   build never initialises the sink and never sends an event.

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
| Did they come back? | no event: retention comes from App Store Connect and Google Play |

## Use

```dart
import 'package:littleduck_analytics/littleduck_analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Analytics.init(appKey: 'A-EU-0000000000'); // reads the saved switch
  runApp(const App());
}

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
`Analytics.readSwitch()` reads it on its own. Pass `host:` for a self-hosted
Aptabase.

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
> apps. You can turn the counting off in Settings.

## Testing an app that uses it

```dart
import 'package:littleduck_analytics/testing.dart';

final sink = FakeSink();
Analytics.resetForTesting();
Analytics.isDebug = false; // flutter test runs in debug, which sends nothing
SharedPreferences.setMockInitialValues({});
await Analytics.init(appKey: 'A-EU-0000000000', sink: sink);
// ... drive the app ...
expect(sink.eventNames, ['first_run_started', 'first_run_finished']);
```

Another SDK is one more `AnalyticsSink`; the rules, the switch and the
first-run flags stay where they are.

## Developing

The host has no Flutter; run everything in the studio's Flutter image:

```sh
docker run --rm --entrypoint sh -v "$PWD":/work -w /work \
  ghcr.io/littleduckapps/albert-agent-flutter:latest \
  -c '/sdks/flutter/bin/flutter pub get && /sdks/flutter/bin/flutter analyze && /sdks/flutter/bin/flutter test'
```
