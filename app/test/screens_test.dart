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
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/walking_narrator.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';

final String? _out = Platform.environment['SCREENSHOTS'];

/// Screens are pictures: no sound.
class _Silence implements Sounds {
  const _Silence();

  @override
  void play(Sound sound) {}

  @override
  void stopAll() {}
}

const _silence = _Silence();

/// The narrator's recordings: no audio in a picture.
class _SilentClip implements ClipPlayer {
  @override
  Future<void> prepare(String asset, double volume) async {}

  @override
  void start() {}

  @override
  void volume(double volume) {}

  @override
  void stop() {}
}

/// Every device class the layout serves: the phone shots land in the
/// folder itself (the website uses them), the others in a subfolder.
/// `SCREEN_SIZE=1280x800` renders only that size.
final Map<String, Size> _sizes = () {
  final only = Platform.environment['SCREEN_SIZE'];
  if (only != null) {
    final parts = only.split('x');
    return {'': Size(double.parse(parts[0]), double.parse(parts[1]))};
  }
  return const {
    '': Size(390, 844),
    'tablet': Size(820, 1180),
    'desktop': Size(1280, 800),
  };
}();

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
  messenger
    ..setMockMessageHandler(
      '$wakelock.WakelockPlusApi.toggle',
      (_) async => const StandardMessageCodec().encodeMessage(<Object?>[null]),
    )
    // A device that has seen the privacy notice already, nothing else
    // saved.
    ..setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      (call) async =>
          call.method == 'read' &&
              (call.arguments as Map<Object?, Object?>)['key'] ==
                  'privacyNoticeSeen'
          ? '1'
          : null,
    );
}

class _Shooter {
  _Shooter(this.tester, this.locale, this.size, this.folder);

  final WidgetTester tester;
  final String locale;
  final Size size;
  final String folder;
  final GlobalKey _boundary = GlobalKey();

  Widget frame(Widget child) => RepaintBoundary(
    key: _boundary,
    child: MediaQuery(
      data: MediaQueryData(
        size: size,
        disableAnimations: true,
        // `TEXT_SCALE=2` checks the screens with the system's largest text.
        textScaler: TextScaler.linear(
          double.tryParse(Platform.environment['TEXT_SCALE'] ?? '') ?? 1,
        ),
      ),
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
    // Let images on the screen decode (figures, costumes, poses).
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 600)),
    );
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(seconds: 1));
    final boundary =
        _boundary.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    await tester.runAsync(() async {
      // `PIXEL_RATIO=3` with `SCREEN_SIZE=430x932` gives App Store size.
      final ratio =
          double.tryParse(Platform.environment['PIXEL_RATIO'] ?? '') ?? 2;
      final image = await boundary.toImage(pixelRatio: ratio);
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('$_out/${folder.isEmpty ? '' : '$folder/'}$locale-$name.png')
        ..createSync(recursive: true)
        ..writeAsBytesSync(png!.buffer.asUint8List());
    });
  }
}

Future<void> _precache(WidgetTester tester) async {
  final context = tester.element(find.byType(Scaffold).first);
  await tester.runAsync(() async {
    for (final dir in [
      'brand',
      'figures',
      'figures/roles',
      'figures/poses',
      'sheep',
      'stage',
      'stage/scenery',
    ]) {
      for (final file in Directory('assets/$dir').listSync()) {
        if (file is! File) continue;
        await precacheImage(AssetImage(file.path), context);
      }
    }
  });
}

/// One game: "you" plus five bots that act on what they see.
class _Table {
  /// [youOwn]: "you" opened the room (and see its settings button).
  _Table(int seed, {this.youOwn = false})
    : host = GameHost(
        // Whowolf's night, for the sheep and door sign screens.
        settings: const GameSettings(),
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
        dial: () async =>
            i == 0 && !youOwn ? host.connectOwner() : lan.connect(),
      );
      bots.add(link);
    }
  }

  final GameHost host;
  final bool youOwn;
  final lan = MemoryTransport();
  late final GameSession you;
  final bots = <PlayerLink>[];
  Connection? _yours;
  bool hostAway = false;

  Future<Connection> _dialYou() async {
    if (hostAway) throw StateError('host away');
    return _yours = youOwn ? host.connectOwner() : lan.connect();
  }

  /// The host disappears for "you": the calm pause shows.
  Future<void> leaveHost() async {
    hostAway = true;
    await _yours?.close();
  }

  /// Sends as the room's owner, whoever that is at this table.
  void ownerSends(ClientMessage intent) =>
      youOwn ? you.send(intent) : bots.first.send(intent);

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
      case Phase.night when me.isAlive && !v.youActed:
        final first = others.first.id;
        switch (v.yourNightTask) {
          case NightAbility.link:
            send(NightIntent.of([v.you, first]));
          case NightAbility.brew:
            send(NightIntent.of(const []));
          case NightAbility.hunt:
            final prey = others.where((s) => s.role != Role.werewolf);
            send(NightIntent(prey.first.id));
          case NightAbility.inspect || NightAbility.decoy:
            send(NightIntent(first));
          case null:
            // Eyes closed: not called in this step.
            break;
        }
      case Phase.hunterShot when v.shooter == v.you:
        send(ShootIntent(others.first.id));
      case Phase.day when isOwner:
        send(const EndDiscussionIntent());
      case Phase.vote when me.isAlive:
        send(VoteIntent(others.last.id));
      case Phase.lobby ||
          Phase.night ||
          Phase.day ||
          Phase.vote ||
          Phase.hunterShot ||
          Phase.ended:
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
    await _loadFont('AncizarSerif', [
      'assets/fonts/AncizarSerif-Variable.ttf',
      'assets/fonts/AncizarSerif-Italic-Variable.ttf',
    ]);
    await _loadFont('Manrope', [
      'assets/fonts/Manrope-Regular.ttf',
      'assets/fonts/Manrope-SemiBold.ttf',
      'assets/fonts/Manrope-ExtraBold.ttf',
    ]);
    await _loadFont('MaterialIcons', [
      '$_flutterFonts/MaterialIcons-Regular.otf',
    ]);
  });

  for (final MapEntry(key: folder, value: size) in _sizes.entries) {
    for (final locale in ['de', 'en']) {
      testWidgets(
        'screens ($locale${folder.isEmpty ? '' : ', $folder'})',
        skip: _out == null,
        (tester) async {
          _silencePlugins();
          await tester.binding.setSurfaceSize(size);
          final shot = _Shooter(tester, locale, size, folder);

          await tester.pumpWidget(
            shot.frame(const StartScreen(version: '0.1')),
          );
          await _precache(tester);
          await shot.shoot('01-start');
          // The start screen's other pages, swiped to like a home screen.
          if (find.byType(PageView).evaluate().isNotEmpty) {
            for (final (page, dx) in [
              ('how', 500.0),
              ('play', -500.0),
              ('settings', -500.0),
            ]) {
              await tester.drag(find.byType(PageView), Offset(dx, 0));
              await tester.pumpAndSettle();
              if (page != 'play') await shot.shoot('01-start-$page');
            }
          }

          // Find a seed per role, so every night screen gets a picture.
          final wanted = {Role.villager, Role.werewolf, Role.seer};
          for (var seed = 1; wanted.isNotEmpty && seed < 40; seed++) {
            final table = _Table(seed);
            await tester.pumpWidget(
              shot.frame(
                GameScreen(
                  session: table.you,
                  sounds: _silence,
                  clips: _SilentClip.new,
                ),
              ),
            );
            await tester.pump();
            final first = seed == 1;
            if (first) {
              await tester.runAsync(
                () => Future<void>.delayed(const Duration(seconds: 2)),
              );
              await shot.shoot('02-lobby');
              if (find.byType(PageView).evaluate().isNotEmpty) {
                for (final page in ['table', 'game']) {
                  await tester.drag(
                    find.byType(PageView),
                    const Offset(-500, 0),
                  );
                  await tester.pumpAndSettle();
                  await shot.shoot('02-lobby-$page');
                }
              }
            }
            table.ownerSends(const StartGameIntent());
            await tester.pump();
            final role = table.you.view!.yourRole!;
            if (!wanted.remove(role)) {
              await tester.pumpWidget(const SizedBox());
              await table.close();
              continue;
            }
            if (first) {
              await shot.shoot('03-role-hidden');
              await tester.tap(find.byType(TurningFigure));
              await tester.pump(const Duration(seconds: 1));
              await shot.shoot('03-role-shown');
            }
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
              for (
                var i = 0;
                i < 12 && table.you.view!.phase != Phase.ended;
                i++
              ) {
                table.playRound(withYou: true);
                await tester.pump();
              }
              await shot.shoot('07-${table.you.view!.phase.name}');
              await table.leaveHost();
              // The pause only shows after a grace period.
              await tester.pump(const Duration(seconds: 9));
              await shot.shoot('08-pause');
            }
            await tester.pumpWidget(const SizedBox());
            await table.close();
          }

          // The host's settings in the lobby.
          final host = _Table(1, youOwn: true);
          await tester.pumpWidget(
            shot.frame(
              GameScreen(
                session: host.you,
                sounds: _silence,
                clips: _SilentClip.new,
              ),
            ),
          );
          await tester.pump();
          // The host opens on the invitation.
          await shot.shoot('09-host-lobby');
          final l10n = await AppLocalizations.delegate.load(Locale(locale));
          // On a phone the settings are the lobby's last page; on wider
          // windows they sit in the lobby itself.
          for (
            var i = 0;
            i < 3 &&
                find.text(l10n.settingsRoles).hitTestable().evaluate().isEmpty;
            i++
          ) {
            if (find.byType(PageView).evaluate().isEmpty) break;
            await tester.drag(find.byType(PageView), const Offset(-500, 0));
            await tester.pumpAndSettle();
          }
          await tester.pump(const Duration(milliseconds: 400));
          await shot.shoot('09-settings');
          await tester.pumpWidget(const SizedBox());
          await host.close();

          // Every role on the full stage: cupid's pick, the witch's table, the
          // hunter's moment and the lovers' note, from whichever seed shows it.
          final missing = {'cupid', 'witch', 'hunter', 'lovers'};
          for (var seed = 1; missing.isNotEmpty && seed < 60; seed++) {
            final table = _Table(seed);
            await tester.pumpWidget(
              shot.frame(
                GameScreen(
                  session: table.you,
                  sounds: _silence,
                  clips: _SilentClip.new,
                ),
              ),
            );
            await tester.pump();
            table.ownerSends(SettingsIntent(Preset.fullStage.settings));
            await tester.pump();
            table.ownerSends(const StartGameIntent());
            await tester.pump();
            for (var i = 0; i < 40; i++) {
              final v = table.you.view!;
              if (v.phase == Phase.ended) break;
              final night = v.phase == Phase.night && v.yourSeat.isAlive;
              final task = v.yourNightTask;
              String? scene;
              if (night && task == NightAbility.link && !v.youActed) {
                scene = 'cupid';
              } else if (night && task == NightAbility.brew && !v.youActed) {
                scene = 'witch';
              } else if (v.phase == Phase.hunterShot) {
                scene = 'hunter';
              } else if (v.phase == Phase.day && v.partner != null) {
                scene = 'lovers';
              }
              if (scene != null && missing.remove(scene)) {
                await shot.shoot('10-$scene');
              }
              table.playRound(withYou: true);
              await tester.pump();
            }
            await tester.pumpWidget(const SizedBox());
            await table.close();
          }

          // The classic night: eyes closed, and the moment you are called.
          final classic = {'eyes', 'called'};
          for (var seed = 1; classic.isNotEmpty && seed < 40; seed++) {
            final table = _Table(seed);
            await tester.pumpWidget(
              shot.frame(
                GameScreen(
                  session: table.you,
                  sounds: _silence,
                  clips: _SilentClip.new,
                ),
              ),
            );
            await tester.pump();
            table.ownerSends(SettingsIntent(Preset.classic.settings));
            await tester.pump();
            table.ownerSends(const StartGameIntent());
            await tester.pump();
            for (var i = 0; i < 20; i++) {
              final v = table.you.view!;
              if (v.phase == Phase.ended) break;
              if (v.phase == Phase.night && v.yourSeat.isAlive) {
                final scene = v.yourNightTask == null ? 'eyes' : 'called';
                if (!v.youActed && classic.remove(scene)) {
                  await shot.shoot('11-classic-$scene');
                }
              }
              table.playRound(withYou: true);
              await tester.pump();
            }
            await tester.pumpWidget(const SizedBox());
            await table.close();
          }
        },
      );
    }
  }
}
