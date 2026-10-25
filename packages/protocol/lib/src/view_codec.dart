import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';

final _id = RegExp(r'^[a-z0-9]{0,16}$');

PlayerId _pid(JsonReader json, String key) {
  final value = json.string(key, max: 16);
  if (!_id.hasMatch(value)) throw ProtocolError('bad id "$key"');
  return PlayerId(value);
}

PlayerId? _maybePid(JsonReader json, String key) =>
    json.maybeString(key) == null ? null : _pid(json, key);

/// Encodes a [PlayerView] as JSON.
Map<String, Object?> encodeView(PlayerView view) => {
  'you': view.you.value,
  'phase': view.phase.name,
  'round': view.round,
  'seats': [
    for (final s in view.seats)
      {
        'id': s.id.value,
        'name': s.name,
        'alive': s.isAlive,
        'role': ?s.role?.name,
      },
  ],
  'deaths': [
    for (final d in view.deaths)
      {
        'player': d.player.value,
        'round': d.round,
        'cause': d.cause.name,
        'role': ?d.role?.name,
      },
  ],
  'waitingFor': view.waitingFor,
  'yourRole': ?view.yourRole?.name,
  'confirmed': view.youConfirmed,
  'nightChoice': ?view.yourNightChoice?.value,
  'voted': view.youVoted,
  'vote': ?view.yourVote?.value,
  'pack': [
    for (final MapEntry(:key, :value) in view.packChoices.entries)
      {'wolf': key.value, 'target': value.value},
  ],
  'seen': [
    for (final r in view.seerResults)
      {
        'target': r.target.value,
        'round': r.round,
        'faction': r.faction.name,
        'role': ?r.role?.name,
      },
  ],
  'winner': ?view.winner?.name,
};

/// Decodes a [PlayerView]; throws a [ProtocolError] for invalid input.
PlayerView decodeView(JsonReader json) => PlayerView(
  you: _pid(json, 'you'),
  phase: json.enumValue('phase', Phase.values),
  round: json.integer('round', max: 1000),
  seats: [
    for (final s in json.objects('seats', max: maxPlayers))
      SeatView(
        id: _pid(s, 'id'),
        name: s.string('name', max: maxNameLength),
        isAlive: s.boolean('alive'),
        role: s.maybeEnum('role', Role.values),
      ),
  ],
  deaths: [
    for (final d in json.objects('deaths', max: maxPlayers))
      DeathView(
        player: _pid(d, 'player'),
        round: d.integer('round', max: 1000),
        cause: d.enumValue('cause', DeathCause.values),
        role: d.maybeEnum('role', Role.values),
      ),
  ],
  waitingFor: json.integer('waitingFor', max: maxPlayers),
  yourRole: json.maybeEnum('yourRole', Role.values),
  youConfirmed: json.boolean('confirmed'),
  yourNightChoice: _maybePid(json, 'nightChoice'),
  youVoted: json.boolean('voted'),
  yourVote: _maybePid(json, 'vote'),
  packChoices: {
    for (final p in json.objects('pack', max: maxPlayers))
      _pid(p, 'wolf'): _pid(p, 'target'),
  },
  seerResults: [
    for (final r in json.objects('seen', max: 1000))
      SeerResult(
        target: _pid(r, 'target'),
        round: r.integer('round', max: 1000),
        faction: r.enumValue('faction', Faction.values),
        role: r.maybeEnum('role', Role.values),
      ),
  ],
  winner: json.maybeEnum('winner', Faction.values),
);
