import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/lobby_invite.dart';
import 'package:whowolf/src/theme.dart';

/// The invitation shows the room's door code beside the server's QR code,
/// and the new one when it changes (task 022).
void main() {
  const link = JoinLink(
    room: '1234',
    relayRoom: 'abcd2345',
    lan: LanAddress('192.168.1.5', 47470),
  );

  Widget invite({
    required StreamController<String?> codes,
    bool browserCanJoin = true,
    String? page = 'play.example.org',
  }) => MaterialApp(
    theme: buildTheme(),
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: SingleChildScrollView(
        child: LobbyInvite(
          link: link,
          qr: 'https://play.example.org/v/12/0.3.0/join?room=1234&relay=abcd2345#k=x',
          browserCanJoin: browserCanJoin,
          doorPage: page,
          doorCode: 'abc234',
          doorCodes: codes.stream,
        ),
      ),
    ),
  );

  Future<void> unfold(WidgetTester tester) async {
    await tester.tap(find.text('Invite players'));
    await tester.pumpAndSettle();
  }

  testWidgets('the door code shows and follows its rotation', (tester) async {
    final codes = StreamController<String?>.broadcast();
    addTearDown(() => unawaited(codes.close()));
    await tester.pumpWidget(invite(codes: codes));
    await unfold(tester);
    expect(find.text('ABC 234'), findsOneWidget);
    expect(find.textContaining('play.example.org'), findsOneWidget);

    codes.add('xyz789');
    await tester.pumpAndSettle();
    expect(find.text('XYZ 789'), findsOneWidget);
    expect(find.text('ABC 234'), findsNothing);

    // Expired without a new one: no code rather than a dead one.
    codes.add(null);
    await tester.pumpAndSettle();
    expect(find.text('XYZ 789'), findsNothing);
  });

  testWidgets('no door code without the server page', (tester) async {
    final codes = StreamController<String?>.broadcast();
    addTearDown(() => unawaited(codes.close()));
    await tester.pumpWidget(invite(codes: codes, page: null));
    await unfold(tester);
    expect(find.text('ABC 234'), findsNothing);
    await tester.pumpWidget(invite(codes: codes, browserCanJoin: false));
    await tester.pumpAndSettle();
    expect(find.text('ABC 234'), findsNothing);
  });
}
