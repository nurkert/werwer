import 'dart:convert';

/// A message that is malformed, too large or from an incompatible version.
/// Receivers drop such messages; they never reach the game.
class ProtocolError implements Exception {
  /// Creates the error.
  const ProtocolError(this.message);

  /// What was wrong (for debugging; never shown to players).
  final String message;

  @override
  String toString() => 'ProtocolError: $message';
}

/// Strict, typed access to a decoded JSON object. Every getter throws a
/// [ProtocolError] for a missing field or a wrong type.
extension type const JsonReader(Map<String, Object?> _map) {
  /// Decodes [raw] as one JSON object of at most [maxBytes] UTF-16 units.
  factory JsonReader.decode(String raw, {required int maxBytes}) {
    if (raw.length > maxBytes) throw const ProtocolError('message too large');
    final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ProtocolError('invalid JSON');
    }
    if (decoded is! Map<String, Object?>) {
      throw const ProtocolError('not an object');
    }
    return JsonReader(decoded);
  }

  /// A required string of at most [max] characters.
  String string(String key, {int max = 64}) {
    final value = _map[key];
    if (value is! String || value.length > max) {
      throw ProtocolError('bad string "$key"');
    }
    return value;
  }

  /// An optional string of at most [max] characters.
  String? maybeString(String key, {int max = 64}) =>
      _map[key] == null ? null : string(key, max: max);

  /// A required integer within [min]..[max].
  int integer(String key, {int min = 0, int max = 1 << 31}) {
    final value = _map[key];
    if (value is! int || value < min || value > max) {
      throw ProtocolError('bad int "$key"');
    }
    return value;
  }

  /// An optional integer within [min]..[max].
  int? maybeInteger(String key, {int min = 0, int max = 1 << 31}) =>
      _map[key] == null ? null : integer(key, min: min, max: max);

  /// A required boolean.
  bool boolean(String key) {
    final value = _map[key];
    if (value is! bool) throw ProtocolError('bad bool "$key"');
    return value;
  }

  /// A required nested object.
  JsonReader object(String key) {
    final value = _map[key];
    if (value is! Map<String, Object?>) {
      throw ProtocolError('bad object "$key"');
    }
    return JsonReader(value);
  }

  /// A required list of objects with at most [max] entries.
  List<JsonReader> objects(String key, {int max = 64}) {
    final value = _map[key];
    if (value is! List<Object?> || value.length > max) {
      throw ProtocolError('bad list "$key"');
    }
    return [
      for (final item in value)
        if (item is Map<String, Object?>)
          JsonReader(item)
        else
          throw ProtocolError('bad item in "$key"'),
    ];
  }

  /// A required enum value by name.
  T enumValue<T extends Enum>(String key, List<T> values) {
    final name = string(key, max: 32);
    for (final v in values) {
      if (v.name == name) return v;
    }
    throw ProtocolError('bad value "$key"');
  }

  /// An optional enum value by name.
  T? maybeEnum<T extends Enum>(String key, List<T> values) =>
      _map[key] == null ? null : enumValue(key, values);
}
