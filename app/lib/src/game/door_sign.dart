import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';
import 'package:whowolf/src/theme.dart';

/// Your door sign tonight, big: everyone has one, so everyone has a reason
/// to keep their screen to themselves (not just the werewolves).
class DoorSignPanel extends StatelessWidget {
  const DoorSignPanel({required this.sign, super.key});

  final List<int> sign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Panel(
      child: Column(
        children: [
          Headline(l10n.doorSignTitle, size: 24),
          const SizedBox(height: 12),
          CheckCode(code: sign, size: 40),
          const SizedBox(height: 12),
          Body(l10n.doorSignHint, muted: true),
        ],
      ),
    );
  }
}

/// For the werewolves: a door sign someone saw on another phone. One try
/// per pack and night; a right sign gives a fair chance, no certainty.
class MarkForm extends StatefulWidget {
  const MarkForm({required this.session, super.key});

  final GameSession session;

  @override
  State<MarkForm> createState() => _MarkFormState();
}

class _MarkFormState extends State<MarkForm> {
  PlayerId? _target;
  final _sign = List<int?>.filled(doorSignLength, null);

  Future<void> _pickSymbol(int slot) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < doorSignSymbols; i++)
                IconButton.outlined(
                  iconSize: 32,
                  onPressed: () => Navigator.pop(context, i),
                  icon: Icon(checkSymbols[i], color: Palette.moon100),
                ),
            ],
          ),
        ),
      ),
    );
    if (picked != null) setState(() => _sign[slot] = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = widget.session.view!;
    final mark = view.packMark;
    if (mark != null) {
      final name = view.nameOf(mark.target);
      return Body(mark.correct ? l10n.markRight(name) : l10n.markWrong(name));
    }
    final target = _target;
    final ready = target != null && _sign.every((s) => s != null);
    return Column(
      children: [
        Headline(l10n.markTitle, size: 22),
        const SizedBox(height: 6),
        Body(l10n.markHint, muted: true),
        const SizedBox(height: 12),
        SeatGrid(
          view: view,
          selected: target,
          enabled: (seat) =>
              seat.isAlive && seat.id != view.you && seat.role != Role.werewolf,
          onTap: (seat) => setState(() => _target = seat.id),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var slot = 0; slot < doorSignLength; slot++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Semantics(
                  button: true,
                  label: l10n.markSymbol(slot + 1),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(Radii.s + 4),
                    onTap: () => _pickSymbol(slot),
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: Palette.night700,
                        borderRadius: BorderRadius.circular(Radii.s + 4),
                        border: Border.all(
                          color: _sign[slot] == null
                              ? Palette.night500
                              : Palette.lantern400,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        _sign[slot] == null
                            ? Icons.question_mark_rounded
                            : checkSymbols[_sign[slot]!],
                        size: 34,
                        color: _sign[slot] == null
                            ? Palette.night500
                            : Palette.moon100,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SecondaryButton(
          label: l10n.markTry,
          onPressed: ready
              ? () => widget.session.send(
                  MarkIntent(target, [for (final s in _sign) s!]),
                )
              : null,
        ),
      ],
    );
  }
}
