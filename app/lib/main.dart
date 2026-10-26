import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:whowolf/src/app.dart';

void main() {
  LicenseRegistry.addLicense(_fontLicenses);
  runApp(const WhowolfApp());
}

/// The bundled fonts are SIL OFL: their licence travels with the app.
Stream<LicenseEntry> _fontLicenses() async* {
  for (final font in ['LilitaOne', 'Manrope']) {
    final text = await rootBundle.loadString('assets/licenses/$font-OFL.txt');
    yield LicenseEntryWithLineBreaks([font], text);
  }
}
