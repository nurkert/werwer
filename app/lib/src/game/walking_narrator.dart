import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narration_script.dart';
import 'package:whowolf/src/game/narrator_walk.dart';

/// One recorded variant of a moment, and the facts it needs to be true
/// (see `storyFacts`); none for a line that always fits.
typedef Clip = ({String file, int ms, Set<String> only});

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
        return (
          file: m['file']! as String,
          ms: m['ms']! as int,
          only: {
            for (final f in (m['if'] as List<Object?>?) ?? []) f! as String,
          },
        );
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

  /// The variants of [key] in [language] that fit [facts], or none.
  List<Clip> variants(
    NarratorLanguage language,
    String key, {
    Set<String>? facts,
  }) => [
    for (final clip in _clips[language.name]?[key] ?? const <Clip>[])
      if (facts == null || facts.containsAll(clip.only)) clip,
  ];

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

/// One moment as the narrator will say it: which recording, when (this
/// device's clock) and how the voice walks meanwhile.
typedef Planned = ({String key, Clip clip, int at, NarratorWalk walk});

/// The narrator walking around the table: every phone that plays sound
/// plays its part of the same walk at the same time (the clocks are in
/// step with the host's), louder while the voice is at its seat, quiet
/// otherwise.
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

  /// The pause between two moments, as one speaker would leave it: short
  /// within one thought (who died, then what they were), longer when the
  /// story moves on, and time to close and open eyes between two roles.
  static int gap(String before, String after) {
    if (before == 'intro') return 1400;
    if (before == 'sleep') return 1600;
    if (after.startsWith('role_') || after == 'grief') return 650;
    return 900;
  }

  /// A clip that should have begun this long ago stays silent: joining
  /// in mid-sentence would be out of step.
  static const _late = 250;

  /// How often the volume follows the walk.
  static const _step = Duration(milliseconds: 40);

  /// Whether this phone stays silent.
  bool muted = false;

  /// Says [moments], starting at [startMs] (this device's clock), on the
  /// [speakers] (the phones that play sound, in seat order: the same list
  /// on every phone); this phone plays its part if [me] is one of them.
  /// Nothing runs past [deadlineMs] (the end of the phase). Stops whatever
  /// was still being said. Returns the plan, also when this phone is
  /// silent, so the screen can follow it.
  List<Planned> speak({
    required List<Spoken> moments,
    required NarratorLanguage language,
    required int round,
    required int startMs,
    required List<PlayerId> speakers,
    required PlayerId me,
    int? deadlineMs,
    Set<String> facts = const {},
  }) {
    stop();
    final planned = plan(
      moments: moments,
      language: language,
      round: round,
      startMs: startMs,
      speakers: speakers,
      deadlineMs: deadlineMs,
      facts: facts,
    );
    final mine = speakers.indexOf(me);
    if (muted || mine < 0) return planned;
    for (final p in planned) {
      if (p.walk.activeFor(mine, p.clip.ms).isNotEmpty) {
        _schedule(p.clip, p.walk, mine, p.at);
      }
    }
    return planned;
  }

  /// When each of [moments] is said and how the voice walks over the
  /// [speakers]: the same on every phone. A moment that would not end by
  /// [deadlineMs] is left out, and so is everything after it.
  List<Planned> plan({
    required List<Spoken> moments,
    required NarratorLanguage language,
    required int round,
    required int startMs,
    required List<PlayerId> speakers,
    int? deadlineMs,
    Set<String> facts = const {},
  }) {
    final planned = <Planned>[];
    if (speakers.isEmpty) return planned;
    var at = startMs;
    int? position;
    final said = <String, int>{};
    for (final moment in moments) {
      final variants = bank.variants(language, moment.key, facts: facts);
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
      final begins = planned.isEmpty
          ? at
          : at + gap(planned.last.key, moment.key);
      if (deadlineMs != null && begins + clip.ms > deadlineMs) break;
      final target = moment.to == null ? -1 : speakers.indexOf(moment.to!);
      final walk = NarratorWalk.plan(
        seats: speakers.length,
        room: room,
        round: round,
        line: moment.key,
        lengthMs: clip.ms,
        occurrence: occurrence,
        start: position,
        to: target < 0 ? null : target,
      );
      planned.add((key: moment.key, clip: clip, at: begins, walk: walk));
      position = walk.end;
      at = begins + clip.ms;
    }
    return planned;
  }

  void _schedule(Clip clip, NarratorWalk walk, int seat, int startMs) {
    if (startMs < _clock() - _late) return;
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
