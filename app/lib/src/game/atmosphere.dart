import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:game_core/game_core.dart';

/// The night's sounds and the morning yawn.
enum Sound {
  wind('sounds/wind.mp3', 0.5),
  crickets('sounds/crickets.mp3', 0.35),
  owl('sounds/owl.mp3', 0.45),
  yawn('sounds/yawn.mp3', 0.8);

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
  var hash = 0x811c9dc5;
  for (final unit in '$room/$round'.codeUnits) {
    hash = ((hash ^ unit) * 0x01000193) & 0xffffffff;
  }
  final random = Random(hash);
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

/// Follows the game and plays the night and the morning: [update] with
/// every new view. Does nothing unless the table switched atmosphere on
/// and this phone is not [muted].
class Atmosphere {
  Atmosphere({
    required this.room,
    Sounds? sounds,
    void Function() Function(Duration, void Function())? startTimer,
    Random? random,
  }) : _sounds = sounds ?? AudioSounds(),
       _startTimer = startTimer ?? _realTimer,
       _random = random ?? Random();

  final String room;
  final Sounds _sounds;
  final void Function() Function(Duration, void Function()) _startTimer;
  final Random _random;
  final _cancels = <void Function()>[];
  PlayerView? _last;
  bool _muted = false;

  bool get muted => _muted;
  set muted(bool value) {
    _muted = value;
    if (value) _stop();
  }

  void update(PlayerView view) {
    final before = _last;
    _last = view;
    final on = view.settings.atmosphere && !_muted;
    final night = view.phase == Phase.night;
    final wasNight = before?.phase == Phase.night;
    if (night && (!wasNight || before?.round != view.round)) {
      _stop();
      if (on) _planNight(view);
    } else if (!night && wasNight) {
      _stop();
      // Everyone yawns as the sun comes up, not quite in unison.
      if (on && view.phase == Phase.day) {
        _later(Duration(milliseconds: _random.nextInt(1200)), Sound.yawn);
      }
    }
  }

  void _planNight(PlayerView view) {
    for (final cue in nightCues(
      room,
      view.round,
      length: view.settings.nightTime,
    )) {
      _later(cue.at, cue.sound);
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
