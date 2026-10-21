import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'aptabase_sink.dart';
import 'rules.dart';
import 'sink.dart';

/// The one door every Little Duck app sends usage counts through.
///
/// ```dart
/// await Analytics.init(appKey: 'A-EU-0000000000');
/// Analytics.track('level_won', {'level': 12, 'ads': Buckets.adsWatched(n)});
/// await Analytics.setEnabled(false); // the Settings switch
/// ```
///
/// No method takes a user id, and the package never reads a device
/// identifier. Every event and property is checked against [AnalyticsRules]
/// before it goes anywhere: in a debug build a bad one throws
/// [ArgumentError]; in a release build it is dropped and `debugPrint`ed once.
/// A debug build never sends anything at all.
abstract final class Analytics {
  /// The `SharedPreferences` key that holds the off switch.
  static const String prefsEnabledKey = 'littleduck_analytics.enabled';

  /// The `SharedPreferences` key set once `first_run_started` has been sent.
  static const String prefsFirstRunStartedKey =
      'littleduck_analytics.first_run_started';

  /// The `SharedPreferences` key set once `first_run_finished` has been sent.
  static const String prefsFirstRunFinishedKey =
      'littleduck_analytics.first_run_finished';

  static bool? _debugOverride;
  static AnalyticsSink? _sink;
  static SharedPreferences? _prefs;
  static bool _enabled = true;
  static final Set<String> _warned = {};

  /// Whether this is a debug build, in which case nothing is ever sent.
  ///
  /// Follows `kDebugMode` unless a test overrides it.
  static bool get isDebug => _debugOverride ?? kDebugMode;

  /// Overrides [isDebug]. Tests only.
  @visibleForTesting
  static set isDebug(bool value) => _debugOverride = value;

  /// Whether counting is switched on. True until [setEnabled] says otherwise.
  static bool get isEnabled => _enabled;

  /// Whether [init] has run.
  static bool get isInitialised => _sink != null;

  /// Reads the persisted switch: `true` unless the person turned it off.
  static Future<bool> readSwitch() async {
    final prefs = await _preferences();
    return prefs.getBool(prefsEnabledKey) ?? true;
  }

  /// Opens the door. Call once, early in `main`.
  ///
  /// [enabled] is the switch; when `null` the persisted value is read (default
  /// on). When given, it is persisted. [sink] replaces the Aptabase sink, for
  /// tests. [host] points Aptabase at a self-hosted server. In a debug build
  /// the sink is never initialised, so nothing can be sent.
  ///
  /// A second call only re-reads the switch; the sink stays as it was.
  static Future<void> init({
    required String appKey,
    bool? enabled,
    AnalyticsSink? sink,
    String? host,
  }) async {
    final prefs = await _preferences();
    if (enabled == null) {
      _enabled = prefs.getBool(prefsEnabledKey) ?? true;
    } else {
      _enabled = enabled;
      await prefs.setBool(prefsEnabledKey, enabled);
    }
    if (_sink != null) {
      return;
    }
    final chosen = sink ?? const AptabaseSink();
    _sink = chosen;
    if (!isDebug) {
      await chosen.init(appKey, host: host);
    }
  }

  /// Counts one [event] with [props].
  ///
  /// The name must match [AnalyticsRules.eventName]; each property key must
  /// match [AnalyticsRules.propertyKey] and stay off the deny-list; each value
  /// is a `bool`, an `int` or a short `String` token. In a debug build a bad
  /// name or property throws [ArgumentError]. In a release build a bad
  /// property is dropped, a bad name drops the whole event, and each offending
  /// name is `debugPrint`ed once.
  ///
  /// Validation runs before the switch, so a bad call is caught in debug even
  /// with counting off. Then: nothing is sent in a debug build, when the
  /// switch is off, or before [init].
  static void track(String event, [Map<String, Object> props = const {}]) {
    final eventProblem = AnalyticsRules.checkEvent(event);
    if (eventProblem != null) {
      _complain('event:$event', eventProblem);
      return;
    }
    final clean = <String, Object>{};
    for (final entry in props.entries) {
      final problem = AnalyticsRules.checkProperty(entry.key, entry.value);
      if (problem == null) {
        clean[entry.key] = entry.value;
      } else {
        _complain('property:${entry.key}', problem);
      }
    }
    final sink = _sink;
    if (isDebug || !_enabled || sink == null) {
      return;
    }
    sink.track(event, clean);
  }

  /// Turns counting on or off, at once and for every later launch.
  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await _preferences();
    await prefs.setBool(prefsEnabledKey, value);
  }

  /// Sends `first_run_started` the first time it is called on this install,
  /// and never again.
  static Future<void> firstRunStarted() =>
      _once(prefsFirstRunStartedKey, 'first_run_started');

  /// Sends `first_run_finished` the first time it is called on this install,
  /// and never again.
  static Future<void> firstRunFinished() =>
      _once(prefsFirstRunFinishedKey, 'first_run_finished');

  /// Forgets everything: sink, switch, debug override, warnings. Tests only.
  /// Persisted flags live in `SharedPreferences`; reset those with
  /// `SharedPreferences.setMockInitialValues`.
  @visibleForTesting
  static void resetForTesting() {
    _debugOverride = null;
    _sink = null;
    _prefs = null;
    _enabled = true;
    _warned.clear();
  }

  static Future<void> _once(String key, String event) async {
    final prefs = await _preferences();
    if (prefs.getBool(key) ?? false) {
      return;
    }
    await prefs.setBool(key, true);
    track(event);
  }

  static Future<SharedPreferences> _preferences() async =>
      _prefs ??= await SharedPreferences.getInstance();

  static void _complain(String name, String problem) {
    if (isDebug) {
      throw ArgumentError(problem);
    }
    if (_warned.add(name)) {
      debugPrint('littleduck_analytics: dropped. $problem');
    }
  }
}
