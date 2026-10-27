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

/// The game in five steps, with the figures (task 012): on the start
/// screen's second page and in [showHowItWorks].
class HowSteps extends StatelessWidget {
  const HowSteps({super.key, this.figure = 76});

  /// How tall the figure beside each step stands.
  final double figure;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = [
      (Icons.qr_code_2_rounded, Role.villager, l10n.how1Title, l10n.how1Text),
      (Icons.style_rounded, Role.werewolf, l10n.how2Title, l10n.how2Text),
      (Icons.bedtime_rounded, Role.seer, l10n.how3Title, l10n.how3Text),
      (Icons.forum_rounded, Role.hunter, l10n.how4Title, l10n.how4Text),
      (Icons.how_to_vote_rounded, Role.witch, l10n.how5Title, l10n.how5Text),
    ];
    return Column(
      children: [
        for (final (i, (icon, role, title, text)) in steps.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          Panel(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.fromBorderSide(
                      BorderSide(color: Palette.stageBrassLight, width: 1.5),
                    ),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontFamily: displayFont,
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                      color: Palette.stageIvory,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: Palette.stageLanternTop),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontFamily: displayFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: Palette.stageIvory,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: Palette.stageIvorySoft,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                ExcludeSemantics(
                  child: SizedBox(
                    width: figure * 0.7,
                    height: figure,
                    child: Image.asset(figureAsset(role), fit: BoxFit.contain),
                  ),
                ),
              ],
            ),
          ),
        ],
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
