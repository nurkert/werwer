import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// How long a seat's QR code works (the host's limit, see
/// `GameHost.handoverTime`).
const _codeTime = Duration(minutes: 2);

/// A one-time code in a token's format: 16 random bytes as hex.
String _newCode() {
  final random = Random.secure();
  return [
    for (var i = 0; i < 16; i++) random.nextInt(256).toRadixString(16),
  ].map((h) => h.padLeft(2, '0')).join();
}

/// The game leader hands a player's seat to another device (a phone whose
/// battery died): pick the seat, and a one-time QR code appears that the
/// new device scans with the app. It works once, for two minutes; the old
/// device is let go.
Future<void> handOverSeat(
  BuildContext context, {
  required GameSession session,
  required JoinLink link,
}) async {
  final view = session.view;
  if (view == null) return;
  final l10n = AppLocalizations.of(context);
  final seat = await showDialog<SeatView>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(l10n.handoverPick),
      children: [
        for (final s in view.seats)
          if (s.id != view.you)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, s),
              child: Row(
                children: [
                  Expanded(child: Text(s.name)),
                  if (session.offline.contains(s.id))
                    Text(
                      l10n.offlineBadge,
                      style: const TextStyle(color: Palette.moon200),
                    ),
                ],
              ),
            ),
      ],
    ),
  );
  if (seat == null || !context.mounted) return;
  final code = _newCode();
  session.send(HandoverIntent(seat.id, code));
  await showDialog<void>(
    context: context,
    builder: (context) => _SeatCode(
      name: seat.name,
      qr: link.withSeat(code).encode(),
    ),
  );
}

class _SeatCode extends StatefulWidget {
  const _SeatCode({required this.name, required this.qr});

  final String name;
  final String qr;

  @override
  State<_SeatCode> createState() => _SeatCodeState();
}

class _SeatCodeState extends State<_SeatCode> {
  late final DateTime _until = DateTime.now().add(_codeTime);
  late final Timer _tick;

  @override
  void initState() {
    super.initState();
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (DateTime.now().isAfter(_until)) {
        _tick.cancel();
        unawaited(Navigator.of(context).maybePop());
      } else {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final left = _until.difference(DateTime.now());
    final clock =
        '${left.inMinutes}:${(left.inSeconds % 60).toString().padLeft(2, '0')}';
    return AlertDialog(
      title: Text(l10n.handoverTitle(widget.name)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: QrImageView(
                data: widget.qr,
                size: 220,
                semanticsLabel: l10n.handoverTitle(widget.name),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Body(l10n.handoverHint(widget.name)),
          const SizedBox(height: 6),
          Text(
            clock,
            style: const TextStyle(
              fontFamily: displayFont,
              fontWeight: FontWeight.w700,
              fontSize: 22,
              color: Palette.stageLanternTop,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.handoverDone),
        ),
      ],
    );
  }
}
