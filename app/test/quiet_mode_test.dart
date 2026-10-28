import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/quiet_mode.dart';

void main() {
  testWidgets('where the app cannot switch it, the card explains how', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: QuietModeCard()),
      ),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(QuietModeCard)),
    );
    expect(find.text(l10n.quietTitle), findsOneWidget);
    expect(QuietMode.switches, isFalse, reason: 'tests run on a computer');
    await tester.tap(find.text(l10n.quietHow));
    await tester.pumpAndSettle();
    // The steps for the computer the test runs on (CI: Linux).
    expect(
      find.textContaining(Platform.isMacOS ? l10n.quietMac : l10n.quietOther),
      findsOneWidget,
    );
  });

  test('stopping without having started touches nothing', () async {
    await QuietMode.stop();
    expect(QuietMode.on.value, isFalse);
  });
}
