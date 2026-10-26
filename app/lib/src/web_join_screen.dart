import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:secure_channel/secure_channel.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/stage.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';
import 'package:whowolf/src/net/browser_socket_stub.dart'
    if (dart.library.js_interop) 'package:whowolf/src/net/browser_socket.dart';
import 'package:whowolf/src/net/game_session.dart';
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
  // Read once; the address bar forgets it. After a reload (phones throw
  // away background tabs) the tab's own storage brings it back, with the
  // session token: the player is back at their seat.
  static final ({JoinLink link, String? token, String? name})? _game = () {
    final link = JoinLink.tryParse(Uri.base.toString());
    if (link != null) {
      forgetPageLink();
      return (link: link, token: null, name: null);
    }
    final kept = recallGame();
    final keptLink = kept == null ? null : JoinLink.tryParse(kept.link);
    if (kept == null || keptLink == null) return null;
    return (link: keptLink, token: kept.token, name: kept.name);
  }();

  final _name = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    final game = _game;
    _name.text = game?.name ?? '';
    // Seated before the reload: straight back in.
    if (game?.token case final token?) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => _join(game!.link, token: token),
      );
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _join(JoinLink link, {String? token}) async {
    final l10n = AppLocalizations.of(context);
    final name = _name.text.trim();
    if (name.isEmpty && token == null) {
      setState(() => _error = l10n.nameRequired);
      return;
    }
    setState(() => _error = null);
    final text = link.encodeLocal() ?? link.encode();
    rememberGame(text, token: token, name: name);
    final session = GameSession(
      name: name,
      roomCode: link.room,
      token: token,
      onWelcome: (token, name) => rememberGame(text, token: token, name: name),
      onEnded: forgetGame,
      dial: () async => connectSecure(
        await dialPageHost(),
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
            if (link == null)
              Body(l10n.webJoinNoLink)
            else ...[
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
