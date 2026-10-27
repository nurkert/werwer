import 'dart:math';

import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// One page of [StagePages]: its name for the dots and what it shows.
typedef StagePage = ({String label, Widget child});

/// Pages to swipe like a phone's home screen instead of one long scroll
/// (task 012): the stage stays, only the front pans away, a little
/// slower than the finger and fading, so it feels like depth. Each page
/// fits the window; on a very small one it shrinks as a whole rather than
/// scroll.
class StagePages extends StatefulWidget {
  const StagePages({
    required this.pages,
    super.key,
    this.maxWidth = 440,
    this.action,
  });

  final List<StagePage> pages;
  final double maxWidth;

  /// The screen's one main button, on every page, above the dots.
  final Widget? action;

  @override
  State<StagePages> createState() => _StagePagesState();
}

class _StagePagesState extends State<StagePages> {
  final _controller = PageController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _page =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? 0
      : 0;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final still = MediaQuery.of(context).disableAnimations;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.pages.length,
            itemBuilder: (context, i) => AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                final off = still ? 0.0 : _page - i;
                return Opacity(
                  opacity: (1 - off.abs() * 0.6).clamp(0.0, 1.0),
                  child: Transform.translate(
                    // Lagging behind the finger a little: depth.
                    offset: Offset(off * 60, 0),
                    child: child,
                  ),
                );
              },
              child: _FitPage(
                maxWidth: widget.maxWidth,
                top: insets.top + 8,
                child: widget.pages[i].child,
              ),
            ),
          ),
        ),
        if (widget.action case final action?)
          Padding(
            padding: EdgeInsets.fromLTRB(
              20 + insets.left,
              8,
              20 + insets.right,
              0,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: widget.maxWidth),
              child: action,
            ),
          ),
        _Dots(
          controller: _controller,
          labels: [for (final p in widget.pages) p.label],
          onTap: (i) => _controller.animateToPage(
            i,
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
          ),
        ),
        SizedBox(height: insets.bottom + 10),
      ],
    );
  }
}

/// A page laid out at its natural height and, only if the window is too
/// small for it, scaled down as a whole: never a scroll bar.
class _FitPage extends StatelessWidget {
  const _FitPage({
    required this.child,
    required this.maxWidth,
    required this.top,
  });

  final Widget child;
  final double maxWidth;
  final double top;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = min(box.maxWidth - 40, maxWidth);
      return Padding(
        padding: EdgeInsets.only(top: top),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: width,
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class _Dots extends StatelessWidget {
  const _Dots({
    required this.controller,
    required this.labels,
    required this.onTap,
  });

  final PageController controller;
  final List<String> labels;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) {
      final page = controller.hasClients && controller.position.haveDimensions
          ? controller.page ?? 0
          : 0.0;
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (final (i, label) in labels.indexed)
            Semantics(
              button: true,
              selected: page.round() == i,
              label: label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 10,
                  ),
                  child: () {
                    final near = (1 - (page - i).abs()).clamp(0.0, 1.0);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8 + 14 * near,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: Color.lerp(
                              Palette.stageIvorySoft.withValues(alpha: 0.4),
                              Palette.stageLanternTop,
                              near,
                            ),
                          ),
                        ),
                        if (near > 0.5) ...[
                          const SizedBox(width: 6),
                          Opacity(
                            opacity: (near - 0.5) * 2,
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontFamily: displayFont,
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Palette.stageIvory,
                                shadows: [Shadow(blurRadius: 6)],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }(),
                ),
              ),
            ),
        ],
      );
    },
  );
}
