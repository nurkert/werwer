import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';

/// Build version, injected by CI via `--dart-define=APP_VERSION=0.0.x`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// Languages the app speaks; the first one is the fallback.
const supportedLocales = [Locale('en'), Locale('de')];

class WhowolfApp extends StatelessWidget {
  const WhowolfApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Whowolf',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      supportedLocales: supportedLocales,
      home: const StartScreen(version: appVersion),
    );
  }
}
