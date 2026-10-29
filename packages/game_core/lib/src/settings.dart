import 'package:game_core/src/model.dart' show PlayerId;
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

/// What the dead see of the game.
enum GhostSight {
  /// No more than the living.
  off,

  /// Every role and the lovers.
  roles,

  /// Also, as it happens, what the night brings (the pack's pick, the
  /// seer's look, the witch's potions, the pack's door sign attempt) and
  /// who votes for whom: like keeping your eyes open at the card table.
  everything,
}

/// How a tied vote ends.
enum TieRule {
  /// Nobody is eliminated; night falls.
  nobody,

  /// A second vote among the tied only; another tie eliminates nobody.
  runoff,
}

/// The language the narrator speaks at the table: one for everyone, so the
/// voice does not change language as it walks from phone to phone.
enum NarratorLanguage {
  /// German.
  de,

  /// English.
  en,
}

/// How much the narrator says aloud (the screens always show the text).
enum NarratorMode {
  /// Text only.
  off,

  /// Only what a table with closed eyes needs: nightfall and falling
  /// asleep, every call of the called night, and the village waking up.
  essential,

  /// The moments that carry the story: the intro, nightfall (and in the
  /// called night falling asleep and every call), the news in the morning,
  /// the vote and its result, the hunter and the end.
  moments,

  /// Every line of the script.
  always,
}

/// How much the narrator walks around the table ("Bühne").
enum NarratorStage {
  /// Hardly at all: the voice stays at one phone per line.
  calm,

  /// Now and then, in the pauses between words, with footsteps by day.
  lively,

  /// Like a play: more often, and from line to line across the table.
  theater,
}

/// How someone who joins a running game comes in (only by day, and only
/// when the game leader lets them in).
enum LateJoin {
  /// As a ghost: dead from the start, no role of their own to play, sees
  /// what the dead see ([GameSettings.ghosts]). Changes nothing about who
  /// can win.
  ghost,

  /// As a living villager: votes from the next vote on. Everyone knows the
  /// newcomer is a villager (the setting is public), so they are a
  /// confirmed innocent.
  villager,
}

/// Which phones play the narrator and the shared sounds.
enum SoundMode {
  /// Every phone at the table.
  everyone,

  /// Only the seats in [GameSettings.soundSeats] (the game leader's phone,
  /// a group, or one player with a speaker).
  chosen,
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
    this.narratorMode = NarratorMode.moments,
    this.narratorStage = NarratorStage.lively,
    this.soundMode = SoundMode.everyone,
    this.soundSeats = const {},
    this.doorSigns = false,
    this.nightMode = NightMode.together,
    this.narratorLanguage = NarratorLanguage.de,
    this.ghosts = GhostSight.everything,
    this.tieRule = TieRule.runoff,
    this.openVotes = false,
    this.mayor = false,
    this.lateJoin = LateJoin.ghost,
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

  /// How much the narrator says aloud.
  final NarratorMode narratorMode;

  /// How much the narrator walks around the table.
  final NarratorStage narratorStage;

  /// Whether the narrator speaks aloud at all.
  bool get narratorVoice => narratorMode != NarratorMode.off;

  /// Which phones play sound.
  final SoundMode soundMode;

  /// The seats that play sound with [SoundMode.chosen] (at most
  /// [maxPlayers]). Not a rule: seats that left simply do not count.
  final Set<PlayerId> soundSeats;

  /// Whether door signs are in play: every night each living player gets a
  /// secret sign on their door, and the werewolves may once per night guess
  /// a player's sign; a right guess may take that player too. So everyone,
  /// not only the werewolves, has a reason to hide their screen at night.
  final bool doorSigns;

  /// How the night runs.
  final NightMode nightMode;

  /// The language of the narrator's voice (the host's app language).
  final NarratorLanguage narratorLanguage;

  /// What the dead see (only once they have nothing left to do).
  final GhostSight ghosts;

  /// How a tied vote ends.
  final TieRule tieRule;

  /// Whether everyone sees who votes for whom, as it happens (like raising
  /// hands), and the day after how the last vote went.
  final bool openVotes;

  /// Whether the village elects a mayor, whose vote counts twice: by day,
  /// whenever there is no living mayor, the table elects one openly during
  /// the talk.
  final bool mayor;

  /// How someone who joins a running game comes in.
  final LateJoin lateJoin;

  /// Whether sheep are counted: they need the phones in hand at night, so
  /// not when the narrator calls the roles.
  bool get sheepInPlay => sheepCounting && nightMode == NightMode.together;

  /// Whether door signs are in play (Whowolf's night only, like the sheep).
  bool get doorSignsInPlay => doorSigns && nightMode == NightMode.together;

  /// The preset these settings are exactly, if any.
  /// The narrator's language and where sound plays are the table's, not
  /// part of a preset.
  Preset? get preset => Preset.values
      .where((p) => p.settings.withTableOf(this) == this)
      .firstOrNull;

  /// These settings with the table's own choices from [other]: the
  /// narrator's language, where sound plays, the phase times and how
  /// latecomers come in (a preset keeps them).
  GameSettings withTableOf(GameSettings other) => copyWith(
    narratorLanguage: other.narratorLanguage,
    lateJoin: other.lateJoin,
    soundMode: other.soundMode,
    soundSeats: other.soundSeats,
    nightTime: other.nightTime,
    dayTime: other.dayTime,
    voteTime: other.voteTime,
  );

  bool _sameTimes(GameSettings other) =>
      other.nightTime == nightTime &&
      other.dayTime == dayTime &&
      other.voteTime == voteTime;

  /// These settings for a table that went from [from] to [to] players: the
  /// phase times follow it while they are the ones that suited [from] (see
  /// [timedFor]); times the host set by hand stay.
  GameSettings retimed(int from, int to) =>
      _sameTimes(timedFor(from)) ? timedFor(to) : this;

  /// Throws a [RuleViolation] unless every value is within its bounds.
  void validate() {
    final wolves = werewolves;
    if (!specialRoles.containsAll(roles) ||
        (wolves != null && (wolves < 1 || wolves > maxWerewolves)) ||
        soundSeats.length > maxPlayers) {
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

  /// These settings with phase times that suit [playerCount] players: a
  /// small table talks less than a big one. Always within the ranges.
  GameSettings timedFor(int playerCount) {
    final n = playerCount;
    return copyWith(
      dayTime: Duration(
        minutes: n <= 5
            ? 4
            : n <= 8
            ? 6
            : n <= 12
            ? 8
            : 10,
      ),
      voteTime: Duration(seconds: n <= 6 ? 60 : (n <= 12 ? 90 : 120)),
      nightTime: Duration(seconds: n <= 8 ? 60 : 90),
    );
  }

  /// These settings as [playerCount] players can play them: a werewolf
  /// count that would not be a minority falls back to the suggested one,
  /// and special roles that do not fit are left out, the last of
  /// [specialRoles] first (cupid, hunter, witch, then the seer). The
  /// settings themselves stay as the host chose them, so the roles come
  /// back when the table grows.
  GameSettings fittedFor(int playerCount) {
    if (rolesFor(playerCount) != null) return this;
    var fitted = this;
    final wolves = werewolves;
    if (wolves != null && wolves * 2 >= playerCount) {
      fitted = fitted.copyWith(suggestWerewolves: true);
    }
    for (final role in specialRoles.toList().reversed) {
      if (fitted.rolesFor(playerCount) != null) break;
      if (fitted.roles.contains(role)) {
        fitted = fitted.copyWith(roles: {...fitted.roles}..remove(role));
      }
    }
    return fitted;
  }

  /// The special roles [fittedFor] leaves out for [playerCount] players.
  Set<Role> droppedFor(int playerCount) =>
      roles.difference(fittedFor(playerCount).roles);

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
    NarratorMode? narratorMode,
    NarratorStage? narratorStage,
    SoundMode? soundMode,
    Set<PlayerId>? soundSeats,
    bool? doorSigns,
    NightMode? nightMode,
    NarratorLanguage? narratorLanguage,
    GhostSight? ghosts,
    TieRule? tieRule,
    bool? openVotes,
    bool? mayor,
    LateJoin? lateJoin,
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
    narratorMode: narratorMode ?? this.narratorMode,
    narratorStage: narratorStage ?? this.narratorStage,
    soundMode: soundMode ?? this.soundMode,
    soundSeats: soundSeats ?? this.soundSeats,
    doorSigns: doorSigns ?? this.doorSigns,
    nightMode: nightMode ?? this.nightMode,
    narratorLanguage: narratorLanguage ?? this.narratorLanguage,
    ghosts: ghosts ?? this.ghosts,
    tieRule: tieRule ?? this.tieRule,
    openVotes: openVotes ?? this.openVotes,
    mayor: mayor ?? this.mayor,
    lateJoin: lateJoin ?? this.lateJoin,
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
      other.narratorMode == narratorMode &&
      other.narratorStage == narratorStage &&
      other.soundMode == soundMode &&
      other.soundSeats.length == soundSeats.length &&
      other.soundSeats.containsAll(soundSeats) &&
      other.doorSigns == doorSigns &&
      other.nightMode == nightMode &&
      other.narratorLanguage == narratorLanguage &&
      other.ghosts == ghosts &&
      other.tieRule == tieRule &&
      other.openVotes == openVotes &&
      other.mayor == mayor &&
      other.lateJoin == lateJoin;

  @override
  int get hashCode => Object.hashAll([
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
    narratorMode,
    narratorStage,
    soundMode,
    Object.hashAllUnordered(soundSeats),
    doorSigns,
    nightMode,
    narratorLanguage,
    ghosts,
    tieRule,
    openVotes,
    mayor,
    lateJoin,
  ]);
}

/// Starting points the host picks with one tap and may then change in
/// detail.
enum Preset {
  /// Like the card game: everyone closes their eyes and the narrator
  /// calls the roles one by one; the app narrates aloud and counts the
  /// votes. No sheep score, no wolf trail, no atmosphere.
  classic(
    GameSettings(
      roles: {Role.seer, Role.witch, Role.hunter},
      sheepCounting: false,
      nightMode: NightMode.called,
    ),
  ),

  /// Classic plus Whowolf's own touches: sheep counting with the morning
  /// score, door signs, atmosphere and the morning yawn.
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
      mayor: true,
    ),
  );

  const Preset(this.settings);

  /// The settings this preset stands for.
  final GameSettings settings;
}
