import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/seer_vision.dart';

void main() {
  const seat = SeatView(
    id: PlayerId('p2'),
    name: 'Bo',
    isAlive: true,
    persona: Persona.baker,
  );

  Future<void> open(WidgetTester tester, SeerResult result) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () => showSeerVision(context, seat, result),
            child: const Text('look'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('look'));
    await tester.pump();
  }

  testWidgets('the figure turns into what they are, large, then the vision '
      'closes by itself', (tester) async {
    await open(
      tester,
      const SeerResult(
        target: PlayerId('p2'),
        round: 1,
        faction: Faction.werewolves,
        role: Role.werewolf,
      ),
    );
    final figure = tester.widget<TurningFigure>(find.byType(TurningFigure));
    expect(figure.showBack, isTrue, reason: 'first from behind');
    expect(figure.asset, personaRoleAsset(Persona.baker, Role.werewolf));
    expect(find.text('Bo'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    expect(
      tester.widget<TurningFigure>(find.byType(TurningFigure)).showBack,
      isFalse,
    );
    expect(find.text('Werwolf'), findsOneWidget);

    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.byType(TurningFigure), findsNothing);
  });

  testWidgets('a tap closes it at once', (tester) async {
    await open(
      tester,
      const SeerResult(
        target: PlayerId('p2'),
        round: 1,
        faction: Faction.village,
      ),
    );
    // Only the faction: the everyday clothes.
    expect(
      tester.widget<TurningFigure>(find.byType(TurningFigure)).asset,
      personaAsset(Persona.baker),
    );
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.byType(TurningFigure), findsNothing);
  });
}
