import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/src/game/narration_script.dart';
import 'package:whowolf/src/game/narrator_walk.dart';

/// One recorded variant of a moment, the facts it needs to be true (see
/// `storyFacts`; none for a line that always fits) and the pauses between
/// its words, where the voice may change phones unheard.
typedef Clip = ({String file, int ms, Set<String> only, List<Pause> pauses});

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
          pauses: [
            for (final p in (m['pauses'] as List<Object?>?) ?? [])
              (
                start: (p! as List<Object?>)[0]! as int,
                end: (p as List<Object?>)[1]! as int,
              ),
          ],
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

/// A footstep of the narrator walking to the next line: on which phone,
/// when (this device's clock).
typedef Step = ({int seat, int at});

/// One moment as the narrator will say it: which recording, when (this
/// device's clock), how the voice walks meanwhile and the footsteps that
/// lead to it.
typedef Planned = ({
  String key,
  Clip clip,
  int at,
  NarratorWalk walk,
  List<Step> steps,
});

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

  /// Clips planned but not begun yet, with what stops them.
  final _waiting = <ClipPlayer, void Function()>{};

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

  /// How often the volume follows the walk during a handover (between
  /// handovers it does not change, and nothing ticks).
  static const _step = Duration(milliseconds: 12);

  /// Between two footsteps (about two steps a second).
  static const stepMs = 450;

  /// How loud a footstep plays: about 10 dB under the voice.
  static const stepVolume = 0.32;

  /// Whether this phone stays silent.
  bool muted = false;

  /// Says [moments], starting at [startMs] (this device's clock), on the
  /// [speakers] (the phones that play sound, in seat order: the same list
  /// on every phone); this phone plays its part if [me] is one of them.
  /// Nothing runs past [deadlineMs] (the end of the phase). Stops whatever
  /// was still being said. Returns the plan, also when this phone is
  /// silent, so the screen can follow it.
  ///
  /// With [goingOn] the same moments are planned again over other
  /// [speakers] (a phone dropped out or came back): what is being said
  /// goes on to its end, only what is still to come moves to the others.
  List<Planned> speak({
    required List<Spoken> moments,
    required NarratorLanguage language,
    required int round,
    required int startMs,
    required List<PlayerId> speakers,
    required PlayerId me,
    int? deadlineMs,
    Set<String> facts = const {},
    bool goingOn = false,
    NarratorStage stage = NarratorStage.lively,
    bool night = false,
  }) {
    final now = _clock();
    if (goingOn) {
      _stopWaiting();
    } else {
      stop();
    }
    final planned = plan(
      moments: moments,
      language: language,
      round: round,
      startMs: startMs,
      speakers: speakers,
      deadlineMs: deadlineMs,
      facts: facts,
      stage: stage,
      night: night,
    );
    final mine = speakers.indexOf(me);
    if (muted || mine < 0) return planned;
    for (final p in planned) {
      // Going on, a moment already begun stays with those saying it.
      if (goingOn && p.at <= now) continue;
      for (final (i, step) in p.steps.indexed) {
        if (step.seat == mine) _scheduleStep(i, step.at);
      }
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
    NarratorStage stage = NarratorStage.lively,
    bool night = false,
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
      var begins = planned.isEmpty
          ? at
          : at + gap(planned.last.key, moment.key);
      // Between two lines the narrator may walk somewhere else, audibly:
      // a footstep on each phone it passes. Never at night.
      final steps = <Step>[];
      final from = position;
      final to = from == null || night
          ? null
          : NarratorWalk.relocate(
              seats: speakers.length,
              room: room,
              round: round,
              line: moment.key,
              occurrence: occurrence,
              from: from,
              stage: stage,
            );
      if (from != null && to != null) {
        final way = NarratorWalk.path(speakers.length, from, to);
        for (final (i, seat) in way.indexed) {
          steps.add((seat: seat, at: at + 250 + i * stepMs));
        }
        begins = max(begins, steps.last.at + stepMs);
      }
      if (deadlineMs != null && begins + clip.ms > deadlineMs) break;
      final target = moment.to == null ? -1 : speakers.indexOf(moment.to!);
      final walk = NarratorWalk.plan(
        seats: speakers.length,
        room: room,
        round: round,
        line: moment.key,
        lengthMs: clip.ms,
        occurrence: occurrence,
        start: to ?? position,
        to: target < 0 ? null : target,
        pauses: clip.pauses,
        stage: stage,
        night: night,
      );
      planned.add((
        key: moment.key,
        clip: clip,
        at: begins,
        walk: walk,
        steps: steps,
      ));
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
    late final void Function() cancelStart;
    _waiting[player] = () {
      cancelStart();
      _playing.remove(player);
      player.stop();
    };
    _cancels
      ..add(
        cancelStart = _startTimer(
          Duration(milliseconds: wait < 0 ? 0 : wait),
          () {
            _waiting.remove(player);
            if (!prepared) {
              // Not loaded in time: better silent than late and out of step.
              _playing.remove(player);
              player.stop();
              return;
            }
            player.start();
            final fades = walk.fades;
            void tick() {
              final ms = _clock() - startMs;
              if (ms > clip.ms) {
                _playing.remove(player);
                player.stop();
                return;
              }
              player.volume(walk.gainAt(seat, ms));
              // Fine steps through a handover; otherwise asleep until the
              // next one (or the end of the clip).
              final inFade = fades.any((f) => f.from <= ms && ms < f.until);
              final next = fades
                  .where((f) => f.from > ms)
                  .map((f) => f.from)
                  .fold(clip.ms + 1, min);
              follow = _startTimer(
                inFade ? _step : Duration(milliseconds: max(1, next - ms)),
                tick,
              );
            }

            tick();
          },
        ),
      )
      ..add(() => follow?.call());
  }

  /// The [i]-th footstep of a walk, on this phone at [startMs].
  void _scheduleStep(int i, int startMs) {
    if (startMs < _clock() - _late) return;
    final player = _player();
    var prepared = false;
    _playing.add(player);
    unawaited(
      player
          .prepare('sounds/steps/step${i % 5}.mp3', stepVolume)
          .then((_) => prepared = true)
          .catchError((Object _) => false),
    );
    final wait = startMs - _clock();
    late final void Function() cancelStart;
    _waiting[player] = () {
      cancelStart();
      _playing.remove(player);
      player.stop();
    };
    _cancels.add(
      cancelStart = _startTimer(Duration(milliseconds: max(0, wait)), () {
        _waiting.remove(player);
        if (!prepared) {
          _playing.remove(player);
          player.stop();
          return;
        }
        player.start();
        _cancels.add(
          _startTimer(const Duration(milliseconds: 900), () {
            _playing.remove(player);
            player.stop();
          }),
        );
      }),
    );
  }

  /// Drops the clips that have not begun.
  void _stopWaiting() {
    for (final stop in [..._waiting.values]) {
      stop();
    }
    _waiting.clear();
  }

  /// Stops the voice at once.
  void stop() {
    for (final cancel in _cancels) {
      cancel();
    }
    _cancels.clear();
    _waiting.clear();
    for (final player in _playing) {
      player.stop();
    }
    _playing.clear();
  }
}
