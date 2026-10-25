import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// Joining by the host's address and room code. A QR scanner replaces the
/// typing later; it will carry exactly these two values (plus a key).
class JoinScreen extends StatefulWidget {
  const JoinScreen({required this.name, super.key});

  final String name;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _address = TextEditingController();
  final _code = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    // Most tables share the first three parts of the address: prefill them.
    unawaited(
      privateAddresses().then((addresses) {
        if (!mounted || addresses.isEmpty || _address.text.isNotEmpty) return;
        final parts = addresses.first.address.split('.');
        _address.text = '${parts.take(3).join('.')}.';
      }),
    );
  }

  @override
  void dispose() {
    _address.dispose();
    _code.dispose();
    super.dispose();
  }

  /// `ip` or `ip:port`; only private IPv4 addresses are accepted.
  (String, int)? _parse(String input) {
    final parts = input.trim().split(':');
    if (parts.isEmpty || parts.length > 2) return null;
    final ip = parts.first;
    final port = parts.length == 2 ? int.tryParse(parts[1]) : defaultPort;
    final octets = ip.split('.').map(int.tryParse).toList();
    final valid =
        octets.length == 4 &&
        octets.every((o) => o != null && o >= 0 && o < 256);
    if (!valid || port == null || port <= 0 || port > 65535) return null;
    final a = octets[0]!;
    final b = octets[1]!;
    final private =
        a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
    return private ? (ip, port) : null;
  }

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final target = _parse(_address.text);
    final code = _code.text.trim();
    if (target == null || code.length != roomCodeLength) {
      setState(() => _error = l10n.connectFailed);
      return;
    }
    final (ip, port) = target;
    final session = GameSession(
      name: widget.name,
      roomCode: code,
      dial: () => dialHost(ip, port),
    );
    await Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.night900,
        foregroundColor: Palette.moon100,
        title: Text(l10n.joinTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                children: [
                  Body(l10n.joinHelp),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _address,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp('[0-9.:]')),
                    ],
                    decoration: InputDecoration(
                      labelText: l10n.hostAddress,
                      hintText: '192.168.1.23',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _code,
                    keyboardType: TextInputType.number,
                    maxLength: roomCodeLength,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(labelText: l10n.roomCode),
                    onSubmitted: (_) => _join(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _error!,
                      style: const TextStyle(color: Palette.curtain400),
                    ),
                  ],
                  const SizedBox(height: 24),
                  PrimaryButton(label: l10n.connect, onPressed: _join),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
