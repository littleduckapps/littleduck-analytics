/// The rules every event and property must pass, in one place.
///
/// The PRD names the events; this class says what a well-formed event looks
/// like. Nothing that could identify a person, and nothing typed by one, gets
/// through.
abstract final class AnalyticsRules {
  /// An event name: snake_case, 3 to 41 characters, starting with a letter.
  static final RegExp eventName = RegExp(r'^[a-z][a-z0-9_]{2,40}$');

  /// A property key: snake_case, 2 to 33 characters, starting with a letter.
  static final RegExp propertyKey = RegExp(r'^[a-z][a-z0-9_]{1,32}$');

  /// A string property value: a short token, never free text.
  static final RegExp propertyValue = RegExp(r'^[a-z0-9_.-]{1,32}$');

  /// Property keys that are never accepted, whatever their value.
  ///
  /// Each one names a thing that identifies a person, a device, or carries
  /// something a person typed or paid.
  static const Set<String> deniedKeys = {
    'email',
    'name',
    'amount',
    'query',
    'text',
    'id',
    'user',
    'user_id',
    'device',
    'device_id',
    'ip',
    'phone',
    'address',
    'location',
    'lat',
    'lng',
  };

  /// Why [event] is not an acceptable event name, or `null` when it is.
  static String? checkEvent(String event) {
    if (!eventName.hasMatch(event)) {
      return 'Event name "$event" must match ${eventName.pattern} '
          '(snake_case, 3 to 41 characters).';
    }
    return null;
  }

  /// Why the property [key] with [value] is not acceptable, or `null` when
  /// it is.
  ///
  /// A value is a `bool`, an `int`, or a `String` token matching
  /// [propertyValue]. Anything else (a double, free text, a list, an object)
  /// is refused.
  static String? checkProperty(String key, Object value) {
    if (deniedKeys.contains(key)) {
      return 'Property "$key" is on the deny-list: it names an identifier, '
          'free text or an amount, which analytics never carries.';
    }
    if (!propertyKey.hasMatch(key)) {
      return 'Property key "$key" must match ${propertyKey.pattern} '
          '(snake_case, 2 to 33 characters).';
    }
    if (value is bool || value is int) {
      return null;
    }
    if (value is String) {
      if (propertyValue.hasMatch(value)) {
        return null;
      }
      return 'Property "$key" has a value that is not a short token '
          '(${propertyValue.pattern}): free text, spaces and capitals are '
          'never sent. Use a bucket or a fixed token instead.';
    }
    return 'Property "$key" has a ${value.runtimeType} value; only bool, int '
        'and short String tokens are sent.';
  }
}
