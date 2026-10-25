import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:game_host/lan.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/game_screen.dart';
import 'package:whowolf/src/game/help.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/dial.dart';
import 'package:whowolf/src/net/discovery.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/net/store.dart';
import 'package:whowolf/src/scan_screen.dart';
import 'package:whowolf/src/theme.dart';

/// A player session that remembers itself for a resume after a restart.
GameSession playerSession({
  required String name,
  required String room,
  LanAddress? lan,
  String? relayRoom,
  Uri? server,
  String? token,
}) {
  const store = Store();
  return GameSession(
    name: name,
    roomCode: room,
    token: token,
    dial: dialerFor(lan: lan, relayRoom: relayRoom, server: server),
    onWelcome: (token, name) => unawaited(
      store.saveResume(
        ResumeInfo(
          name: name,
          room: room,
          token: token,
          lan: lan,
          relayRoom: relayRoom,
          server: server,
        ),
      ),
    ),
    onEnded: () => unawaited(store.clearResume()),
  );
}

/// Opens the game screen for [session].
Future<void> playSession(BuildContext context, GameSession session) =>
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => GameScreen(session: session)),
    );

/// Joining: scan the host's QR code, or type the address (same Wi-Fi) or the
/// online code (through the relay server) plus the room code.
class JoinScreen extends StatefulWidget {
  const JoinScreen({required this.name, super.key});

  final String name;

  @override
  State<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends State<JoinScreen> {
  final _address = TextEditingController();
  final _online = TextEditingController();
  final _code = TextEditingController();
  bool _onlineMode = false;
  String? _error;
  final _finder = RoomFinder();

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
    _finder.dispose();
    _address.dispose();
    _online.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _scan() async {
    final link = await Navigator.push<JoinLink>(
      context,
      MaterialPageRoute(builder: (_) => const ScanScreen()),
    );
    if (link == null || !mounted) return;
    final l10n = AppLocalizations.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.joinConfirmTitle(link.room)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (link.lan != null)
              Text(l10n.joinConfirmLan(link.lan.toString())),
            if (link.server != null)
              Text(l10n.joinConfirmOnline(link.server!.host)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.connect),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !mounted) return;
    await playSession(
      context,
      playerSession(
        name: widget.name,
        room: link.room,
        lan: link.lan,
        relayRoom: link.relayRoom,
        server: link.server,
      ),
    );
  }

  Future<void> _joinNearby(NearbyRoom room) => playSession(
    context,
    playerSession(name: widget.name, room: room.room, lan: room.lan),
  );

  Future<void> _join() async {
    final l10n = AppLocalizations.of(context);
    final code = _code.text.trim();
    if (code.length != roomCodeLength) {
      setState(() => _error = l10n.connectFailed);
      return;
    }
    if (_onlineMode) {
      final relayRoom = _online.text.trim().toLowerCase();
      final server = await const Store().relayServer();
      if (!mounted) return;
      if (server == null) {
        setState(() => _error = l10n.noRelayServer);
        return;
      }
      if (!isRelayRoomId(relayRoom)) {
        setState(() => _error = l10n.connectFailed);
        return;
      }
      setState(() => _error = null);
      await playSession(
        context,
        playerSession(
          name: widget.name,
          room: code,
          relayRoom: relayRoom,
          server: server,
        ),
      );
      return;
    }
    final lan = LanAddress.tryParse(_address.text);
    if (lan == null) {
      setState(() => _error = l10n.connectFailed);
      return;
    }
    setState(() => _error = null);
    await playSession(
      context,
      playerSession(name: widget.name, room: code, lan: lan),
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
                  _Nearby(finder: _finder, onJoin: _joinNearby),
                  const HelpLink(),
                  const SizedBox(height: 12),
                  if (canScan) ...[
                    PrimaryButton(label: l10n.scanQr, onPressed: _scan),
                    const SizedBox(height: 12),
                  ],
                  // Typing addresses is the fallback, tucked away.
                  Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: EdgeInsets.zero,
                      iconColor: Palette.moon200,
                      collapsedIconColor: Palette.moon200,
                      title: Text(
                        l10n.manualJoin,
                        style: const TextStyle(color: Palette.moon200),
                      ),
                      children: [
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment(
                              value: false,
                              label: Text(l10n.joinLan),
                            ),
                            ButtonSegment(
                              value: true,
                              label: Text(l10n.joinOnline),
                            ),
                          ],
                          selected: {_onlineMode},
                          onSelectionChanged: (v) =>
                              setState(() => _onlineMode = v.first),
                        ),
                        const SizedBox(height: 12),
                        Body(l10n.joinHelp, muted: true),
                        const SizedBox(height: 12),
                        if (_onlineMode)
                          TextField(
                            controller: _online,
                            maxLength: relayRoomIdLength,
                            autocorrect: false,
                            decoration: InputDecoration(
                              labelText: l10n.onlineCode,
                            ),
                          )
                        else
                          TextField(
                            controller: _address,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp('[0-9.:]'),
                              ),
                            ],
                            decoration: InputDecoration(
                              labelText: l10n.hostAddress,
                              hintText: '192.168.1.23',
                            ),
                          ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _code,
                          keyboardType: TextInputType.number,
                          maxLength: roomCodeLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          decoration: InputDecoration(labelText: l10n.roomCode),
                          onSubmitted: (_) => _join(),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Palette.curtain400),
                          ),
                        ],
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _join,
                          child: Text(l10n.connect),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Rooms found on the local network, one tap to join.
class _Nearby extends StatelessWidget {
  const _Nearby({required this.finder, required this.onJoin});

  final RoomFinder finder;
  final void Function(NearbyRoom room) onJoin;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return ListenableBuilder(
      listenable: finder,
      builder: (context, _) {
        final rooms = finder.rooms;
        return Column(
          children: [
            Headline(l10n.nearbyTitle),
            const SizedBox(height: 12),
            if (rooms.isEmpty)
              Panel(
                child: Row(
                  children: [
                    if (!finder.unavailable) ...[
                      const SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Text(
                        finder.unavailable ? l10n.noDiscovery : l10n.searching,
                        style: const TextStyle(color: Palette.moon200),
                      ),
                    ),
                  ],
                ),
              ),
            for (final room in rooms)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Material(
                  color: Palette.night700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                    side: const BorderSide(color: Palette.lantern400, width: 2),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.nightlight_round,
                      color: Palette.lantern400,
                    ),
                    title: Text(
                      room.hostName.isEmpty
                          ? 'Whowolf'
                          : l10n.roomOf(room.hostName),
                      style: const TextStyle(
                        color: Palette.moon100,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    trailing: Text(
                      l10n.connect,
                      style: const TextStyle(
                        color: Palette.lantern400,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    onTap: () => onJoin(room),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
