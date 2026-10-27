import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

/// Plain-language help for the usual network traps (iOS permission, desktop
/// firewall, guest Wi-Fi with client isolation), this device's first.
Future<void> showNetworkHelp(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  final mine = [
    if (Platform.isIOS) l10n.helpIos,
    if (Platform.isAndroid) l10n.helpAndroid,
    if (Platform.isMacOS) l10n.helpMac,
    if (Platform.isWindows) l10n.helpWindows,
  ];
  final tips = [
    l10n.helpSameWifi,
    ...mine,
    l10n.helpGuest,
    for (final t in [l10n.helpIos, l10n.helpMac, l10n.helpWindows])
      if (!mine.contains(t)) t,
    l10n.helpVpn,
    l10n.helpQr,
  ];
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Headline(l10n.helpTitle)),
            const SizedBox(height: 12),
            for (final tip in tips)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 3),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Palette.lantern400,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        tip,
                        style: const TextStyle(
                          color: Palette.moon100,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

/// A small text button that opens [showNetworkHelp].
class HelpLink extends StatelessWidget {
  const HelpLink({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    onPressed: () => showNetworkHelp(context),
    icon: const Icon(Icons.help_outline, size: 18),
    label: Text(AppLocalizations.of(context).helpLink),
    style: TextButton.styleFrom(foregroundColor: Palette.moon200),
  );
}

/// The game in five acts, as the rules on paper (task 012): every act
/// with its own picture, a corner of a stage set with a villager in front.
/// On the start screen's left page (it scrolls) and in [showHowItWorks].
class HowSteps extends StatelessWidget {
  const HowSteps({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final acts = [
      (
        l10n.act1,
        l10n.how1Title,
        l10n.how1Text,
        'village',
        posed(Persona.baker, 3).$1,
        const Alignment(0, 0.3),
      ),
      (
        l10n.act2,
        l10n.how2Title,
        l10n.how2Text,
        'theatre',
        figureAsset(Role.werewolf),
        const Alignment(0, 0.6),
      ),
      (
        l10n.act3,
        l10n.how3Title,
        l10n.how3Text,
        'nightlake',
        figureAsset(Role.seer),
        const Alignment(0, 0.2),
      ),
      (
        l10n.act4,
        l10n.how4Title,
        l10n.how4Text,
        'dusk',
        posed(Persona.smith, 2).$1,
        const Alignment(0, 0.6),
      ),
      (
        l10n.act5,
        l10n.how5Title,
        l10n.how5Text,
        'finale',
        posed(Persona.mayor, 2).$1,
        const Alignment(0, 0.6),
      ),
    ];
    return Panel(
      paper: true,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (i, (act, title, text, scene, figure, focus))
              in acts.indexed) ...[
            if (i > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Palette.gold500.withValues(alpha: 0.5),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.nightlight_round,
                        size: 14,
                        color: Palette.gold500,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: Palette.gold500.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            _ActPicture(
              scene: scene,
              figure: figure,
              focus: focus,
              number: i + 1,
            ),
            const SizedBox(height: 12),
            Text(
              act.toUpperCase(),
              style: const TextStyle(
                fontFamily: displayFont,
                fontSize: 12.5,
                letterSpacing: 2,
                fontWeight: FontWeight.w700,
                color: Palette.curtain600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(
                fontFamily: displayFont,
                fontWeight: FontWeight.w700,
                fontSize: 24,
                height: 1.15,
                color: Palette.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              text,
              style: const TextStyle(
                fontSize: 16.5,
                height: 1.45,
                color: Palette.inkSoft,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// An act's picture: a corner of a painted stage set, framed in brass,
/// with a cardboard villager standing in it and the act's number.
class _ActPicture extends StatelessWidget {
  const _ActPicture({
    required this.scene,
    required this.figure,
    required this.focus,
    required this.number,
  });

  final String scene;
  final String figure;
  final Alignment focus;
  final int number;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: AspectRatio(
      aspectRatio: 16 / 9,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Palette.stageBrass, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LayoutBuilder(
            builder: (context, box) => Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'assets/stage/$scene.webp',
                  fit: BoxFit.cover,
                  alignment: focus,
                  cacheWidth: (box.maxWidth * 2).round(),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x00000000), Color(0x66000000)],
                      stops: [0.5, 1],
                    ),
                  ),
                ),
                Positioned(
                  right: box.maxWidth * 0.08,
                  bottom: box.maxHeight * 0.04,
                  height: box.maxHeight * 0.86,
                  child: Image.asset(figure, fit: BoxFit.contain),
                ),
                Positioned(
                  left: 12,
                  top: 10,
                  child: Container(
                    width: 40,
                    height: 40,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Palette.paper,
                      border: Border.all(color: Palette.stageBrass, width: 2),
                    ),
                    child: Text(
                      '$number',
                      style: const TextStyle(
                        fontFamily: displayFont,
                        fontWeight: FontWeight.w700,
                        fontSize: 22,
                        height: 1,
                        color: Palette.curtain600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

/// [HowSteps] in a sheet, for whoever plays for the first time.
Future<void> showHowItWorks(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          children: [
            Headline(l10n.howTitle, eyebrow: l10n.howEyebrow),
            const SizedBox(height: 16),
            const HowSteps(),
            const SizedBox(height: 16),
            PrimaryButton(
              label: l10n.howDone,
              icon: Icons.check_rounded,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    ),
  );
}
