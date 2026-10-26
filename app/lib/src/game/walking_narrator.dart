import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narration_script.dart';
import 'package:whowolf/src/game/narrator_walk.dart';

/// One recorded variant of a moment.
typedef Clip = ({String file, int ms});

/// The narrator's recordings in this build (`tool/voice/encode.py` writes
/// them with a manifest); empty where there are none, and then the screen
/// and the system voice tell the story as before.
class VoiceBank {
  const VoiceBank(this._clips);

  /// The bank of this build, or an empty one.
  static Future<VoiceBank> load() async {
    try {
      final raw = await rootBundle.loadString('assets/voice/manifest.json');
      final json = jsonDecode(raw) as Map<String, Object?>;
      Clip clip(Object? v) {
        final m = v! as Map<String, Object?>;
        return (file: m['file']! as String, ms: m['ms']! as int);
      }

      return VoiceBank({
        for (final MapEntry(key: lang, :value) in json.entries)
          lang: {
            for (final MapEntry(:key, value: variants)
                in (value! as Map<String, Object?>).entries)
              key: [for (final v in variants! as List<Object?>) clip(v)],
          },
      });
    } on Object {
      return const VoiceBank({});
    }
  }

  final Map<String, Map<String, List<Clip>>> _clips;

  /// The variants of [key] in [language], or none.
  List<Clip> variants(NarratorLanguage language, String key) =>
      _clips[language.name]?[key] ?? const [];

  /// Whether there are recordings in [language] at all.
  bool speaks(NarratorLanguage language) =>
      _clips[language.name]?.isNotEmpty ?? false;
}

/// Plays one clip; the app uses audioplayers, tests a fake.
abstract interface class ClipPlayer {
  /// Loads [asset] so that [start] begins at once.
  Future<void> prepare(String asset, double volume);
  void start();
  void volume(double volume);
  void stop();
}

class _AudioClipPlayer implements ClipPlayer {
  final _player = AudioPlayer();

  @override
  Future<void> prepare(String asset, double volume) async {
    await _player.setVolume(volume);
    await _player.setSource(AssetSource(asset));
  }

  @override
  void start() => unawaited(_player.resume().catchError((Object _) {}));

  @override
  void volume(double volume) =>
      unawaited(_player.setVolume(volume).catchError((Object _) {}));

  @override
  void stop() => unawaited(
    _player.stop().then((_) => _player.dispose()).catchError((Object _) {}),
  );
}

/// The narrator walking around the table: every phone plays its part of
/// the same walk at the same time (the clocks are in step with the host's),
/// louder while the voice is at its seat, quiet otherwise.
class WalkingNarrator {
  WalkingNarrator({
    required this.bank,
    required this.room,
    ClipPlayer Function()? player,
    int Function()? clock,
    void Function() Function(Duration, void Function())? startTimer,
  }) : _player = player ?? _AudioClipPlayer.new,
       _clock = clock ?? _now,
       _startTimer = startTimer ?? _timer;

  static int _now() => DateTime.now().millisecondsSinceEpoch;

  static void Function() _timer(Duration after, void Function() callback) =>
      Timer(after, callback).cancel;

  final VoiceBank bank;
  final String room;
  final ClipPlayer Function() _player;
  final int Function() _clock;
  final void Function() Function(Duration, void Function()) _startTimer;
  final _cancels = <void Function()>[];
  final _playing = <ClipPlayer>{};

  /// A pause between two moments.
  static const gap = 450;

  /// How often the volume follows the walk.
  static const _step = Duration(milliseconds: 40);

  /// Whether this phone stays silent.
  bool muted = false;

  /// Says [moments], starting at [startMs] (this device's clock), as heard
  /// from [me]'s seat at a table of [seats] in their order (the same list
  /// on every phone). Stops whatever was still being said.
  void speak({
    required List<Spoken> moments,
    required NarratorLanguage language,
    required int round,
    required int startMs,
    required List<PlayerId> seats,
    required PlayerId me,
  }) {
    stop();
    final mine = seats.indexOf(me);
    if (muted || mine < 0 || seats.isEmpty) return;
    var at = startMs;
    double? position;
    final said = <String, int>{};
    for (final moment in moments) {
      final variants = bank.variants(language, moment.key);
      if (variants.isEmpty) continue;
      final occurrence = said[moment.key] = (said[moment.key] ?? -1) + 1;
      final clip =
          variants[pickVariant(
            room: room,
            round: round,
            key: moment.key,
            count: variants.length,
            occurrence: occurrence,
          )];
      final target = moment.to == null ? -1 : seats.indexOf(moment.to!);
      final walk = position == null
          ? NarratorWalk.forMoment(
              seats: seats.length,
              room: room,
              round: round,
              line: moment.key,
              to: target < 0 ? null : target,
            )
          : NarratorWalk(
              seats: seats.length,
              start: position.round() % seats.length,
              to: target < 0 ? null : target,
            );
      if (walk.activeFor(mine, clip.ms).isNotEmpty) {
        _schedule(clip, walk, mine, at);
      }
      position = walk.positionAt(clip.ms);
      at += clip.ms + gap;
    }
  }

  void _schedule(Clip clip, NarratorWalk walk, int seat, int startMs) {
    final player = _player();
    var prepared = false;
    _playing.add(player);
    unawaited(
      player
          .prepare('voice/${clip.file}', walk.gainAt(seat, 0))
          .then((_) => prepared = true)
          .catchError((Object _) => false),
    );
    void Function()? follow;
    final wait = startMs - _clock();
    _cancels
      ..add(
        _startTimer(Duration(milliseconds: wait < 0 ? 0 : wait), () {
          if (!prepared) {
            // Not loaded in time: better silent than late and out of step.
            _playing.remove(player);
            player.stop();
            return;
          }
          player.start();
          void tick() {
            final ms = _clock() - startMs;
            if (ms > clip.ms) {
              _playing.remove(player);
              player.stop();
              return;
            }
            player.volume(walk.gainAt(seat, ms));
            follow = _startTimer(_step, tick);
          }

          tick();
        }),
      )
      ..add(() => follow?.call());
  }

  /// Stops the voice at once.
  void stop() {
    for (final cancel in _cancels) {
      cancel();
    }
    _cancels.clear();
    for (final player in _playing) {
      player.stop();
    }
    _playing.clear();
  }
}
