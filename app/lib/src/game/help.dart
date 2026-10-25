import 'dart:io';

import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
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
    backgroundColor: Palette.night800,
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
