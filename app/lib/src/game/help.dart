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

/// The game in five acts, as a playbill (task 012): three villagers stand
/// on the stage above a paper slip with the acts. On the start screen's
/// left page and in [showHowItWorks].
class HowSteps extends StatelessWidget {
  const HowSteps({super.key, this.figure = 120});

  /// How tall the villagers above the playbill stand.
  final double figure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final acts = [
      (l10n.act1, l10n.how1Title, l10n.how1Text),
      (l10n.act2, l10n.how2Title, l10n.how2Text),
      (l10n.act3, l10n.how3Title, l10n.how3Text),
      (l10n.act4, l10n.how4Title, l10n.how4Text),
      (l10n.act5, l10n.how5Title, l10n.how5Text),
    ];
    final (baker, _) = posed(Persona.baker, 3);
    final (smith, _) = posed(Persona.smith, 2);
    final (maid, _) = posed(Persona.maid, 1);
    return Column(
      children: [
        // The ensemble, the werewolf hiding in the middle.
        ExcludeSemantics(
          child: SizedBox(
            height: figure,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Image.asset(baker, height: figure * 0.86),
                Transform.translate(
                  offset: Offset(-figure * 0.08, 0),
                  child: Image.asset(
                    figureAsset(Role.werewolf),
                    height: figure,
                  ),
                ),
                Transform.translate(
                  offset: Offset(-figure * 0.16, 0),
                  child: Image.asset(smith, height: figure * 0.9),
                ),
                Transform.translate(
                  offset: Offset(-figure * 0.24, 0),
                  child: Image.asset(maid, height: figure * 0.82),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 4),
        Panel(
          paper: true,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            children: [
              for (final (i, (act, title, text)) in acts.indexed) ...[
                if (i > 0)
                  Container(
                    height: 1,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    color: Palette.gold500.withValues(alpha: 0.45),
                  ),
                Semantics(
                  container: true,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 34,
                        child: Text(
                          '${i + 1}',
                          style: const TextStyle(
                            fontFamily: displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 28,
                            height: 1,
                            color: Palette.curtain600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              act.toUpperCase(),
                              style: const TextStyle(
                                fontFamily: displayFont,
                                fontSize: 10.5,
                                letterSpacing: 1.6,
                                fontWeight: FontWeight.w700,
                                color: Palette.inkSoft,
                              ),
                            ),
                            Text(
                              title,
                              style: const TextStyle(
                                fontFamily: displayFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                height: 1.15,
                                color: Palette.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              text,
                              style: const TextStyle(
                                fontSize: 13,
                                height: 1.3,
                                color: Palette.inkSoft,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
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
            const HowSteps(figure: 100),
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
