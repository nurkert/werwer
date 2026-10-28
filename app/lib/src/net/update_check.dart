import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/net/store.dart';

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

/// Once per app start: if the player has not switched it off and a newer
/// version than [current] is out, a short note says so, once per version.
/// Not in the browser (the page always matches its host) and not on iOS
/// (TestFlight updates by itself), nor in a build without a version.
Future<void> checkForUpdate(BuildContext context, String current) async {
  if (kIsWeb || Platform.isIOS || compareVersions(current, '0.0.0') == null) {
    return;
  }
  const store = Store();
  if (!await store.updateCheck()) return;
  final newest = await fetchNewestRelease();
  if (newest == null || compareVersions(newest, current)! <= 0) return;
  if (await store.updateSeen() == newest || !context.mounted) return;
  final l10n = AppLocalizations.of(context);
  final download = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.updateTitle(newest)),
      content: Text(l10n.updateText(current)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l10n.updateLater),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(l10n.updateGet),
        ),
      ],
    ),
  );
  await store.setUpdateSeen(newest);
  if (download ?? false) {
    unawaited(launchUrl(downloadPage, mode: LaunchMode.externalApplication));
  }
}
