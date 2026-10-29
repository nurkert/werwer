import 'package:flutter/material.dart';
import 'package:game_core/game_core.dart';
import 'package:protocol/protocol.dart';
import 'package:whowolf/l10n/app_localizations.dart';
import 'package:whowolf/src/game/check_code.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/net/game_session.dart';

/// Someone asks to join: their name, the symbols their device shows, and
/// the two answers. [note] says how they come in (a running game).
class AdmitCard extends StatelessWidget {
  const AdmitCard({
    required this.join,
    required this.onAnswer,
    super.key,
    this.note,
    this.more = 0,
    this.compact = false,
  });

  final PendingJoin join;

  /// Smaller, for a card over a running game's screen.
  final bool compact;
  final ValueChanged<bool> onAnswer;
  final String? note;

  /// How many more wait behind this one.
  final int more;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final refuse = SecondaryButton(
      label: l10n.refuse,
      onPressed: () => onAnswer(false),
    );
    final letIn = PrimaryButton(
      label: l10n.letIn,
      onPressed: () => onAnswer(true),
    );
    return Panel(
      highlight: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Headline(l10n.wantsToJoin(join.name), size: compact ? 26 : 34),
          SizedBox(height: compact ? 6 : 8),
          Body(l10n.compareSymbols),
          if (note case final note?) Body(note, muted: true),
          SizedBox(height: compact ? 10 : 12),
          if (join.checkCode.isNotEmpty)
            CheckCode(code: join.checkCode, size: compact ? 30 : 32),
          SizedBox(height: compact ? 12 : 14),
          LayoutBuilder(
            builder: (context, box) {
              // Side by side only where both labels fit on one line.
              if (box.maxWidth < 360) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [letIn, const SizedBox(height: 10), refuse],
                );
              }
              return Row(
                children: [
                  Expanded(child: refuse),
                  const SizedBox(width: 12),
                  Expanded(child: letIn),
                ],
              );
            },
          ),
          if (more > 0) ...[
            const SizedBox(height: 8),
            Body(l10n.moreWaiting(more), muted: true),
          ],
        ],
      ),
    );
  }
}

/// For the game leader in a running game: someone asks to join. The host
/// asks only by day (never at night, where the leader's phone lighting up
/// could look like a role at work), so this shows only then; it slides
/// up from the bottom over the day's screen until the leader answers.
class LateJoinPrompt extends StatelessWidget {
  const LateJoinPrompt({required this.session, super.key});

  final GameSession session;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: session,
    builder: (context, _) => _prompt(context),
  );

  Widget _prompt(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final view = session.view;
    final pending = session.pending;
    final show =
        session.isOwner &&
        view != null &&
        view.phase == Phase.day &&
        pending.isNotEmpty;
    final first = show ? pending.first : null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 260),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.4),
          end: Offset.zero,
        ).animate(animation),
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: first == null
          ? const SizedBox.shrink()
          : SafeArea(
              key: ValueKey(first.id),
              top: false,
              child: Center(
                heightFactor: 1,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 480),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: AdmitCard(
                      compact: true,
                      join: first,
                      more: pending.length - 1,
                      note: switch (view!.settings.lateJoin) {
                        LateJoin.ghost => l10n.lateJoinAsGhost,
                        LateJoin.villager => l10n.lateJoinAsVillager,
                      },
                      onAnswer: (admit) =>
                          session.send(AdmitIntent(first.id, admit: admit)),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
