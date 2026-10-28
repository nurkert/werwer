import 'dart:async';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/news.dart';
import 'package:whowolf/src/game/widgets.dart';

/// What the narrator says when the game moves from [before] to [after], or
/// `null` if nothing changed worth announcing. Uses only what every player
/// may know, so the host device can say it out loud.
String? narration(
  PlayerView? before,
  PlayerView after,
  AppLocalizations l10n,
) {
  final called = after.settings.nightMode == NightMode.called;
  if (before != null &&
      before.phase == after.phase &&
      before.round == after.round) {
    if (after.phase == Phase.vote &&
        before.runoff.isEmpty &&
        after.runoff.isNotEmpty) {
      return l10n.narrateRunoff;
    }
    // In the called night the narrator wakes one role after another.
    if (called &&
        after.phase == Phase.night &&
        before.nightStep != after.nightStep) {
      return '${l10n.narrateStepSleep} ${_wake(after.nightStep, l10n)}';
    }
    return null;
  }
  final deaths = freshDeaths(after);
  return switch (after.phase) {
    Phase.lobby => null,
    Phase.roleReveal => l10n.narrateReveal,
    Phase.night => [
      if (before?.phase == Phase.vote || before?.phase == Phase.hunterShot)
        l10n.news(after, deaths, l10n.nobodyEliminated),
      if (called) ...[
        l10n.narrateNightCalled,
        _wake(after.nightStep, l10n),
      ] else
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

String _wake(NightStep step, AppLocalizations l10n) => switch (step) {
  NightStep.link => l10n.narrateStepLink,
  NightStep.hunt => l10n.narrateStepHunt,
  NightStep.inspect => l10n.narrateStepInspect,
  NightStep.brew => l10n.narrateStepBrew,
  NightStep.protect => l10n.narrateStepProtect,
};

/// Who is awake in a called night's [step], for everyone else's screen.
String awakeIn(NightStep step, AppLocalizations l10n) => switch (step) {
  NightStep.link => l10n.role(Role.cupid),
  NightStep.hunt => l10n.nightWerewolves,
  NightStep.inspect => l10n.role(Role.seer),
  NightStep.brew => l10n.role(Role.witch),
  NightStep.protect => l10n.role(Role.protector),
};

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
