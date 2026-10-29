import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/stage/motion.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  await _phonesUpright();
  const store = Store();
  final language = await store.language();
  if (language != null) appLanguage.value = Locale(language);
  // The very first start picks a fitting stage once and keeps it like a
  // choice; whatever the player picks later stays.
  final motion = await store.stageMotion();
  if (motion == null) {
    final first = initialStageMotion(
      web: kIsWeb,
      reduceMotion:
          PlatformDispatcher.instance.accessibilityFeatures.disableAnimations,
    );
    stageMotion.value = first;
    await store.setStageMotion(first);
  } else {
    stageMotion.value = motion;
  }
  runApp(const WhowolfApp());
}

/// Phones play upright only (tablets and desktops turn freely): iOS says
/// so in its Info.plist for the iPhone, Android cannot tell phone from
/// tablet there, so the app asks at start.
Future<void> _phonesUpright() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
  final view = PlatformDispatcher.instance.views.firstOrNull;
  if (view == null) return;
  final size = view.physicalSize / view.devicePixelRatio;
  if (size.shortestSide < 600) {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }
}

/// The bundled fonts are SIL OFL: their licence travels with the app.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final font in ['AncizarSerif', 'Manrope']) {
    final text = await rootBundle.loadString('assets/licenses/$font-OFL.txt');
    yield LicenseEntryWithLineBreaks([font], text);
  }
}
