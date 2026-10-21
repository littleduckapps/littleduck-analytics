import 'package:flutter_test/flutter_test.dart';
import 'package:littleduck_analytics/littleduck_analytics.dart';

void main() {
  final now = DateTime(2026, 10, 22, 12);

  group('installAge', () {
    String age(int days, {int hours = 0}) => Buckets.installAge(
      now.subtract(Duration(days: days, hours: hours)),
      now: now,
    );

    test('boundaries', () {
      expect(age(0), 'd0');
      expect(age(0, hours: 23), 'd0');
      expect(age(1), 'd1_3');
      expect(age(3), 'd1_3');
      expect(age(3, hours: 23), 'd1_3');
      expect(age(4), 'd4_7');
      expect(age(7), 'd4_7');
      expect(age(8), 'd8_30');
      expect(age(30), 'd8_30');
      expect(age(31), 'd30_plus');
      expect(age(400), 'd30_plus');
    });

    test('a clock set before the install is d0', () {
      expect(
        Buckets.installAge(now.add(const Duration(days: 2)), now: now),
        'd0',
      );
    });

    test('defaults to the current time', () {
      expect(Buckets.installAge(DateTime.now()), 'd0');
    });
  });

  test('levelsDone boundaries', () {
    expect(Buckets.levelsDone(-1), '0');
    expect(Buckets.levelsDone(0), '0');
    expect(Buckets.levelsDone(1), '1_10');
    expect(Buckets.levelsDone(10), '1_10');
    expect(Buckets.levelsDone(11), '11_50');
    expect(Buckets.levelsDone(50), '11_50');
    expect(Buckets.levelsDone(51), '51_plus');
    expect(Buckets.levelsDone(1000), '51_plus');
  });

  group('balance', () {
    String b(int v) => Buckets.balance(v, low: 100, high: 1000);

    test('boundaries', () {
      expect(b(-5), 'empty');
      expect(b(0), 'empty');
      expect(b(1), 'low');
      expect(b(99), 'low');
      expect(b(100), 'mid');
      expect(b(999), 'mid');
      expect(b(1000), 'high');
      expect(b(1000000), 'high');
    });

    test('refuses thresholds that make no sense', () {
      expect(() => Buckets.balance(1, low: 0, high: 10), throwsArgumentError);
      expect(() => Buckets.balance(1, low: 10, high: 10), throwsArgumentError);
      expect(() => Buckets.balance(1, low: 20, high: 10), throwsArgumentError);
    });
  });

  test('adsWatched boundaries', () {
    expect(Buckets.adsWatched(-1), '0');
    expect(Buckets.adsWatched(0), '0');
    expect(Buckets.adsWatched(1), '1_5');
    expect(Buckets.adsWatched(5), '1_5');
    expect(Buckets.adsWatched(6), '6_20');
    expect(Buckets.adsWatched(20), '6_20');
    expect(Buckets.adsWatched(21), '21_plus');
    expect(Buckets.adsWatched(500), '21_plus');
  });

  test('sessionLength boundaries', () {
    expect(Buckets.sessionLength(Duration.zero), 'under_1');
    expect(Buckets.sessionLength(const Duration(seconds: 59)), 'under_1');
    expect(Buckets.sessionLength(const Duration(minutes: 1)), '1_5');
    expect(
      Buckets.sessionLength(const Duration(minutes: 4, seconds: 59)),
      '1_5',
    );
    expect(Buckets.sessionLength(const Duration(minutes: 5)), '5_15');
    expect(
      Buckets.sessionLength(const Duration(minutes: 14, seconds: 59)),
      '5_15',
    );
    expect(Buckets.sessionLength(const Duration(minutes: 15)), 'over_15');
    expect(Buckets.sessionLength(const Duration(hours: 3)), 'over_15');
  });

  test('every token passes the property-value rule', () {
    final tokens = <String>{
      for (final d in [0, 1, 3, 4, 7, 8, 30, 31])
        Buckets.installAge(now.subtract(Duration(days: d)), now: now),
      for (final n in [0, 1, 10, 11, 50, 51]) Buckets.levelsDone(n),
      for (final n in [0, 1, 100, 1000])
        Buckets.balance(n, low: 100, high: 1000),
      for (final n in [0, 1, 5, 6, 20, 21]) Buckets.adsWatched(n),
      for (final m in [0, 1, 5, 15])
        Buckets.sessionLength(Duration(minutes: m)),
    };
    // 21 tokens, 19 distinct: '0' and '1_5' are shared between helpers.
    expect(tokens, hasLength(19));
    for (final token in tokens) {
      expect(
        AnalyticsRules.propertyValue.hasMatch(token),
        isTrue,
        reason: token,
      );
      expect(AnalyticsRules.checkProperty('bucket', token), isNull);
    }
  });
}
