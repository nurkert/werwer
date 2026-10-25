import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  Widget host(Locale locale) => MaterialApp(
    locale: locale,
    localizationsDelegates: GlobalMaterialLocalizations.delegates,
    supportedLocales: supportedLocales,
    theme: buildTheme(),
    home: const StartScreen(version: '0.0.1'),
  );

  testWidgets('shows the development status with the version in German', (
    tester,
  ) async {
    await tester.pumpWidget(host(const Locale('de')));
    expect(find.text('In Entwicklung · 0.0.1'), findsOneWidget);
    expect(find.bySemanticsLabel('Whowolf'), findsOneWidget);
  });

  testWidgets('falls back to English for other languages', (tester) async {
    await tester.pumpWidget(host(const Locale('en')));
    expect(find.text('In development · 0.0.1'), findsOneWidget);
  });
}
