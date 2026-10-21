import 'package:flutter_test/flutter_test.dart';
import 'package:littleduck_analytics/littleduck_analytics.dart';

void main() {
  test('event names', () {
    expect(AnalyticsRules.checkEvent('abc'), isNull);
    expect(AnalyticsRules.checkEvent('first_run_finished'), isNull);
    expect(AnalyticsRules.checkEvent('a' * 41), isNull);
    expect(AnalyticsRules.checkEvent('ab'), isNotNull);
    expect(AnalyticsRules.checkEvent('a' * 42), isNotNull);
    expect(AnalyticsRules.checkEvent('_abc'), isNotNull);
    expect(AnalyticsRules.checkEvent('9abc'), isNotNull);
    expect(AnalyticsRules.checkEvent('Abc'), isNotNull);
    expect(AnalyticsRules.checkEvent('ab c'), isNotNull);
    expect(AnalyticsRules.checkEvent(''), isNotNull);
  });

  test('property keys', () {
    expect(AnalyticsRules.checkProperty('ab', 1), isNull);
    expect(AnalyticsRules.checkProperty('a${'b' * 32}', 1), isNull);
    expect(AnalyticsRules.checkProperty('a', 1), isNotNull);
    expect(AnalyticsRules.checkProperty('a${'b' * 33}', 1), isNotNull);
    expect(AnalyticsRules.checkProperty('A_b', 1), isNotNull);
    for (final key in AnalyticsRules.deniedKeys) {
      expect(
        AnalyticsRules.checkProperty(key, 'token'),
        isNotNull,
        reason: key,
      );
    }
  });

  test('property values', () {
    expect(AnalyticsRules.checkProperty('kind', true), isNull);
    expect(AnalyticsRules.checkProperty('kind', 0), isNull);
    expect(AnalyticsRules.checkProperty('kind', -7), isNull);
    expect(AnalyticsRules.checkProperty('kind', 'a'), isNull);
    expect(AnalyticsRules.checkProperty('kind', 'a' * 32), isNull);
    expect(AnalyticsRules.checkProperty('kind', 'v1.2-rc_3'), isNull);
    expect(AnalyticsRules.checkProperty('kind', 'a' * 33), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', ''), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', 'Hello'), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', 'two words'), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', 1.5), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', [1]), isNotNull);
    expect(AnalyticsRules.checkProperty('kind', DateTime(2026)), isNotNull);
  });
}
