import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/atmosphere.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/browser_socket_stub.dart'
    if (dart.library.js_interop) 'package:whowolf/src/net/browser_socket.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/update_check.dart' show downloadPage;
import 'package:whowolf/src/privacy_screen.dart';
import 'package:whowolf/src/theme.dart';

/// The page the host's phone serves to browsers: a name, and you are at
/// the table. The QR code's link carries the room and its key; the key
/// proves the host in the encrypted handshake, like in the app.
class WebJoinScreen extends StatefulWidget {
  const WebJoinScreen({super.key});

  @override
  State<WebJoinScreen> createState() => _WebJoinScreenState();
}

class _WebJoinScreenState extends State<WebJoinScreen> {
  /// The note that the app does more was closed.
  bool _appHintClosed = false;

  /// Where a phone gets the app, if it is a phone that can: the download
  /// page for Android for now (later its store), nothing yet on iOS (until
  /// TestFlight or the App Store) or on a computer.
  static Uri? _appStore() => switch (defaultTargetPlatform) {
    TargetPlatform.android => androidAppUrl,
    TargetPlatform.iOS => iosAppUrl,
    _ => null,
  };

  // Read once; the address bar forgets it. After a reload (phones throw
  // away background tabs) this tab's kept game brings it back; a second
  // scan of the same room finds it too, with the session token: the player
  // goes back to their seat instead of taking a new one.
  static final KeptGame? _game = () {
    final link = JoinLink.tryParse(Uri.base.toString());
    if (link == null) return recallGame();
    forgetPageLink();
    return recallGame(link) ?? (link: link, token: null, name: null);
  }();

  final _name = TextEditingController();
  String? _error;

  /// The seat kept from before; dropped when the player joins as someone
  /// else.
  String? _token = _game?.token;

  @override
  void initState() {
    super.initState();
    _name.text = _game?.name ?? '';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  // Always one tap to sit down, also when coming back: browsers only allow
  // sound and keeping the screen on after the player touched the page.
  Future<void> _join(JoinLink link) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    final token = _token;
    if (name.isEmpty && token == null) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    setState(() => _error = null);
    // Played inside the tap, so the browser lets this page make sound.
    AudioSounds().play(Sound.tap);
    rememberGame(link, token: token, name: name);
    final session = GameSession(
      name: name,
      roomCode: link.room,
      token: token,
      seat: token == null ? link.seat : null,
      onWelcome: (token, name) {
        _token = token;
        rememberGame(link, token: token, name: name);
      },
      onEnded: () => forgetGame(link),
      dial: () async => connectSecure(
        await dialPage(link),
        hostKey: link.hostKey,
        roomSecret: link.roomSecret,
      ),
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final link = _game?.link;
    return StageScaffold(
      floatingAppBar: true,
      appBar: AppBar(),
      body: StageScroll(
        maxWidth: 440,
        horizontal: 28,
        child: Column(
          children: [
            Image.asset(
              'assets/brand/wordmark.png',
              semanticLabel: 'Whowolf',
              height: 120,
            ),
            const SizedBox(height: 12),
            const ExcludeSemantics(
              child: TurningFigure(
                asset: 'assets/figures/magd.webp',
                height: 140,
              ),
            ),
            const SizedBox(height: 16),
            Headline(l10n.webJoinTitle, size: 30),
            const SizedBox(height: 10),
            if (_appStore() case final store? when !_appHintClosed) ...[
              _AppHint(
                onGet: () => unawaited(
                  launchUrl(store, mode: LaunchMode.externalApplication),
                ),
                onClose: () => setState(() => _appHintClosed = true),
              ),
              const SizedBox(height: 14),
            ],
            if (link == null)
              Body(l10n.webJoinNoLink)
            else if (_token != null) ...[
              Body(l10n.webJoinBack),
              const SizedBox(height: 20),
              PrimaryButton(
                label: l10n.webJoinContinue(_name.text),
                onPressed: () => _join(link),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _token = null;
                  _name.clear();
                }),
                child: Text(l10n.webJoinSomeoneElse),
              ),
            ] else ...[
              Body(l10n.webJoinHint),
              const SizedBox(height: 20),
              TextField(
                controller: _name,
                maxLength: 24,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: l10n.nameLabel,
                  errorText: _error,
                ),
                onSubmitted: (_) => _join(link),
              ),
              const SizedBox(height: 12),
              PrimaryButton(
                label: l10n.webJoinButton,
                onPressed: () => _join(link),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              l10n.webJoinScreenOn,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.moon200, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.webJoinPrivacy,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.moon200, fontSize: 13),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const PrivacyScreen()),
              ),
              child: Text(l10n.privacy),
            ),
            Text(
              l10n.webJoinApp,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Palette.moon200, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where Android phones get the app (the store's page once there is one).
final Uri androidAppUrl = downloadPage;

/// Where iPhones get the app: none until TestFlight or the App Store.
const Uri? iosAppUrl = null;

/// A small note on the join page: the app does more (sound, the screen
/// stays on, coming back is easier). One can close it and play on here.
class _AppHint extends StatelessWidget {
  const _AppHint({required this.onGet, required this.onClose});

  final VoidCallback onGet;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          const Icon(Icons.install_mobile_rounded, color: Palette.lantern400),
          const SizedBox(width: 12),
          Expanded(child: Body(l10n.webAppHint)),
          TextButton(onPressed: onGet, child: Text(l10n.webAppGet)),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
