import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/widgets.dart';
import 'package:game_core/game_core.dart';

/// Every sound of the game: wordless, CC0 (see assets/sounds/CREDITS.md).
enum Sound {
  wind('sounds/wind.mp3', 0.5),
  crickets('sounds/crickets.mp3', 0.35),
  owl('sounds/owl.mp3', 0.45),
  yawn('sounds/yawn.mp3', 0.8),
  tap('sounds/tap.mp3', 0.6),
  confirm('sounds/confirm.mp3', 0.5),
  refused('sounds/refused.mp3', 0.5),
  join('sounds/join.mp3', 0.8),
  start('sounds/start.mp3', 0.7),
  turn('sounds/turn.mp3', 0.8),
  night('sounds/night.mp3', 0.6),
  wake('sounds/wake.mp3', 0.6),
  death('sounds/death.mp3', 0.8),
  vote('sounds/vote.mp3', 0.6),
  ballot('sounds/ballot.mp3', 0.9),
  tick('sounds/tick.mp3', 0.5),
  howl('sounds/howl.mp3', 0.8),
  cheer('sounds/cheer.mp3', 0.7),
  bowstring('sounds/bowstring.mp3', 0.8);

  const Sound(this.asset, this.volume);

  final String asset;
  final double volume;
}

/// One sound at a moment of the night, counted from nightfall.
typedef Cue = ({Sound sound, Duration at});

/// The sounds of night [round] in room [room]: wind at nightfall and now
/// and then, crickets, an owl or two.
///
/// A pure function of public values, so every phone plans the same night
/// and no sound can ever depend on a role or a night action (that would be
/// a tell).
List<Cue> nightCues(String room, int round, {Duration length = _night}) {
  final random = Random(stableHash('$room/$round'));
  final seconds = length.inSeconds;
  Duration at(double from, double to) => Duration(
    milliseconds: ((from + random.nextDouble() * (to - from)) * 1000).round(),
  );
  final cues = <Cue>[
    (sound: Sound.wind, at: Duration.zero),
    for (
      var s = 25 + random.nextInt(15);
      s < seconds - 10;
      s += 30 + random.nextInt(20)
    )
      (sound: Sound.wind, at: Duration(seconds: s)),
    for (var i = 0; i < 2 + random.nextInt(2); i++)
      (sound: Sound.crickets, at: at(4, seconds - 6)),
    for (var i = 0; i < 1 + random.nextInt(2); i++)
      (sound: Sound.owl, at: at(10, seconds - 5)),
  ]..sort((a, b) => a.at.compareTo(b.at));
  return cues;
}

const _night = Duration(seconds: 90);

/// Plays sounds; the app uses [AudioSounds], tests a silent fake.
abstract interface class Sounds {
  void play(Sound sound);
  void stopAll();
}

/// Plays through the platform's audio (`audioplayers`). Platforms without
/// audio simply stay silent.
class AudioSounds implements Sounds {
  final _playing = <AudioPlayer>{};

  @override
  void play(Sound sound) {
    final player = AudioPlayer();
    _playing.add(player);
    unawaited(
      player
          .play(AssetSource(sound.asset), volume: sound.volume)
          .then((_) => player.onPlayerComplete.first)
          .catchError((Object _) {})
          .whenComplete(() {
            _playing.remove(player);
            unawaited(player.dispose().catchError((Object _) {}));
          }),
    );
  }

  @override
  void stopAll() {
    for (final player in [..._playing]) {
      unawaited(player.stop().catchError((Object _) {}));
    }
  }
}

/// Follows the game and plays it: [update] with every new view.
///
/// The moments everyone shares (someone sits down, the game starts, night
/// falls, morning comes, someone dies, the vote, the end) sound on every
/// phone at once. The night's atmosphere and the morning yawn only play if
/// the table switched atmosphere on. Nothing plays on a [muted] phone, and
/// nothing here ever depends on a role or a night action.
class Atmosphere {
  Atmosphere({
    required this.room,
    Sounds? sounds,
    void Function() Function(Duration, void Function())? startTimer,
    int Function()? clock,
  }) : _sounds = sounds ?? AudioSounds(),
       _startTimer = startTimer ?? _realTimer,
       _clock = clock ?? _now;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  final String room;
  final Sounds _sounds;
  final void Function() Function(Duration, void Function()) _startTimer;
  final int Function() _clock;

  /// When the current phase began on this device's clock, translated from
  /// the host's (see `PlayerLink.phaseStartedAtMs`); `null` until known.
  int? _phaseStart;
  final _cancels = <void Function()>[];
  PlayerView? _last;
  bool _muted = false;

  bool get muted => _muted;
  set muted(bool value) {
    _muted = value;
    if (value) _stop();
  }

  /// Follows the game to [view]. With [phaseStartedAt] (this device's
  /// time the phase began, from the synced clock) the shared moments sound
  /// at the same instant on every phone, not just whenever each phone
  /// heard of the new phase.
  void update(PlayerView view, {int? phaseStartedAt}) {
    final before = _last;
    _last = view;
    _phaseStart = phaseStartedAt;
    final on = view.settings.atmosphere && !_muted;
    final night = view.phase == Phase.night;
    final wasNight = before?.phase == Phase.night;
    if (night && (!wasNight || before?.round != view.round)) {
      _stop();
      // Night falls: the gong, and everyone goes to sleep with a yawn.
      _moment(Duration.zero, Sound.night);
      _moment(const Duration(milliseconds: 2000), Sound.yawn);
      if (on) _planNight(view, after: const Duration(seconds: 3));
    } else if (!night && wasNight) {
      _stop();
      if (view.phase == Phase.day) {
        _moment(Duration.zero, Sound.wake);
        // Everyone yawns as the sun comes up, all at once: a phone that
        // stays silent stands out.
        if (on) _shared(const Duration(milliseconds: 2600), Sound.yawn);
      }
    }
    if (before == null || _muted) return;
    final phase = view.phase;
    final changed = before.phase != phase;
    if (phase == Phase.lobby && view.seats.length > before.seats.length) {
      _sounds.play(Sound.join);
    }
    if (changed && phase == Phase.roleReveal) _sounds.play(Sound.start);
    if (changed && phase == Phase.vote) _sounds.play(Sound.vote);
    if (changed && before.phase == Phase.hunterShot) {
      _sounds.play(Sound.bowstring);
    }
    final died = _alive(before) > _alive(view);
    if (died) {
      _moment(
        Duration(milliseconds: phase == Phase.day ? 2600 : 400),
        Sound.death,
      );
    }
    if (changed && phase == Phase.ended) {
      _moment(
        Duration(milliseconds: died ? 2200 : 300),
        view.winner == Faction.werewolves ? Sound.howl : Sound.cheer,
      );
    }
  }

  static int _alive(PlayerView view) =>
      view.seats.where((s) => s.isAlive).length;

  /// A shared moment: on every phone that is not muted, whatever the
  /// atmosphere setting, [at] after the phase began.
  void _moment(Duration at, Sound sound) {
    if (!_muted) _shared(at, sound);
  }

  /// Plays [sound] [at] after the phase began, by the synced clock if
  /// known (so in unison with the others), else from now. A moment missed
  /// by more than a second is skipped rather than played late.
  void _shared(Duration at, Sound sound) {
    final start = _phaseStart;
    if (start == null) return _later(at, sound);
    final wait = start + at.inMilliseconds - _clock();
    if (wait < -1000) return;
    _later(Duration(milliseconds: wait < 0 ? 0 : wait), sound);
  }

  /// A sound only this player hears, for their own taps (never at night:
  /// taps there must sound like nothing, whatever the role).
  void own(Sound sound) {
    if (_muted || _last?.phase == Phase.night) return;
    _sounds.play(sound);
  }

  void _planNight(PlayerView view, {Duration after = Duration.zero}) {
    for (final cue in nightCues(
      room,
      view.round,
      length: view.settings.nightTime,
    )) {
      _later(cue.at + after, cue.sound);
    }
  }

  void _later(Duration at, Sound sound) =>
      _cancels.add(_startTimer(at, () => _sounds.play(sound)));

  void _stop() {
    for (final cancel in _cancels) {
      cancel();
    }
    _cancels.clear();
    _sounds.stopAll();
  }

  void dispose() => _stop();
}

void Function() _realTimer(Duration after, void Function() callback) =>
    Timer(after, callback).cancel;

/// Gives the widgets below a way to play this player's own sounds (button
/// taps, turning the figure, casting a vote), see [Atmosphere.own].
class SoundScope extends InheritedWidget {
  const SoundScope({required this.atmosphere, required super.child, super.key});

  final Atmosphere atmosphere;

  /// Plays [sound] for this player, if a game screen is above.
  static void play(BuildContext context, Sound sound) => context
      .getInheritedWidgetOfExactType<SoundScope>()
      ?.atmosphere
      .own(sound);

  @override
  bool updateShouldNotify(SoundScope old) => old.atmosphere != atmosphere;
}
