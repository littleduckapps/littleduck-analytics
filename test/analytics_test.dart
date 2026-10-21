import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:littleduck_analytics/littleduck_analytics.dart';
import 'package:littleduck_analytics/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late FakeSink sink;
  late List<String> printed;
  late DebugPrintCallback originalDebugPrint;

  Future<void> start({bool? enabled}) =>
      Analytics.init(appKey: 'A-EU-0000000000', enabled: enabled, sink: sink);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    Analytics.resetForTesting();
    Analytics.isDebug = false; // flutter test runs in debug; most tests
    // need release behaviour, and the debug tests say so themselves.
    sink = FakeSink();
    printed = [];
    originalDebugPrint = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) {
      printed.add(message ?? '');
    };
  });

  tearDown(() {
    debugPrint = originalDebugPrint;
    Analytics.resetForTesting();
  });

  group('init', () {
    test('initialises the sink with the app key and host', () async {
      await Analytics.init(
        appKey: 'A-EU-0000000000',
        sink: sink,
        host: 'https://aptabase.example',
      );
      expect(sink.inits, hasLength(1));
      expect(sink.inits.single.appKey, 'A-EU-0000000000');
      expect(sink.inits.single.host, 'https://aptabase.example');
    });

    test('a second init keeps the first sink', () async {
      await start();
      final other = FakeSink();
      await Analytics.init(appKey: 'A-EU-0000000000', sink: other);
      Analytics.track('level_won');
      expect(sink.eventNames, ['level_won']);
      expect(other.events, isEmpty);
    });
  });

  group('track', () {
    test('the sink receives the validated props', () async {
      await start();
      Analytics.track('level_won', {
        'level': 12,
        'first_try': true,
        'install_age': 'd1_3',
        'pack': 'v1.2-beta',
      });
      expect(sink.events, hasLength(1));
      expect(sink.events.single.name, 'level_won');
      expect(sink.events.single.props, {
        'level': 12,
        'first_try': true,
        'install_age': 'd1_3',
        'pack': 'v1.2-beta',
      });
    });

    test('an event with no props sends an empty map', () async {
      await start();
      Analytics.track('settings_opened');
      expect(sink.events.single.props, isEmpty);
    });

    test('a free-text property is dropped in release mode', () async {
      await start();
      Analytics.track('search_done', {
        'typed': 'Where is my money',
        'results': 'some',
      });
      expect(sink.events, hasLength(1));
      expect(sink.events.single.props, {'results': 'some'});
      expect(printed, hasLength(1));
      expect(printed.single, contains('typed'));
    });

    test('a free-text property throws in debug mode', () async {
      Analytics.isDebug = true;
      await start();
      expect(
        () => Analytics.track('search_done', {'typed': 'Where is my money'}),
        throwsArgumentError,
      );
      expect(sink.events, isEmpty);
    });

    test('a bad event name drops the whole event in release mode', () async {
      await start();
      Analytics.track('Level Won', {'level': 1});
      Analytics.track('ab');
      Analytics.track('1_level');
      Analytics.track('this_event_name_is_far_too_long_to_be_accepted');
      expect(sink.events, isEmpty);
      expect(printed, hasLength(4));
    });

    test('a bad event name throws in debug mode', () async {
      Analytics.isDebug = true;
      await start();
      expect(() => Analytics.track('Level Won'), throwsArgumentError);
    });

    test('each offending name is printed once', () async {
      await start();
      Analytics.track('level_won', {'typed': 'a b'});
      Analytics.track('level_won', {'typed': 'c d'});
      Analytics.track('Bad Name');
      Analytics.track('Bad Name');
      expect(printed, hasLength(2));
    });

    test('deny-listed keys are dropped whatever their value', () async {
      await start();
      Analytics.track('bill_split', {
        'email': 'ok_token',
        'name': 'x',
        'amount': 42,
        'query': 'q',
        'text': 't',
        'id': 1,
        'user': 'u',
        'user_id': 2,
        'device': 'd',
        'device_id': 3,
        'ip': 'v4',
        'phone': 'p',
        'address': 'a',
        'location': 'l',
        'lat': 1,
        'lng': 2,
        'people': 4,
      });
      expect(sink.events.single.props, {'people': 4});
      expect(printed, hasLength(16));
    });

    test('bad keys and non-token values are dropped', () async {
      await start();
      Analytics.track('bill_split', {
        'Level': 1,
        'a': 1,
        'with-dash': 1,
        'this_key_is_much_too_long_for_a_property': 1,
        'ratio': 0.5,
        'list': [1, 2],
        'empty': '',
        'long': 'abcdefghijklmnopqrstuvwxyz0123456789',
        'ok': 'abc-1.2_x',
      });
      expect(sink.events.single.props, {'ok': 'abc-1.2_x'});
    });

    test('validation still runs in debug when the switch is off', () async {
      Analytics.isDebug = true;
      await start(enabled: false);
      expect(
        () => Analytics.track('level_won', {'typed': 'free text'}),
        throwsArgumentError,
      );
    });

    test('before init nothing is sent and nothing breaks', () {
      Analytics.track('level_won');
      expect(sink.events, isEmpty);
    });
  });

  group('the switch', () {
    test('off stops sends at once and persists', () async {
      await start();
      Analytics.track('level_won');
      await Analytics.setEnabled(false);
      Analytics.track('level_lost');
      expect(sink.eventNames, ['level_won']);
      expect(Analytics.isEnabled, isFalse);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(Analytics.prefsEnabledKey), isFalse);
      expect(await Analytics.readSwitch(), isFalse);
    });

    test('a persisted off is read on the next init', () async {
      SharedPreferences.setMockInitialValues({
        Analytics.prefsEnabledKey: false,
      });
      await start();
      expect(Analytics.isEnabled, isFalse);
      Analytics.track('level_won');
      expect(sink.events, isEmpty);
    });

    test('back on resumes sends', () async {
      await start(enabled: false);
      Analytics.track('level_won');
      await Analytics.setEnabled(true);
      Analytics.track('level_lost');
      expect(sink.eventNames, ['level_lost']);
    });

    test('an explicit enabled on init is persisted', () async {
      await start(enabled: false);
      expect(await Analytics.readSwitch(), isFalse);
    });

    test('defaults to on', () async {
      expect(await Analytics.readSwitch(), isTrue);
      await start();
      expect(Analytics.isEnabled, isTrue);
    });
  });

  group('debug builds', () {
    test('send nothing, whatever the switch', () async {
      Analytics.isDebug = true;
      await start(enabled: true);
      Analytics.track('level_won', {'level': 1});
      await Analytics.firstRunStarted();
      expect(sink.inits, isEmpty);
      expect(sink.events, isEmpty);
    });

    test('isDebug follows kDebugMode unless overridden', () {
      Analytics.resetForTesting();
      expect(Analytics.isDebug, kDebugMode);
    });
  });

  group('first run', () {
    test('each event fires exactly once per install', () async {
      await start();
      await Analytics.firstRunStarted();
      await Analytics.firstRunStarted();
      await Analytics.firstRunFinished();
      await Analytics.firstRunFinished();
      expect(sink.eventNames, ['first_run_started', 'first_run_finished']);

      // A later launch on the same install: the flags are persisted.
      Analytics.resetForTesting();
      Analytics.isDebug = false;
      sink = FakeSink();
      await start();
      await Analytics.firstRunStarted();
      await Analytics.firstRunFinished();
      expect(sink.events, isEmpty);
    });

    test('flags are persisted under the documented keys', () async {
      await start();
      await Analytics.firstRunFinished();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool(Analytics.prefsFirstRunFinishedKey), isTrue);
      expect(prefs.getBool(Analytics.prefsFirstRunStartedKey), isNull);
    });
  });
}
