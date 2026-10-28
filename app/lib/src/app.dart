import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/net/app_links.dart';
import 'package:whowolf/src/start_screen.dart';
import 'package:whowolf/src/theme.dart';
import 'package:whowolf/src/web_join_screen.dart';

/// Build version, injected by CI via `--dart-define=APP_VERSION=0.0.x`.
const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: 'dev');

/// Languages the app speaks; the first one is the fallback.
const supportedLocales = [Locale('en'), Locale('de')];

/// The language picked in the app, or `null` for the system's.
final appLanguage = ValueNotifier<Locale?>(null);

class WhowolfApp extends StatefulWidget {
  const WhowolfApp({super.key, this.home});

  /// The first screen; the start screen (or in the browser the join page)
  /// unless a test puts something simpler there.
  @visibleForTesting
  final Widget? home;

  @override
  State<WhowolfApp> createState() => _WhowolfAppState();
}

class _WhowolfAppState extends State<WhowolfApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// A room link while the app runs: handed to the start screen, never
  /// pushed as a route.
  @override
  Future<bool> didPushRouteInformation(RouteInformation info) async {
    final link = joinLinkFromRoute(info.uri.toString());
    if (link != null) incomingLink.value = link;
    return true;
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
    valueListenable: appLanguage,
    builder: (context, language, _) => _app(language),
  );

  Widget _app(Locale? language) {
    return MaterialApp(
      title: 'Whowolf',
      locale: language,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: supportedLocales,
      // In the browser the page comes from a host's phone: join it.
      // A room link that started the app goes to the start screen, which
      // asks before joining; there are no other routes.
      onGenerateInitialRoutes: (route) {
        final link = kIsWeb ? null : joinLinkFromRoute(route);
        if (link != null) incomingLink.value = link;
        return [_home(widget.home)];
      },
      onGenerateRoute: (_) => _home(widget.home),
    );
  }

  static Route<void> _home(Widget? home) => MaterialPageRoute<void>(
    builder: (_) =>
        home ??
        (kIsWeb
            ? const WebJoinScreen()
            : const StartScreen(version: appVersion)),
  );
}
