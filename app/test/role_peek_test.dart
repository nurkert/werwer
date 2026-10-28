import 'dart:math';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/role_peek.dart';
import 'package:whowolf/src/game/widgets.dart';

void main() {
  testWidgets('the role shows only while the button is held', (tester) async {
    var state = GameState.lobby();
    for (var i = 0; i < 4; i++) {
      state = apply(state, AddPlayer(PlayerId('p$i'), 'N$i')).state;
    }
    state = apply(state, StartGame(random: Random(1))).state;
    final view = viewFor(state, const PlayerId('p0'));
    final role = view.yourRole!;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(child: RolePeek(view: view)),
        ),
      ),
    );
    final l10n = AppLocalizations.of(tester.element(find.byType(RolePeek)));
    expect(find.text(l10n.role(role)), findsNothing);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(RolePeek)),
    );
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));
    expect(find.text(l10n.role(role)), findsOneWidget);

    await gesture.up();
    await tester.pump();
    expect(find.text(l10n.role(role)), findsNothing);
  });
}
