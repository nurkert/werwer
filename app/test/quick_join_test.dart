import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/quick_join.dart';
import 'package:whowolf/src/theme.dart';

NearbyRoom _room(String code, String host, {bool locked = false}) => NearbyRoom(
  id: 'Whowolf $code',
  hostName: host,
  room: code,
  lan: const LanAddress('192.168.1.2', 4747),
  locked: locked,
);

void main() {
  final rooms = [
    _room('1111', 'Ada', locked: true),
    _room('2222', 'Bo'),
    _room('3333', 'Cem', locked: true),
  ];

  Future<void> pump(
    WidgetTester tester, {
    ResumeInfo? resume,
    String? lastRoom,
    ValueChanged<NearbyRoom>? onJoin,
    ValueChanged<ResumeInfo>? onResume,
  }) => tester.pumpWidget(
    MaterialApp(
      theme: buildTheme(),
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: const [Locale('en'), Locale('de')],
      home: Scaffold(
        body: QuickJoinButtons(
          rooms: rooms,
          lastRoom: lastRoom,
          resume: resume,
          onJoin: onJoin ?? (_) {},
          onResume: onResume ?? (_) {},
        ),
      ),
    ),
  );

  testWidgets('locked rooms stay out of the quick buttons', (tester) async {
    await pump(tester);
    expect(find.textContaining('Bo'), findsOneWidget);
    expect(find.textContaining('Ada'), findsNothing);
    expect(find.textContaining('Cem'), findsNothing);
  });

  testWidgets('a locked room shows to whoever still holds a seat in it, '
      'and the tap comes back with that seat', (tester) async {
    const seat = ResumeInfo(name: 'Mira', room: '1111', token: 'abc');
    ResumeInfo? resumed;
    NearbyRoom? joined;
    await pump(
      tester,
      resume: seat,
      lastRoom: '1111',
      onJoin: (room) => joined = room,
      onResume: (info) => resumed = info,
    );
    expect(find.textContaining('Ada'), findsOneWidget);
    expect(find.textContaining('Cem'), findsNothing);
    await tester.tap(find.textContaining('Ada'));
    expect(resumed, seat);
    expect(joined, isNull, reason: 'never as a newcomer');
    await tester.tap(find.textContaining('Bo'));
    expect(joined?.room, '2222');
  });

  test('the last room comes first, two at most', () {
    final open = [_room('1', 'A'), _room('2', 'B'), _room('3', 'C')];
    expect(quickRooms(open, lastRoom: '3').map((r) => r.room), ['3', '1']);
  });
}
