/// Bucket helpers: turn a number into one of a few fixed tokens.
///
/// Analytics never carries a raw count that could single someone out, so every
/// number goes through one of these first. The tokens come from the games
/// plan and all pass the property-value rule.
abstract final class Buckets {
  /// How long ago the app was installed: `d0`, `d1_3`, `d4_7`, `d8_30` or
  /// `d30_plus`, by whole days between [installedAt] and [now] (default: the
  /// current time).
  static String installAge(DateTime installedAt, {DateTime? now}) {
    final days = (now ?? DateTime.now()).difference(installedAt).inDays;
    if (days <= 0) return 'd0';
    if (days <= 3) return 'd1_3';
    if (days <= 7) return 'd4_7';
    if (days <= 30) return 'd8_30';
    return 'd30_plus';
  }

  /// Levels completed so far: `0`, `1_10`, `11_50` or `51_plus`.
  static String levelsDone(int count) {
    if (count <= 0) return '0';
    if (count <= 10) return '1_10';
    if (count <= 50) return '11_50';
    return '51_plus';
  }

  /// A balance (coins, gems, credits) against two thresholds: `empty` when
  /// [value] is zero or less, `low` below [low], `mid` below [high], else
  /// `high`. [low] must be positive and below [high].
  static String balance(int value, {required int low, required int high}) {
    if (low <= 0 || high <= low) {
      throw ArgumentError(
        'balance needs 0 < low < high, got low=$low high=$high',
      );
    }
    if (value <= 0) return 'empty';
    if (value < low) return 'low';
    if (value < high) return 'mid';
    return 'high';
  }

  /// Rewarded ads watched: `0`, `1_5`, `6_20` or `21_plus`.
  static String adsWatched(int count) {
    if (count <= 0) return '0';
    if (count <= 5) return '1_5';
    if (count <= 20) return '6_20';
    return '21_plus';
  }

  /// A session's length in minutes: `under_1`, `1_5`, `5_15` or `over_15`.
  static String sessionLength(Duration length) {
    if (length < const Duration(minutes: 1)) return 'under_1';
    if (length < const Duration(minutes: 5)) return '1_5';
    if (length < const Duration(minutes: 15)) return '5_15';
    return 'over_15';
  }
}
