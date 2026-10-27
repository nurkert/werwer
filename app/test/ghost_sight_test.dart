import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/game/ghost_sight.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  const ada = PlayerId('p1');
  const bo = PlayerId('p2');
  const cy = PlayerId('p3');
  PlayerView ghost({GhostSight sight = GhostSight.roles}) => PlayerView(
    you: ada,
    phase: Phase.day,
    round: 2,
    seats: const [
      SeatView(id: ada, name: 'Ada', isAlive: false, role: Role.villager),
      SeatView(id: bo, name: 'Bo', isAlive: true, role: Role.werewolf),
      SeatView(id: cy, name: 'Cy', isAlive: false, role: Role.seer),
    ],
    deaths: const [
      DeathView(player: ada, round: 1, cause: DeathCause.night),
      DeathView(
        player: cy,
        round: 1,
        cause: DeathCause.vote,
        role: Role.seer,
      ),
    ],
    waitingFor: 0,
    yourGhostSight: sight,
  );

  Widget host(Widget child) => MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: supportedLocales,
    theme: buildTheme(),
    home: Scaffold(body: child),
  );

  testWidgets('a ghost shows openly only what everyone knows', (tester) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    final view = ghost();
    String? open(PlayerId id) =>
        openRole(view, view.seats.firstWhere((s) => s.id == id), l10n);
    expect(open(ada), 'Villager');
    expect(open(cy), 'Seer');
    expect(open(bo), isNull, reason: 'the living wolf stays hidden');
  });

  testWidgets('the roles show only while a finger holds the ghost sight', (
    tester,
  ) async {
    await tester.pumpWidget(host(GhostPanel(view: ghost())));
    expect(find.textContaining('Bo: Werewolf'), findsNothing);
    final finger = await tester.startGesture(
      tester.getCenter(find.text('Ghost sight: press and hold')),
    );
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.textContaining('Bo: Werewolf'), findsOneWidget);
    await finger.up();
    await tester.pumpAndSettle();
    expect(find.textContaining('Bo: Werewolf'), findsNothing);
  });

  testWidgets('without ghost sight the dead only read that they are dead', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(GhostPanel(view: ghost(sight: GhostSight.off))),
    );
    expect(find.text('Ghost sight: press and hold'), findsNothing);
    expect(find.textContaining('dead'), findsOneWidget);
  });
}
