import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/net/page_legal.dart';
import 'package:whowolf/src/theme.dart';
import 'package:whowolf/src/web_join_screen.dart';

/// A browser page shows the publisher's privacy notice only where it
/// applies; on another operator's server only that operator's pages, or
/// none (task 029).
void main() {
  final official = Uri.parse('https://play.whowolf.de/v/18/0.3.0/join');
  final other = Uri.parse('https://relay.example.org/v/18/0.3.0/join');
  final phone = Uri.parse('http://192.168.1.20:4040/v/18/0.3.0/join');
  const set =
      '{"imprint":"https://example.org/impressum",'
      '"privacy":"https://example.org/datenschutz",'
      '"imprintEn":null,"privacyEn":"https://example.org/privacy"}';
  const none =
      '{"imprint":null,"privacy":null,"imprintEn":null,"privacyEn":null}';

  test('the official server and the host phone keep the publisher notice', () {
    expect(
      pageLegal(page: official, legalJson: set, german: true).operator,
      isFalse,
    );
    // The host's phone has no /legal.json.
    expect(
      pageLegal(page: phone, legalJson: null, german: true).operator,
      isFalse,
    );
  });

  test("another operator's server shows only its own pages", () {
    final de = pageLegal(page: other, legalJson: set, german: true);
    expect(de.operator, isTrue);
    expect(de.imprint, Uri.parse('https://example.org/impressum'));
    expect(de.privacy, Uri.parse('https://example.org/datenschutz'));
    final en = pageLegal(page: other, legalJson: set, german: false);
    expect(en.imprint, Uri.parse('https://example.org/impressum'));
    expect(en.privacy, Uri.parse('https://example.org/privacy'));
  });

  test('nothing set, odd or unsafe answers: no links at all', () {
    for (final json in [
      none,
      'not json',
      '[1]',
      '{"imprint":"http://example.org","privacy":"javascript:x"}',
    ]) {
      final pages = pageLegal(page: other, legalJson: json, german: true);
      expect(pages.operator, isTrue, reason: json);
      expect(pages.imprint, isNull, reason: json);
      expect(pages.privacy, isNull, reason: json);
    }
  });

  Future<void> show(WidgetTester tester, Uri page, String? json) =>
      tester.pumpWidget(
        MaterialApp(
          locale: const Locale('de'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: supportedLocales,
          theme: buildTheme(),
          home: Scaffold(
            body: PageLegalLinks(page: page, legalJson: Future.value(json)),
          ),
        ),
      );

  testWidgets('the links on the join page', (tester) async {
    await show(tester, other, none);
    await tester.pump();
    expect(find.text('Datenschutz'), findsNothing);
    expect(find.text('Impressum'), findsNothing);

    await show(tester, other, set);
    await tester.pump();
    expect(find.text('Impressum'), findsOneWidget);
    expect(find.text('Datenschutz'), findsOneWidget);

    await show(tester, phone, null);
    await tester.pump();
    expect(find.text('Datenschutz'), findsOneWidget);
    expect(find.text('Impressum'), findsNothing);
  });
}
