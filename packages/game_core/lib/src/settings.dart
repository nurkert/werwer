import 'package:game_core/src/role.dart';
import 'package:game_core/src/violation.dart';
import 'package:meta/meta.dart';

/// Shortest and longest allowed night (the werewolves' step).
const ({Duration min, Duration max}) nightTimeRange = (
  min: Duration(seconds: 30),
  max: Duration(minutes: 5),
);

/// Shortest and longest allowed discussion.
const ({Duration min, Duration max}) dayTimeRange = (
  min: Duration(minutes: 1),
  max: Duration(minutes: 30),
);

/// Shortest and longest allowed vote.
const ({Duration min, Duration max}) voteTimeRange = (
  min: Duration(seconds: 30),
  max: Duration(minutes: 5),
);

/// How a night runs.
enum NightMode {
  /// Whowolf's night: everyone taps at the same time (whoever has nothing
  /// to do gets a cover task), so phones can stay in hands and give
  /// nothing away.
  together,

  /// The night everyone knows: all close their eyes and the narrator calls
  /// the roles one after another (cupid in the first night, the
  /// werewolves, the seer, the witch); only whoever is called opens their
  /// eyes and picks up their phone.
  called,
}

/// Options the host picks in the lobby; everyone at the table sees them.
///
/// Everything Whowolf adds to the classic card game is optional, so a table
/// can start plain and add more step by step ([Preset]). In Whowolf's night
/// everyone taps something (sheep or at least a neutral pick), or the
/// tapping would tell the roles; in the called night ([NightMode.called])
/// everyone's eyes are closed instead.
@immutable
class GameSettings {
  /// Creates settings. The defaults are the base game: werewolves, a seer
  /// and villagers, with sheep counting.
  const GameSettings({
    this.roles = const {Role.seer},
    this.werewolves,
    this.nightTime = const Duration(seconds: 90),
    this.dayTime = const Duration(minutes: 8),
    this.voteTime = const Duration(minutes: 2),
    this.revealRoleOnDeath = true,
    this.seerSeesRole = true,
    this.sheepCounting = true,
    this.wolfTrail = false,
    this.atmosphere = false,
    this.personaChoice = true,
    this.narratorVoice = false,
    this.doorSigns = false,
    this.nightMode = NightMode.together,
  });

  /// The special roles in play (a subset of [specialRoles]), each dealt
  /// once. Werewolves and villagers are always in play.
  final Set<Role> roles;

  /// How many werewolves; `null` deals [suggestedWerewolves] for the
  /// number of players at the start.
  final int? werewolves;

  /// How long the werewolves' step of a night may take.
  final Duration nightTime;

  /// How long the discussion may take before the vote starts.
  final Duration dayTime;

  /// How long the vote may take.
  final Duration voteTime;

  /// Whether a dead player's role is shown to everyone.
  final bool revealRoleOnDeath;

  /// Whether the seer learns the exact role (otherwise only the faction).
  final bool seerSeesRole;

  /// Whether the night's cover game is counting sheep, with the count told
  /// in the morning. Off, everyone still makes a neutral pick at night.
  final bool sheepCounting;

  /// Whether the light wolf trail plays (see NIGHT_SOUNDS.md).
  final bool wolfTrail;

  /// Whether the night soundscape and the morning yawn play.
  final bool atmosphere;

  /// Whether players pick their persona in the lobby (otherwise they keep
  /// the one they got).
  final bool personaChoice;

  /// Whether the narrator speaks aloud (otherwise text only). Off unless
  /// the host turns it on: the system voices are no pleasure to hear yet;
  /// recorded lines come later.
  final bool narratorVoice;

  /// Whether door signs are in play: every night each living player gets a
  /// secret sign on their door, and the werewolves may once per night guess
  /// a player's sign; a right guess may take that player too. So everyone,
  /// not only the werewolves, has a reason to hide their screen at night.
  final bool doorSigns;

  /// How the night runs.
  final NightMode nightMode;

  /// Whether sheep are counted: they need the phones in hand at night, so
  /// not when the narrator calls the roles.
  bool get sheepInPlay => sheepCounting && nightMode == NightMode.together;

  /// Whether door signs are in play (Whowolf's night only, like the sheep).
  bool get doorSignsInPlay => doorSigns && nightMode == NightMode.together;

  /// The preset these settings are exactly, if any.
  Preset? get preset =>
      Preset.values.where((p) => p.settings == this).firstOrNull;

  /// Throws a [RuleViolation] unless every value is within its bounds.
  void validate() {
    final wolves = werewolves;
    if (!specialRoles.containsAll(roles) ||
        (wolves != null && (wolves < 1 || wolves > maxWerewolves))) {
      throw const RuleViolation(Violation.invalidRoles);
    }
    bool within(Duration d, ({Duration min, Duration max}) range) =>
        d >= range.min && d <= range.max;
    if (!within(nightTime, nightTimeRange) ||
        !within(dayTime, dayTimeRange) ||
        !within(voteTime, voteTimeRange)) {
      throw const RuleViolation(Violation.outOfRange);
    }
  }

  /// The roles to deal to [playerCount] players: the werewolves, each
  /// special role once and villagers for the rest. `null` if they do not
  /// fit (too many special roles, or the werewolves would not be fewer than
  /// the others).
  List<Role>? rolesFor(int playerCount) {
    final wolves = werewolves ?? suggestedWerewolves(playerCount);
    final villagers = playerCount - wolves - roles.length;
    if (wolves < 1 || wolves >= playerCount - wolves || villagers < 0) {
      return null;
    }
    return [
      for (var i = 0; i < wolves; i++) Role.werewolf,
      for (final role in specialRoles)
        if (roles.contains(role)) role,
      for (var i = 0; i < villagers; i++) Role.villager,
    ];
  }

  /// Returns a copy with the given fields replaced. Pass
  /// `suggestWerewolves: true` to go back to the suggested number.
  GameSettings copyWith({
    Set<Role>? roles,
    int? werewolves,
    bool suggestWerewolves = false,
    Duration? nightTime,
    Duration? dayTime,
    Duration? voteTime,
    bool? revealRoleOnDeath,
    bool? seerSeesRole,
    bool? sheepCounting,
    bool? wolfTrail,
    bool? atmosphere,
    bool? personaChoice,
    bool? narratorVoice,
    bool? doorSigns,
    NightMode? nightMode,
  }) => GameSettings(
    roles: roles ?? this.roles,
    werewolves: suggestWerewolves ? null : werewolves ?? this.werewolves,
    nightTime: nightTime ?? this.nightTime,
    dayTime: dayTime ?? this.dayTime,
    voteTime: voteTime ?? this.voteTime,
    revealRoleOnDeath: revealRoleOnDeath ?? this.revealRoleOnDeath,
    seerSeesRole: seerSeesRole ?? this.seerSeesRole,
    sheepCounting: sheepCounting ?? this.sheepCounting,
    wolfTrail: wolfTrail ?? this.wolfTrail,
    atmosphere: atmosphere ?? this.atmosphere,
    personaChoice: personaChoice ?? this.personaChoice,
    narratorVoice: narratorVoice ?? this.narratorVoice,
    doorSigns: doorSigns ?? this.doorSigns,
    nightMode: nightMode ?? this.nightMode,
  );

  @override
  bool operator ==(Object other) =>
      other is GameSettings &&
      other.roles.length == roles.length &&
      other.roles.containsAll(roles) &&
      other.werewolves == werewolves &&
      other.nightTime == nightTime &&
      other.dayTime == dayTime &&
      other.voteTime == voteTime &&
      other.revealRoleOnDeath == revealRoleOnDeath &&
      other.seerSeesRole == seerSeesRole &&
      other.sheepCounting == sheepCounting &&
      other.wolfTrail == wolfTrail &&
      other.atmosphere == atmosphere &&
      other.personaChoice == personaChoice &&
      other.narratorVoice == narratorVoice &&
      other.doorSigns == doorSigns &&
      other.nightMode == nightMode;

  @override
  int get hashCode => Object.hash(
    Object.hashAllUnordered(roles),
    werewolves,
    nightTime,
    dayTime,
    voteTime,
    revealRoleOnDeath,
    seerSeesRole,
    sheepCounting,
    wolfTrail,
    atmosphere,
    personaChoice,
    narratorVoice,
    doorSigns,
    nightMode,
  );
}

/// Starting points the host picks with one tap and may then change in
/// detail.
enum Preset {
  /// Like the card game: everyone closes their eyes and the narrator
  /// calls the roles one by one; the app narrates aloud and counts the
  /// votes. No sheep score, no wolf trail, no atmosphere, fixed personas.
  classic(
    GameSettings(
      roles: {Role.seer, Role.witch, Role.hunter},
      sheepCounting: false,
      personaChoice: false,
      narratorVoice: true,
      nightMode: NightMode.called,
    ),
  ),

  /// Classic plus Whowolf's own touches: sheep counting with the morning
  /// score, door signs, atmosphere and the morning yawn, persona choice.
  whowolf(
    GameSettings(
      roles: {Role.seer, Role.witch, Role.hunter},
      atmosphere: true,
      doorSigns: true,
    ),
  ),

  /// Everything there is: all roles and the wolf trail.
  fullStage(
    GameSettings(
      roles: {Role.seer, Role.witch, Role.hunter, Role.cupid},
      atmosphere: true,
      wolfTrail: true,
      doorSigns: true,
    ),
  );

  const Preset(this.settings);

  /// The settings this preset stands for.
  final GameSettings settings;
}
