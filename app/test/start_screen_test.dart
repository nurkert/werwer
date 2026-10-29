import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/stage/wolf_title.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  Widget host(Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: supportedLocales,
    theme: buildTheme(),
    home: const StartScreen(version: '0.0.1'),
  );

  testWidgets('shows the test version stamp in German', (tester) async {
    await tester.pumpWidget(host(const Locale('de')));
    expect(find.text('Testversion · 0.0.1'), findsOneWidget);
    expect(find.text('Raum öffnen'), findsOneWidget);
    expect(find.bySemanticsLabel('Whowolf'), findsOneWidget);
  });

  testWidgets('falls back to English for other languages', (tester) async {
    await tester.pumpWidget(host(const Locale('fr')));
    expect(find.text('Test version · 0.0.1'), findsOneWidget);
  });

  testWidgets('asks for a name before opening a room', (tester) async {
    await tester.pumpWidget(host(const Locale('en')));
    await tester.ensureVisible(find.text('Join a room'));
    await tester.tap(find.text('Join a room'));
    await tester.pump();
    expect(find.text('Enter your name first.'), findsOneWidget);
  });

  testWidgets('on a computer the title and the wolf stand still', (
    tester,
  ) async {
    for (final size in [const Size(1400, 900), const Size(1200, 560)]) {
      tester.view
        ..physicalSize = size
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(host(const Locale('de')));
      await tester.pump();
      expect(
        find.ancestor(
          of: find.byType(WolfTitle),
          matching: find.byType(Scrollable),
        ),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    }
  });
}
