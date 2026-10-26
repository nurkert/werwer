import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';
import 'package:protocol/src/settings_codec.dart';

final _id = RegExp(r'^[a-z0-9]{0,16}$');

PlayerId _pid(JsonReader json, String key) {
  final value = json.string(key, max: 16);
  if (!_id.hasMatch(value)) throw ProtocolError('bad id "$key"');
  return PlayerId(value);
}

PlayerId? _maybePid(JsonReader json, String key) =>
    json.maybeString(key) == null ? null : _pid(json, key);

List<PlayerId> _ids(JsonReader json, String key, {int max = maxPlayers}) => [
  for (final p in json.strings(key, max: max, maxLength: 16))
    if (_id.hasMatch(p)) PlayerId(p) else throw ProtocolError('bad id "$key"'),
];

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
        'persona': s.persona.name,
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
  'settings': encodeSettings(view.settings),
  'yourRole': ?view.yourRole?.name,
  'confirmed': view.youConfirmed,
  'step': view.nightStep.name,
  'task': ?view.yourNightTask?.name,
  'nightTargets': [for (final t in view.yourNightTargets) t.value],
  'acted': view.youActed,
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
  'sheepLast': [
    for (final MapEntry(:key, :value) in view.lastNightSheep.entries)
      {'player': key.value, 'n': value},
  ],
  'dreams': [
    for (final MapEntry(:key, :value) in view.dreams.entries)
      {'player': key.value, 'n': value},
  ],
  'flock': ?view.yourFlock,
  'doorSign': ?view.yourDoorSign,
  'packMark': ?_encodeMark(view.packMark),
  'couple': [for (final p in view.couple) p.value],
  'victim': ?view.victim?.value,
  'potions': [for (final p in view.potions) p.name],
  'shooter': ?view.shooter?.value,
  'winner': ?view.winner?.name,
};

Map<String, Object?>? _encodeMark(DoorMark? mark) => mark == null
    ? null
    : {'target': mark.target.value, 'correct': mark.correct};

DoorMark? _decodeMark(JsonReader json, String key) {
  if (!json.has(key)) return null;
  final mark = json.object(key);
  return (target: _pid(mark, 'target'), correct: mark.boolean('correct'));
}

Map<PlayerId, int> _counts(JsonReader json, String key) => {
  for (final c in json.objects(key, max: maxPlayers))
    _pid(c, 'player'): c.integer('n', min: -1000000, max: 1000000),
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
        persona: s.enumValue('persona', Persona.values),
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
  settings: decodeSettings(json.object('settings')),
  yourRole: json.maybeEnum('yourRole', Role.values),
  youConfirmed: json.boolean('confirmed'),
  nightStep: json.enumValue('step', NightStep.values),
  yourNightTask: json.maybeEnum('task', NightAbility.values),
  yourNightTargets: _ids(json, 'nightTargets', max: 2),
  youActed: json.boolean('acted'),
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
  lastNightSheep: _counts(json, 'sheepLast'),
  dreams: _counts(json, 'dreams'),
  yourFlock: json.maybeInteger('flock', max: maxFlock),
  yourDoorSign: json.has('doorSign')
      ? json.integers(
          'doorSign',
          length: doorSignLength,
          max: doorSignSymbols - 1,
        )
      : null,
  packMark: _decodeMark(json, 'packMark'),
  couple: _couple(_ids(json, 'couple', max: 2)),
  victim: _maybePid(json, 'victim'),
  potions: {
    for (final p in json.strings('potions', max: Potion.values.length))
      Potion.values.where((v) => v.name == p).firstOrNull ??
          (throw const ProtocolError('bad potion')),
  },
  shooter: _maybePid(json, 'shooter'),
  winner: json.maybeEnum('winner', Faction.values),
);

List<PlayerId> _couple(List<PlayerId> ids) => ids.isEmpty || ids.length == 2
    ? ids
    : throw const ProtocolError('bad couple');
