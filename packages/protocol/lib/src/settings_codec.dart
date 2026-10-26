import 'package:game_core/game_core.dart';
import 'package:protocol/src/reader.dart';

/// Longest phase time a message may carry, in seconds (the rules allow
/// less; see [GameSettings.validate]).
const _maxSeconds = 3600;

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
  'personas': settings.personaChoice,
  'voice': settings.narratorVoice,
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
    personaChoice: json.boolean('personas'),
    narratorVoice: json.boolean('voice'),
  );
}
