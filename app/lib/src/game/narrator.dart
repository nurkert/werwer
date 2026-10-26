import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/news.dart';

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
  final deaths = freshDeaths(after);
  return switch (after.phase) {
    Phase.lobby => null,
    Phase.roleReveal => l10n.narrateReveal,
    Phase.night => [
      if (before?.phase == Phase.vote || before?.phase == Phase.hunterShot)
        l10n.news(after, deaths, l10n.nobodyEliminated),
      l10n.narrateNight,
    ].join(' '),
    Phase.day => [
      l10n.narrateMorning,
      l10n.news(after, deaths, l10n.nobodyDied),
      l10n.narrateDiscuss,
    ].join(' '),
    Phase.hunterShot => [
      l10n.news(after, deaths, ''),
      l10n.narrateHunter,
    ].where((part) => part.isNotEmpty).join(' '),
    Phase.vote => l10n.narrateVote,
    Phase.ended => [
      l10n.news(after, deaths, ''),
      l10n.winner(after.winner),
    ].where((part) => part.isNotEmpty).join(' '),
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
