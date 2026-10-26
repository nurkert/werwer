import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';

final _id = RegExp(r'^[a-z0-9]{1,16}$');

PlayerId _pid(JsonReader json, String key) {
  final value = json.string(key, max: 16);
  if (!_id.hasMatch(value)) throw ProtocolError('bad id "$key"');
  return PlayerId(value);
}

List<Map<String, Object?>> _pairs(Map<PlayerId, int> map) => [
  for (final MapEntry(:key, :value) in map.entries)
    {'player': key.value, 'n': value},
];

Map<PlayerId, int> _readPairs(JsonReader json, String key) => {
  for (final p in json.objects(key, max: maxPlayers))
    _pid(p, 'player'): p.integer('n', min: -1000000, max: 1000000),
};

/// The complete [GameState] as JSON, so the host can save it and continue
/// after a crash. Contains every secret of the game: keep it on the host
/// device only.
Map<String, Object?> encodeState(GameState state) => {
  'players': [
    for (final p in state.players)
      {
        'id': p.id.value,
        'name': p.name,
        'persona': p.persona.name,
        'role': ?p.role?.name,
        'alive': p.isAlive,
      },
  ],
  'phase': state.phase.name,
  'round': state.round,
  'revealRoleOnDeath': state.settings.revealRoleOnDeath,
  'seerSeesRole': state.settings.seerSeesRole,
  'confirmed': [for (final p in state.confirmed) p.value],
  'nightChoices': [
    for (final MapEntry(:key, :value) in state.nightChoices.entries)
      {'player': key.value, 'target': value.value},
  ],
  'votes': [
    for (final MapEntry(:key, :value) in state.votes.entries)
      {'player': key.value, 'target': ?value?.value},
  ],
  'seerResults': [
    for (final MapEntry(:key, :value) in state.seerResults.entries)
      for (final r in value)
        {
          'seer': key.value,
          'target': r.target.value,
          'round': r.round,
          'faction': r.faction.name,
          'role': ?r.role?.name,
        },
  ],
  'deaths': [
    for (final d in state.deaths)
      {'player': d.player.value, 'round': d.round, 'cause': d.cause.name},
  ],
  'sheep': _pairs(state.sheep),
  'lastNightSheep': _pairs(state.lastNightSheep),
  'dreams': _pairs(state.dreams),
  'seed': state.seed,
  'winner': ?state.winner?.name,
};

/// Reads a [GameState] written by [encodeState]; throws a [ProtocolError]
/// for anything invalid.
GameState decodeState(JsonReader json) {
  final seer = <PlayerId, List<SeerResult>>{};
  for (final r in json.objects('seerResults', max: 1000)) {
    (seer[_pid(r, 'seer')] ??= []).add(
      SeerResult(
        target: _pid(r, 'target'),
        round: r.integer('round', max: 1000),
        faction: r.enumValue('faction', Faction.values),
        role: r.maybeEnum('role', Role.values),
      ),
    );
  }
  return GameState(
    players: [
      for (final p in json.objects('players', max: maxPlayers))
        Player(
          id: _pid(p, 'id'),
          name: p.string('name', max: maxNameLength),
          persona: p.enumValue('persona', Persona.values),
          role: p.maybeEnum('role', Role.values),
          isAlive: p.boolean('alive'),
        ),
    ],
    phase: json.enumValue('phase', Phase.values),
    round: json.integer('round', max: 1000),
    settings: GameSettings(
      revealRoleOnDeath: json.boolean('revealRoleOnDeath'),
      seerSeesRole: json.boolean('seerSeesRole'),
    ),
    confirmed: {
      for (final p in json.strings('confirmed', max: maxPlayers))
        if (_id.hasMatch(p)) PlayerId(p) else throw const ProtocolError('id'),
    },
    nightChoices: {
      for (final c in json.objects('nightChoices', max: maxPlayers))
        _pid(c, 'player'): _pid(c, 'target'),
    },
    votes: {
      for (final v in json.objects('votes', max: maxPlayers))
        _pid(v, 'player'): v.maybeString('target') == null
            ? null
            : _pid(v, 'target'),
    },
    seerResults: seer,
    deaths: [
      for (final d in json.objects('deaths', max: maxPlayers))
        Death(
          player: _pid(d, 'player'),
          round: d.integer('round', max: 1000),
          cause: d.enumValue('cause', DeathCause.values),
        ),
    ],
    sheep: _readPairs(json, 'sheep'),
    lastNightSheep: _readPairs(json, 'lastNightSheep'),
    dreams: _readPairs(json, 'dreams'),
    seed: json.integer('seed', max: 0xffffffff),
    winner: json.maybeEnum('winner', Faction.values),
  );
}
