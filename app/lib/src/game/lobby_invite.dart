import 'dart:async';

import 'package:flutter/material.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

class LobbyInvite extends StatefulWidget {
  const LobbyInvite({
    required this.link,
    required this.qr,
    super.key,
    this.browserCanJoin = false,
    this.onShowCode,
    this.onLocalCode,
  });

  final JoinLink link;
  final String qr;
  final bool browserCanJoin;
  final Future<void> Function()? onShowCode;
  final VoidCallback? onLocalCode;

  @override
  State<LobbyInvite> createState() => _LobbyInviteState();
}

class _LobbyInviteState extends State<LobbyInvite> {
  bool _opening = false;

  /// Folded by default: the table fills up through "Join a room" on the
  /// same Wi-Fi; the code (and with it the server) only when asked for.
  bool _open = false;

  Future<void> _unfold() async {
    setState(() => _open = true);
    final show = widget.onShowCode;
    if (show == null) return;
    setState(() => _opening = true);
    try {
      await show();
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  Future<void> _explain() {
    final l10n = AppLocalizations.of(context);
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.inviteInfoTitle),
        content: Text(l10n.inviteInfo),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.privacyOk),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AnimatedSize(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        child: _open
            ? KeyedSubtree(key: const ValueKey('open'), child: _code(l10n))
            : Panel(
                key: const ValueKey('folded'),
                padding: const EdgeInsets.fromLTRB(6, 4, 4, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _unfold,
                        style: TextButton.styleFrom(
                          alignment: Alignment.centerLeft,
                          foregroundColor: Palette.stageLanternTop,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 14,
                          ),
                        ),
                        icon: const Icon(Icons.qr_code_2_rounded),
                        label: Text(
                          l10n.inviteOpen,
                          style: const TextStyle(
                            fontFamily: displayFont,
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: l10n.inviteInfoTitle,
                      onPressed: _explain,
                      icon: const Icon(
                        Icons.info_outline_rounded,
                        color: Palette.moon200,
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  /// The code itself, on paper: the QR code, the Wi-Fi-only choice and
  /// the technical details.
  Widget _code(AppLocalizations l10n) {
    final link = widget.link;
    final qr = widget.qr;
    final local = widget.onLocalCode;
    final localButton = local == null
        ? null
        : TextButton(
            onPressed: local,
            style: TextButton.styleFrom(foregroundColor: Palette.ink),
            child: Text(
              l10n.inviteLocalCode,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
            ),
          );
    final waiting = widget.onShowCode != null;
    return Panel(
      paper: true,
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  l10n.inviteTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: displayFont,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    color: Palette.ink,
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.inviteFold,
                onPressed: () => setState(() => _open = false),
                icon: const Icon(Icons.expand_less_rounded, color: Palette.ink),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            widget.browserCanJoin ? l10n.inviteHintWeb : l10n.inviteHint,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Palette.inkSoft, fontSize: 14),
          ),
          const SizedBox(height: 12),
          if (waiting)
            SizedBox(
              height: 230,
              child: Center(
                child: _opening
                    ? const CircularProgressIndicator(color: Palette.inkSoft)
                    : const SizedBox.shrink(),
              ),
            )
          else
            DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(Radii.s),
                border: Border.all(color: Palette.inkSoft, width: 2),
              ),
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: QrImageView(
                  data: qr,
                  size: 210,
                  semanticsLabel: l10n.inviteHint,
                ),
              ),
            ),
          // The technical bits only for those who want them.
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: Material(
              type: MaterialType.transparency,
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                iconColor: Palette.inkSoft,
                collapsedIconColor: Palette.inkSoft,
                title: Text(
                  l10n.connectionDetails,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Palette.inkSoft, fontSize: 13),
                ),
                children: [
                  Wrap(
                    spacing: 24,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _SmallLabel(l10n.roomCode, link.room),
                      if (link.lan != null)
                        _SmallLabel(l10n.hostAddress, link.lan.toString()),
                      if (link.relayRoom != null)
                        _SmallLabel(l10n.onlineCode, link.relayRoom!),
                    ],
                  ),
                  if (!qr.startsWith('http:')) ?localButton,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallLabel extends StatelessWidget {
  const _SmallLabel(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Text(label, style: const TextStyle(color: Palette.inkSoft, fontSize: 12)),
      SelectableText(
        value,
        style: const TextStyle(
          color: Palette.ink,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ],
  );
}
