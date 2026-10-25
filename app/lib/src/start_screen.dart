import 'package:flutter/material.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/join_screen.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/hosted_room.dart';
import 'package:whowolf/src/theme.dart';

/// First screen: the wordmark, your name, open or join a room.
class StartScreen extends StatefulWidget {
  const StartScreen({required this.version, super.key});

  final String version;

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  final _name = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _checkedName() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = AppLocalizations.of(context).nameRequired);
      return null;
    }
    setState(() => _error = null);
    return name;
  }

  Future<void> _open() async {
    final name = _checkedName();
    if (name == null || _busy) return;
    setState(() => _busy = true);
    final l10n = AppLocalizations.of(context);
    try {
      final room = await HostedRoom.open();
      final session = GameSession(
        name: name,
        roomCode: room.roomCode,
        dial: () async => room.host.connectOwner(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (_) => GameScreen(session: session, room: room),
        ),
      );
    } on Object {
      setState(() => _error = l10n.hostFailed);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _join() async {
    final name = _checkedName();
    if (name == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => JoinScreen(name: name)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/brand/wordmark.png',
                    semanticLabel: 'Whowolf',
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.tagline,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _name,
                    maxLength: 24,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: l10n.nameLabel,
                      errorText: _error,
                    ),
                    onSubmitted: (_) => _open(),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: l10n.createRoom,
                    onPressed: _busy ? null : _open,
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Palette.moon100,
                        side: const BorderSide(
                          color: Palette.lantern400,
                          width: 2,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      onPressed: _join,
                      child: Text(l10n.joinRoom),
                    ),
                  ),
                  const SizedBox(height: 28),
                  _Stamp(label: l10n.devStamp(widget.version)),
                  const SizedBox(height: 12),
                  Body(l10n.testNote, muted: true),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Stamp extends StatelessWidget {
  const _Stamp({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.05,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: Palette.lantern400, width: 2),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: displayFont,
              fontSize: 18,
              color: Palette.lantern400,
            ),
          ),
        ),
      ),
    );
  }
}
