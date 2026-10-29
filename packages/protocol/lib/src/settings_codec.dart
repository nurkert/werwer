import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';

/// Longest phase time a message may carry, in seconds (the rules allow
/// less; see [GameSettings.validate]).
const _maxSeconds = 3600;

final _seatId = RegExp(r'^[a-z0-9]{1,16}$');

/// Encodes [GameSettings] as JSON (times in whole seconds).
Map<String, Object?> encodeSettings(GameSettings settings) => {
  'roles': [
    for (final role in specialRoles)
      if (settings.roles.contains(role)) role.name,
  ],
  'werewolves': ?settings.werewolves,
  'night': settings.nightTime.inSeconds,
  'day': settings.dayTime.inSeconds,
  'vote': settings.voteTime.inSeconds,
  'reveal': settings.revealRoleOnDeath,
  'seerRole': settings.seerSeesRole,
  'sheep': settings.sheepCounting,
  'trail': settings.wolfTrail,
  'atmosphere': settings.atmosphere,
  'narrator': settings.narratorMode.name,
  'stage': settings.narratorStage.name,
  'sound': settings.soundMode.name,
  'soundSeats': [for (final seat in settings.soundSeats) seat.value],
  'doorSigns': settings.doorSigns,
  'nights': settings.nightMode.name,
  'voiceLang': settings.narratorLanguage.name,
  'ghosts': settings.ghosts.name,
  'ties': settings.tieRule.name,
  'openVotes': settings.openVotes,
  'mayor': settings.mayor,
  'lateJoin': settings.lateJoin.name,
};

/// Decodes [GameSettings]; throws a [ProtocolError] for invalid input. Only
/// types and sizes are checked here; the rules check the bounds.
GameSettings decodeSettings(JsonReader json) {
  final roles = <Role>{};
  for (final name in json.strings('roles', max: specialRoles.length)) {
    final role = specialRoles.where((r) => r.name == name).firstOrNull;
    if (role == null || !roles.add(role)) {
      throw const ProtocolError('bad role');
    }
  }
  Duration seconds(String key) =>
      Duration(seconds: json.integer(key, max: _maxSeconds));
  return GameSettings(
    roles: roles,
    werewolves: json.maybeInteger('werewolves', max: maxPlayers),
    nightTime: seconds('night'),
    dayTime: seconds('day'),
    voteTime: seconds('vote'),
    revealRoleOnDeath: json.boolean('reveal'),
    seerSeesRole: json.boolean('seerRole'),
    sheepCounting: json.boolean('sheep'),
    wolfTrail: json.boolean('trail'),
    atmosphere: json.boolean('atmosphere'),
    // A game saved before the narrator modes had a switch.
    narratorMode:
        json.maybeEnum('narrator', NarratorMode.values) ??
        (json.maybeBoolean('voice') ?? false
            ? NarratorMode.always
            : NarratorMode.off),
    soundMode: json.maybeEnum('sound', SoundMode.values) ?? SoundMode.everyone,
    soundSeats: {
      if (json.has('soundSeats'))
        for (final id in json.strings(
          'soundSeats',
          max: maxPlayers,
          maxLength: 16,
        ))
          if (_seatId.hasMatch(id))
            PlayerId(id)
          else
            throw const ProtocolError('bad seat'),
    },
    doorSigns: json.boolean('doorSigns'),
    nightMode: json.enumValue('nights', NightMode.values),
    narratorLanguage: json.enumValue('voiceLang', NarratorLanguage.values),
    // A game saved before the stage had a switch walks as it did.
    narratorStage:
        json.maybeEnum('stage', NarratorStage.values) ?? NarratorStage.lively,
    // Missing in a game saved before ghosts and runoffs: the defaults.
    ghosts:
        json.maybeEnum('ghosts', GhostSight.values) ??
        const GameSettings().ghosts,
    tieRule:
        json.maybeEnum('ties', TieRule.values) ?? const GameSettings().tieRule,
    openVotes: json.maybeBoolean('openVotes') ?? false,
    mayor: json.maybeBoolean('mayor') ?? false,
    lateJoin: json.maybeEnum('lateJoin', LateJoin.values) ?? LateJoin.ghost,
  );
}
