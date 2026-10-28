import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/phases.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

void main() {
  testWidgets('the host opens on the invitation, its QR code one tap away', (
    tester,
  ) async {
    // A phone: the lobby comes as pages to swipe.
    tester.view
      ..physicalSize = const Size(390, 844)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final host = GameHost(
      roomCode: '1234',
      random: Random(1),
      settings: const GameSettings(),
      startTimer: (_, _) => () {},
    );
    final owner = GameSession(
      name: 'Mira',
      roomCode: '1234',
      dial: () async => host.connectOwner(),
    );
    await tester.pump();
    const link = JoinLink(room: '1234', lan: LanAddress('192.168.1.2', 4747));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildTheme(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en'), Locale('de')],
        home: StageScaffold(
          body: LobbyPhase(session: owner, link: link, qr: link.encode()),
        ),
      ),
    );
    await tester.pump();
    // On the first page the host sees, without swiping: the invitation,
    // folded; one tap shows the QR code.
    expect(find.byType(QrImageView), findsNothing);
    await tester.tap(find.text('Invite players').hitTestable());
    // The stage keeps moving: pump the unfolding, not until still.
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(QrImageView), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    owner.dispose();
    await host.close();
  });
}
