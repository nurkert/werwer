import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/app.dart';
import 'package:whowolf/src/net/store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(_fontLicenses);
  final language = await const Store().language();
  if (language != null) appLanguage.value = Locale(language);
  runApp(const WhowolfApp());
}

/// The bundled fonts are SIL OFL: their licence travels with the app.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final font in ['AncizarSerif', 'LilitaOne', 'Manrope']) {
    final text = await rootBundle.loadString('assets/licenses/$font-OFL.txt');
    yield LicenseEntryWithLineBreaks([font], text);
  }
}
