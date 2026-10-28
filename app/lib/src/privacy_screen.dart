import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/stage/scene.dart';
import 'package:whowolf/src/theme.dart';

/// What the app does with data, in the app itself (Art. 13 GDPR): readable
/// offline, the full version is on whowolf.de.
class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    Widget section(String title, String text) => Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: displayFont,
              fontSize: 22,
              color: Palette.moon100,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(color: Palette.moon100, height: 1.45),
          ),
        ],
      ),
    );
    return StageScaffold(
      scene: Scene.backstage,
      floatingAppBar: true,
      appBar: AppBar(title: Text(l10n.privacyTitle)),
      body: StageScroll(
        maxWidth: 640,
        child: Column(
          children: [
            for (final (title, text) in [
              (l10n.privacySummaryTitle, l10n.privacySummary),
              (l10n.privacyTableTitle, l10n.privacyTable),
              (l10n.privacyServerTitle, l10n.privacyServer),
              (l10n.privacyDeviceTitle, l10n.privacyDevice),
              (l10n.privacyBrowserTitle, l10n.privacyBrowser),
              (l10n.privacyUpdatesTitle, l10n.privacyUpdates),
              (l10n.privacyRightsTitle, l10n.privacyRights),
            ]) ...[
              section(title, text),
              const SizedBox(height: 16),
            ],
            Body(l10n.privacyUpdated, muted: true),
          ],
        ),
      ),
    );
  }
}

/// Opens the privacy notice.
Future<void> showPrivacy(BuildContext context) => Navigator.push(
  context,
  MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
);

/// The first time the app starts: a short word on privacy. Information,
/// not a consent: nothing here needs one (Art. 6(1)(f) GDPR).
Future<void> showPrivacyNoticeOnce(BuildContext context) async {
  const store = Store();
  if (await store.privacyNoticeSeen() || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final read = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Headline(l10n.privacyNoticeTitle, size: 26),
            const SizedBox(height: 12),
            Body(l10n.privacyNotice),
            const SizedBox(height: 20),
            PrimaryButton(
              label: l10n.privacyOk,
              onPressed: () => Navigator.pop(context, false),
            ),
            const SizedBox(height: 8),
            SecondaryButton(
              label: l10n.privacyRead,
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        ),
      ),
    ),
  );
  await store.setPrivacyNoticeSeen();
  if ((read ?? false) && context.mounted) await showPrivacy(context);
}
