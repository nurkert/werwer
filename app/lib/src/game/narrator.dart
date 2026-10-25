import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';

/// What the narrator says when the game moves from [before] to [after], or
/// `null` if nothing changed worth announcing. Uses only what every player
/// may know, so the host device can say it out loud.
String? narration(
  PlayerView? before,
  PlayerView after,
  AppLocalizations l10n,
) {
  if (before != null &&
      before.phase == after.phase &&
      before.round == after.round) {
    return null;
  }
  String? roleOf(DeathView d) =>
      d.role == null ? null : l10n.narrateRole(l10n.role(d.role!));
  DeathView? death(DeathCause cause, int round) => after.deaths
      .where((d) => d.cause == cause && d.round == round)
      .firstOrNull;

  return switch (after.phase) {
    Phase.lobby => null,
    Phase.roleReveal => l10n.narrateReveal,
    Phase.night => () {
      final parts = <String>[];
      if (before?.phase == Phase.vote) {
        final out = death(DeathCause.vote, after.round - 1);
        parts.add(
          out == null
              ? l10n.nobodyEliminated
              : [
                  l10n.eliminated(after.nameOf(out.player)),
                  ?roleOf(out),
                ].join(' '),
        );
      }
      parts.add(l10n.narrateNight);
      return parts.join(' ');
    }(),
    Phase.day => () {
      final victim = death(DeathCause.night, after.round);
      return [
        l10n.narrateMorning,
        if (victim == null)
          l10n.nobodyDied
        else ...[
          l10n.killedAtNight(after.nameOf(victim.player)),
          ?roleOf(victim),
        ],
        l10n.narrateDiscuss,
      ].join(' ');
    }(),
    Phase.vote => l10n.narrateVote,
    Phase.ended => () {
      final out =
          death(DeathCause.vote, after.round) ??
          death(DeathCause.night, after.round);
      return [
        if (out != null)
          out.cause == DeathCause.vote
              ? l10n.eliminated(after.nameOf(out.player))
              : l10n.killedAtNight(after.nameOf(out.player)),
        if (out != null) ?roleOf(out),
        if (after.winner == Faction.village)
          l10n.villageWins
        else
          l10n.werewolvesWin,
      ].join(' ');
    }(),
  };
}

/// Speaks narrator lines on the host device. Platforms without speech
/// output simply stay silent.
class Voice {
  final _tts = FlutterTts();
  bool muted = false;
  String? _language;

  Future<void> say(String text, String languageCode) async {
    if (muted) return;
    try {
      final language = languageCode == 'de' ? 'de-DE' : 'en-US';
      if (_language != language) {
        _language = language;
        await _tts.setLanguage(language);
        await _tts.setSpeechRate(0.45);
      }
      await _tts.stop();
      await _tts.speak(text);
    } on Object {
      // No speech engine: the text is on screen anyway.
    }
  }

  void stop() => unawaited(_tts.stop().catchError((Object _) => null));
}
