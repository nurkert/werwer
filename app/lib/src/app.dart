import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';
import 'package:whowolf/src/web_join_screen.dart';

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
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      // In the browser the page comes from a host's phone: join it.
      home: kIsWeb
          ? const WebJoinScreen()
          : const StartScreen(version: appVersion),
    );
  }
}
