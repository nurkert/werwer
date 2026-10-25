import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/sheep.dart';

void main() {
  testWidgets('tapping sheep changes the dream points', (tester) async {
    final deltas = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SheepMeadow(onPoints: deltas.add),
        ),
      ),
    );
    // Let a few sheep run onto the meadow.
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    final sheep = find.descendant(
      of: find.byType(SheepMeadow),
      matching: find.byType(GestureDetector),
    );
    expect(sheep, findsWidgets);
    await tester.tap(sheep.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 50));
    expect(deltas, hasLength(1));
    expect(deltas.single == 1 || deltas.single == -3, isTrue);
    await tester.pumpWidget(const SizedBox());
  });
}
