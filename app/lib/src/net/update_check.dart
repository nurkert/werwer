import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/theme.dart';

/// Where the releases are listed (GitHub's public API, no account).
final Uri _releases = Uri.parse(
  'https://api.github.com/repos/nurkert/whowolf/releases?per_page=5',
);

/// Where players get a new version.
final Uri downloadPage = Uri.parse('https://whowolf.de/download/');

final _version = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)$');

/// Compares two versions like `0.1.6` (a leading `v` is fine); `null` if
/// either is not one.
int? compareVersions(String a, String b) {
  final x = _version.firstMatch(a.trim());
  final y = _version.firstMatch(b.trim());
  if (x == null || y == null) return null;
  for (var i = 1; i <= 3; i++) {
    final d = int.parse(x.group(i)!).compareTo(int.parse(y.group(i)!));
    if (d != 0) return d;
  }
  return 0;
}

/// The newest published version in GitHub's release list [json], or
/// `null`. Drafts do not count; pre-releases do (every Whowolf release is
/// one during the beta).
String? newestIn(Object? json) {
  if (json is! List<Object?>) return null;
  String? best;
  for (final release in json) {
    if (release is! Map<String, Object?> || release['draft'] == true) continue;
    final tag = release['tag_name'];
    if (tag is! String || compareVersions(tag, '0.0.0') == null) continue;
    if (best == null || compareVersions(tag, best)! > 0) best = tag;
  }
  return best?.replaceFirst('v', '');
}

/// Asks GitHub for the newest release; `null` on any failure (offline, a
/// limit, an odd answer): then simply nothing is shown.
Future<String?> fetchNewestRelease() async {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
  try {
    final request = await client.getUrl(_releases);
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/vnd.github+json')
      ..set(HttpHeaders.userAgentHeader, 'Whowolf');
    final response = await request.close().timeout(const Duration(seconds: 8));
    if (response.statusCode != HttpStatus.ok) return null;
    // A release list is a few kilobytes; read no more than that.
    final bytes = <int>[];
    await for (final chunk in response.timeout(const Duration(seconds: 8))) {
      bytes.addAll(chunk);
      if (bytes.length > 512 * 1024) return null;
    }
    return newestIn(jsonDecode(utf8.decode(bytes)));
  } on Object {
    return null;
  } finally {
    client.close(force: true);
  }
}

/// How long "Later" keeps the note away before it asks again.
const updateSnooze = Duration(hours: 20);

/// Whether the note for [newest] should show, given what the store
/// remembers ([seen]: `version|millis` of the last time it was shown).
bool shouldRemind(String newest, String? seen, DateTime now) {
  if (seen == null) return true;
  final parts = seen.split('|');
  if (parts.first != newest) return true;
  final at = parts.length > 1 ? int.tryParse(parts[1]) : null;
  // An old entry without a time: shown once already, ask again.
  if (at == null) return true;
  return now.difference(DateTime.fromMillisecondsSinceEpoch(at)) >=
      updateSnooze;
}

/// On app start: if the player has not switched it off and a newer version
/// than [current] is out, a note on the stage says so, again the next day
/// as long as this device is behind (only equal versions play together).
/// Not in the browser (the page always matches its host), nor in a build
/// without a version. On the iPhone the update comes through AltStore or
/// SideStore, which the note says.
Future<void> checkForUpdate(BuildContext context, String current) async {
  if (kIsWeb || compareVersions(current, '0.0.0') == null) return;
  const store = Store();
  if (!await store.updateCheck()) return;
  final newest = await fetchNewestRelease();
  if (newest == null || compareVersions(newest, current)! <= 0) return;
  final now = DateTime.now();
  if (!shouldRemind(newest, await store.updateSeen(), now)) return;
  if (!context.mounted) return;
  final download = await showDialog<bool>(
    context: context,
    builder: (context) => UpdateNote(
      newest: newest,
      current: current,
      iPhone: Platform.isIOS,
    ),
  );
  await store.setUpdateSeen('$newest|${now.millisecondsSinceEpoch}');
  if (download ?? false) {
    unawaited(launchUrl(downloadPage, mode: LaunchMode.externalApplication));
  }
}

/// The note itself, on a plaque of the stage.
class UpdateNote extends StatelessWidget {
  const UpdateNote({
    required this.newest,
    required this.current,
    this.iPhone = false,
    super.key,
  });

  final String newest;
  final String current;
  final bool iPhone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Dialog(
      backgroundColor: Palette.stagePlaque,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Headline(
                l10n.updateTitle(newest),
                eyebrow: l10n.updateEyebrow,
                size: 28,
              ),
              const SizedBox(height: 10),
              Body(l10n.updateText(current)),
              if (iPhone) ...[
                const SizedBox(height: 8),
                Body(l10n.updateIphone, muted: true),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.updateGet,
                onPressed: () => Navigator.pop(context, true),
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: l10n.updateLater,
                onPressed: () => Navigator.pop(context, false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
