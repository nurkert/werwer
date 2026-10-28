import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';

/// Most chronicle entries a message or snapshot may carry (a long game of
/// twenty has a few hundred).
const maxChronicle = 1200;

final _id = RegExp(r'^[a-z0-9]{1,16}$');

PlayerId? _maybeId(JsonReader json, String key) {
  final value = json.maybeString(key, max: 16);
  if (value == null) return null;
  if (!_id.hasMatch(value)) throw ProtocolError('bad id "$key"');
  return PlayerId(value);
}

/// Encodes [entries] compactly.
List<Map<String, Object?>> encodeChronicle(List<ChronicleEntry> entries) => [
  for (final e in entries)
    {
      'r': e.round,
      'k': e.kind.name,
      'a': ?e.actor?.value,
      't': ?e.target?.value,
      if (e.runoff) 'ro': true,
    },
];

/// Decodes the chronicle under [key], or none if it is missing.
List<ChronicleEntry> decodeChronicle(JsonReader json, String key) => [
  if (json.has(key))
    for (final e in json.objects(key, max: maxChronicle))
      ChronicleEntry(
        round: e.integer('r', max: 1000),
        kind: e.enumValue('k', ChronicleKind.values),
        actor: _maybeId(e, 'a'),
        target: _maybeId(e, 't'),
        runoff: e.maybeBoolean('ro') ?? false,
      ),
];
