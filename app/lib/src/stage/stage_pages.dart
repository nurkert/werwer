import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:whowolf/src/stage/pan.dart';
import 'package:whowolf/src/theme.dart';

/// One page of [StagePages]: its name for the dots and what it shows.
typedef StagePage = ({String label, Widget child});

/// A page that scrolls up and down instead of fitting (a long read, like
/// the rules on paper).
class ScrollingPage extends StatelessWidget {
  const ScrollingPage({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

/// Pages to swipe like a phone's home screen instead of one long scroll
/// (task 012): the stage stays, only the front pans away, fading and
/// stepping back a little. Each page
/// fits the window; on a very small one it shrinks as a whole rather than
/// scroll.
class StagePages extends StatefulWidget {
  const StagePages({
    required this.pages,
    super.key,
    this.maxWidth = 440,
    this.action,
    this.initialPage = 0,
    this.arrows = false,
  });

  /// Arrows at the sides and the arrow keys turn the pages (on a computer,
  /// where there is no finger to swipe with).
  final bool arrows;

  /// The page shown first (the others to its left and right).
  final int initialPage;

  final List<StagePage> pages;
  final double maxWidth;

  /// The screen's one main button, on every page, above the dots.
  final Widget? action;

  @override
  State<StagePages> createState() => _StagePagesState();
}

class _StagePagesState extends State<StagePages> {
  late final _controller = PageController(initialPage: widget.initialPage)
    ..addListener(_panStage);

  /// The stage behind, which pans along with the pages.
  PanNotifier? _stage;

  /// How far the pages slide up so the focused field clears the keyboard.
  double _lift = 0;
  double _inset = 0;

  /// After the keyboard opened or closed: lift the pages just enough that
  /// the field being typed in sits above it, with a little air.
  void _clearKeyboard() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var target = 0.0;
      final focus = FocusManager.instance.primaryFocus?.context;
      final box = focus?.findRenderObject();
      if (_inset > 0 && box is RenderBox && box.attached) {
        final bottom = box.localToGlobal(Offset(0, box.size.height)).dy + _lift;
        final visible = MediaQuery.sizeOf(context).height - _inset;
        target = (bottom + 18 - visible).clamp(0.0, _inset);
      }
      if ((target - _lift).abs() > 1) setState(() => _lift = target);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _stage = StagePan.of(context);
  }

  void _panStage() {
    _stage?.set(_page - widget.initialPage);
    // The arrows show or hide at the first and last page.
    if (widget.arrows && mounted) setState(() {});
  }

  void _go(int delta) {
    final target = (_page.round() + delta).clamp(0, widget.pages.length - 1);
    unawaited(
      _controller.animateToPage(
        target,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    final stage = _stage;
    if (stage != null) {
      // Back to the middle once these pages are gone (after this frame).
      WidgetsBinding.instance.addPostFrameCallback((_) => stage.set(0));
    }
    _controller.dispose();
    super.dispose();
  }

  double get _page =>
      _controller.hasClients && _controller.position.haveDimensions
      ? _controller.page ?? widget.initialPage.toDouble()
      : widget.initialPage.toDouble();

  /// The pages with an arrow at each side (where there is a page to go
  /// to) and the arrow keys bound, when [StagePages.arrows] asks for it.
  Widget _withArrows(Widget pages) {
    if (!widget.arrows || widget.pages.length < 2) return pages;
    final at = _page.round();
    Widget arrow(int delta, IconData icon, String label) => AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: (at + delta < 0 || at + delta >= widget.pages.length) ? 0 : 1,
      child: IgnorePointer(
        ignoring: at + delta < 0 || at + delta >= widget.pages.length,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: _arrowMargin),
          child: Tooltip(
            message: label,
            child: Material(
              color: const Color(0xD91C1814),
              shape: const CircleBorder(
                side: BorderSide(color: Palette.stageBrass, width: 1.5),
              ),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => _go(delta),
                child: Padding(
                  padding: const EdgeInsets.all(_arrowPadding),
                  child: Icon(
                    icon,
                    color: Palette.stageLanternTop,
                    size: _arrowIcon,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final labels = [for (final p in widget.pages) p.label];
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowLeft): () => _go(-1),
        const SingleActivator(LogicalKeyboardKey.arrowRight): () => _go(1),
      },
      child: Focus(
        autofocus: true,
        child: Stack(
          children: [
            Positioned.fill(child: pages),
            // In the middle of the page's content (below the top inset),
            // in their own lane beside it.
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
              ),
              child: Row(
                children: [
                  arrow(
                    -1,
                    Icons.chevron_left_rounded,
                    at > 0 ? labels[at - 1] : '',
                  ),
                  const Spacer(),
                  arrow(
                    1,
                    Icons.chevron_right_rounded,
                    at + 1 < labels.length ? labels[at + 1] : '',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The width each arrow keeps free beside the pages, so it never sits
  /// on a page's edge.
  static const _arrowIcon = 30.0;
  static const _arrowPadding = 14.0;
  static const _arrowMargin = 16.0;
  static const double _arrowLane =
      _arrowIcon + 2 * _arrowPadding + 2 * _arrowMargin;

  bool get _hasArrows => widget.arrows && widget.pages.length > 1;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final still = MediaQuery.of(context).disableAnimations;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    if (keyboard != _inset) {
      _inset = keyboard;
      _clearKeyboard();
    }
    return AnimatedSlide(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      offset: Offset(0, -_lift / MediaQuery.sizeOf(context).height),
      child: Column(
        children: [
          Expanded(
            child: _withArrows(
              PageView.builder(
                controller: _controller,
                // No bounce past the first or last page.
                physics: const PageScrollPhysics(
                  parent: ClampingScrollPhysics(),
                ),
                itemCount: widget.pages.length,
                itemBuilder: (context, i) => AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    // The page moves exactly with the finger; leaving, it fades
                    // and steps back a little (never into its neighbour).
                    final off = still ? 0.0 : (_page - i).abs().clamp(0.0, 1.0);
                    return Opacity(
                      opacity: 1 - off * 0.55,
                      child: Transform.scale(
                        scale: 1 - off * 0.06,
                        child: child,
                      ),
                    );
                  },
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: _hasArrows ? _arrowLane : 0,
                      ),
                      child: widget.pages[i].child is ScrollingPage
                          ? _ScrollPage(
                              maxWidth: widget.maxWidth,
                              top: insets.top + 8,
                              child: widget.pages[i].child,
                            )
                          : _FitPage(
                              maxWidth: widget.maxWidth,
                              top: insets.top + 8,
                              child: widget.pages[i].child,
                            ),
                    ),
                  ),
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
      ),
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

/// A page that scrolls, its content fading out under the edges.
class _ScrollPage extends StatelessWidget {
  const _ScrollPage({
    required this.child,
    required this.maxWidth,
    required this.top,
  });

  final Widget child;
  final double maxWidth;
  final double top;

  @override
  Widget build(BuildContext context) => ShaderMask(
    blendMode: BlendMode.dstIn,
    shaderCallback: (rect) => LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      stops: [
        0,
        (top / rect.height).clamp(0, 1),
        0.94,
        1,
      ],
      colors: const [
        Color(0x00000000),
        Color(0xFF000000),
        Color(0xFF000000),
        Color(0x00000000),
      ],
    ).createShader(rect),
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, top, 20, 24),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth + 120),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: child,
          ),
        ),
      ),
    ),
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
          ? controller.page ?? controller.initialPage.toDouble()
          : controller.initialPage.toDouble();
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
