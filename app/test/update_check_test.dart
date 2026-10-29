import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/net/update_check.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  test('versions compare by number, not by text', () {
    expect(compareVersions('0.1.10', '0.1.9'), greaterThan(0));
    expect(compareVersions('v0.2.0', '0.1.99'), greaterThan(0));
    expect(compareVersions('0.1.6', 'v0.1.6'), 0);
    expect(compareVersions('dev', '0.1.6'), isNull);
  });

  test('the newest published release counts, drafts and odd tags do not', () {
    final json = [
      {'tag_name': 'v0.1.6', 'draft': false, 'prerelease': true},
      {'tag_name': 'v0.2.0', 'draft': true},
      {'tag_name': 'nightly', 'draft': false},
      {'tag_name': 'v0.1.10', 'draft': false, 'prerelease': true},
      'garbage',
    ];
    expect(newestIn(json), '0.1.10');
    expect(newestIn({'message': 'rate limited'}), isNull);
    expect(newestIn(<Object?>[]), isNull);
  });

  test('the note asks again the next day while the device is behind', () {
    final now = DateTime(2026, 10, 29, 12);
    String seen(Duration ago, [String version = '0.2.1']) =>
        '$version|${now.subtract(ago).millisecondsSinceEpoch}';
    expect(shouldRemind('0.2.1', null, now), isTrue);
    expect(shouldRemind('0.2.1', seen(const Duration(hours: 1)), now), isFalse);
    expect(shouldRemind('0.2.1', seen(const Duration(hours: 21)), now), isTrue);
    // A newer version than the one last shown: at once.
    expect(
      shouldRemind('0.3.0', seen(const Duration(minutes: 5)), now),
      isTrue,
    );
    // Stored by an older app (version only).
    expect(shouldRemind('0.2.1', '0.2.1', now), isTrue);
  });

  testWidgets('the note fits a phone and tells iPhone players where to go', (
    tester,
  ) async {
    tester.view
      ..physicalSize = const Size(320, 640)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: supportedLocales,
        theme: buildTheme(),
        home: const Scaffold(
          body: UpdateNote(newest: '0.2.1', current: '0.2.0', iPhone: true),
        ),
      ),
    );
    expect(find.text('Version 0.2.1 ist da'), findsOneWidget);
    expect(find.textContaining('AltStore oder SideStore'), findsOneWidget);
    expect(find.text('Zur Download-Seite'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
