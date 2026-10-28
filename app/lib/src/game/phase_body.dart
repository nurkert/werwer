import 'package:flutter/material.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/layout.dart';

/// Shared scaffold of every phase. On a phone it is one column; a wide
/// window splits it: the [Aside] children (the table, the meadow, a big
/// figure) move into a second column on the right, the rest stays on the
/// left. Each column scrolls by itself and centres when it is short.
///
/// The [action] (the screen's one main button, task 012) stays put at the
/// foot of the screen, or of the left column, while the rest scrolls.
class PhaseBody extends StatelessWidget {
  const PhaseBody({required this.children, this.action, super.key});

  final List<Widget> children;
  final Widget? action;

  /// The column with the action pinned below it.
  Widget _withAction(BuildContext context, Widget scroll, double side) {
    final action = this.action;
    if (action == null) return scroll;
    final insets = MediaQuery.paddingOf(context);
    return Column(
      children: [
        Expanded(
          child: MediaQuery.removePadding(
            context: context,
            removeBottom: true,
            child: scroll,
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            side + insets.left,
            8,
            side + insets.right,
            insets.bottom + 14,
          ),
          child: action,
        ),
      ],
    );
  }

  static const double _gap = 18;

  static Widget _stack(List<Widget> children) => Column(
    children: [
      for (final (i, child) in children.indexed) ...[
        if (i > 0) const SizedBox(height: _gap),
        child,
      ],
    ],
  );

  @override
  Widget build(BuildContext context) {
    final layout = StageLayout.of(context);
    final aside = children.whereType<Aside>().toList();
    if (!layout.twoColumns || aside.isEmpty) {
      return _withAction(
        context,
        StageScroll(maxWidth: layout.columnWidth, child: _stack(children)),
        layout.size.width > layout.columnWidth + 40
            ? (layout.size.width - layout.columnWidth) / 2
            : 20,
      );
    }
    final main = [
      for (final child in children)
        if (child is! Aside) child,
    ];
    // The phase's title stands above both columns, centred: a short column
    // standing on the floor does not take it down with it.
    final head = main.isNotEmpty && main.first is Headline
        ? main.removeAt(0)
        : null;
    final insets = MediaQuery.paddingOf(context);
    final action = this.action;
    // Two columns standing on the stage floor, so their boxes line up at
    // the same height; each scrolls when it is long. The main button sits
    // centred below both.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1240),
        child: Padding(
          padding: EdgeInsets.only(left: insets.left, right: insets.right),
          child: MediaQuery.removePadding(
            context: context,
            removeLeft: true,
            removeRight: true,
            child: Column(
              children: [
                if (head != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, insets.top + 4, 24, 0),
                    child: head,
                  ),
                Expanded(
                  child: MediaQuery.removePadding(
                    context: context,
                    removeTop: head != null,
                    removeBottom: action != null,
                    child: Row(
                      children: [
                        SizedBox(
                          width: (layout.size.width * 0.4).clamp(360, 520),
                          child: StageScroll(
                            horizontal: 24,
                            floor: true,
                            child: _stack(main),
                          ),
                        ),
                        Expanded(
                          child: StageScroll(
                            maxWidth: 760,
                            horizontal: 24,
                            floor: true,
                            child: _stack(aside),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (action != null)
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      24,
                      4,
                      24,
                      insets.bottom + 18,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 460),
                      child: action,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A part of a phase that moves into the second column on wide windows
/// (see [PhaseBody]); on a phone it stays where it is.
class Aside extends StatelessWidget {
  const Aside({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
