// Renders every screen of a real game (in-memory host, bots at the table)
// to PNG files, for design reviews and the website's phone screens.
//
//   SCREENSHOTS=/some/dir flutter test test/screens_test.dart
//
// Without SCREENSHOTS the test is skipped, so CI does not write files.
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:game_core/game_core.dart';
import 'package:game_host/game_host.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';

final String? _out = Platform.environment['SCREENSHOTS'];
const _size = Size(390, 844);

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final file in files) {
    final bytes = File(file).readAsBytesSync();
    loader.addFont(Future.value(ByteData.sublistView(bytes)));
  }
  await loader.load();
}

/// Material icons ship with Flutter, next to the test runner's engine.
String get _flutterFonts {
  final artifacts = File(Platform.resolvedExecutable).parent.parent.parent;
  return '${artifacts.path}/material_fonts';
}

/// Whatever the platform plugins would answer: nothing.
void _silencePlugins() {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  const wakelock = 'dev.flutter.pigeon.wakelock_plus_platform_interface';
  for (final channel in [
    '$wakelock.WakelockPlusApi.toggle',
    'plugins.it_nomads.com/flutter_secure_storage',
  ]) {
    messenger.setMockMessageHandler(
      channel,
      (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
    );
  }
}

class _Shooter {
  _Shooter(this.tester, this.locale);

  final WidgetTester tester;
  final String locale;
  final GlobalKey _boundary = GlobalKey();

  Widget frame(Widget child) => RepaintBoundary(
    key: _boundary,
    child: MediaQuery(
      data: const MediaQueryData(size: _size, disableAnimations: true),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        locale: Locale(locale),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: const [Locale('en'), Locale('de')],
        home: child,
      ),
    ),
  );

  Future<void> shoot(String name) async {
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/$locale-$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}

Future<void> _precache(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final dir in ['brand', 'figures', 'sheep']) {
      for (final file in Directory('assets/$dir').listSync()) {
        if (file is! File) continue;
        await precacheImage(AssetImage(file.path), context);
      }
    }
  });
}

/// One game: "you" plus five bots that act on what they see.
class _Table {
  _Table(int seed)
    : host = GameHost(
        roomCode: '1234',
        random: Random(seed),
        startTimer: (_, _) => () {},
      ) {
    host.serve(lan);
    you = GameSession(name: 'Mira', roomCode: '1234', dial: _dialYou);
    for (final (i, name) in ['Ole', 'Lena', 'Tarek', 'Ines', 'Jon'].indexed) {
      final link = PlayerLink(
        name: name,
        roomCode: '1234',
        dial: () async => i == 0 ? host.connectOwner() : lan.connect(),
      );
      bots.add(link);
    }
  }

  final GameHost host;
  final lan = MemoryTransport();
  late final GameSession you;
  final bots = <PlayerLink>[];
  Connection? _yours;
  bool hostAway = false;

  Future<Connection> _dialYou() async {
    if (hostAway) throw StateError('host away');
    return _yours = lan.connect();
  }

  /// The host disappears for "you": the calm pause shows.
  Future<void> leaveHost() async {
    hostAway = true;
    await _yours?.close();
  }

  PlayerLink get owner => bots.first;

  /// Every bot does what its phase asks; [you] only when [withYou].
  void playRound({bool withYou = false}) {
    final links = [...bots];
    for (final link in links) {
      _act(link.view, link.send, isOwner: link.isOwner);
    }
    if (withYou) _act(you.view, you.send);
  }

  void _act(
    PlayerView? v,
    bool Function(ClientMessage) send, {
    bool isOwner = false,
  }) {
    if (v == null) return;
    final me = v.yourSeat;
    final others = v.seats.where((s) => s.isAlive && s.id != v.you).toList();
    switch (v.phase) {
      case Phase.roleReveal:
        send(const ConfirmRoleIntent());
      case Phase.night when me.isAlive:
        final targets = v.yourRole == Role.werewolf
            ? others.where((s) => s.role != Role.werewolf).toList()
            : others;
        send(SheepIntent(v.yourFlock ?? 0));
        send(NightIntent(targets.first.id));
      case Phase.day when isOwner:
        send(const EndDiscussionIntent());
      case Phase.vote when me.isAlive:
        send(VoteIntent(others.last.id));
      case Phase.lobby ||
          Phase.night ||
          Phase.day ||
          Phase.vote ||
          Phase.hunterShot:
      case Phase.ended:
        break;
    }
  }

  /// Closes the table; the game screen already disposed [you].
  Future<void> close() async {
    for (final b in bots) {
      b.close();
    }
    await host.close();
  }
}

void main() {
  setUpAll(() async {
    if (_out == null) return;
    // Real time, before any widget asks for it inside the fake clock.
    await Grain.load();
    await _loadFont('LilitaOne', ['assets/fonts/LilitaOne-Regular.ttf']);
    await _loadFont('Manrope', [
      'assets/fonts/Manrope-Regular.ttf',
      'assets/fonts/Manrope-SemiBold.ttf',
      'assets/fonts/Manrope-ExtraBold.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '$_flutterFonts/MaterialIcons-Regular.otf',
    ]);
  });

  for (final locale in ['de', 'en']) {
    testWidgets('screens ($locale)', skip: _out == null, (tester) async {
      _silencePlugins();
      await tester.binding.setSurfaceSize(_size);
      final shot = _Shooter(tester, locale);

      await tester.pumpWidget(shot.frame(const StartScreen(version: '0.1')));
      await _precache(tester);
      await shot.shoot('01-start');

      // Find a seed per role, so every night screen gets a picture.
      final wanted = {Role.villager, Role.werewolf, Role.seer};
      for (var seed = 1; wanted.isNotEmpty && seed < 40; seed++) {
        final table = _Table(seed);
        await tester.pumpWidget(shot.frame(GameScreen(session: table.you)));
        await tester.pump();
        final first = seed == 1;
        if (first) await shot.shoot('02-lobby');
        table.owner.send(const StartGameIntent());
        await tester.pump();
        final role = table.you.view!.yourRole!;
        if (!wanted.remove(role)) {
          await tester.pumpWidget(const SizedBox());
          await table.close();
          continue;
        }
        if (first) await shot.shoot('03-role-hidden');
        table.playRound(withYou: true);
        await tester.pump();
        await shot.shoot('04-night-${role.name}');
        if (first) {
          table.playRound(withYou: true);
          await tester.pump();
          await shot.shoot('05-day');
          table.playRound();
          await tester.pump();
          await shot.shoot('06-vote');
          for (var i = 0; i < 12 && table.you.view!.phase != Phase.ended; i++) {
            table.playRound(withYou: true);
            await tester.pump();
          }
          await shot.shoot('07-${table.you.view!.phase.name}');
          await table.leaveHost();
          await tester.pump(const Duration(seconds: 2));
          await shot.shoot('08-pause');
        }
        await tester.pumpWidget(const SizedBox());
        await table.close();
      }
    });
  }
}
