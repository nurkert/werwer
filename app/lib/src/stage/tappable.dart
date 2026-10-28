import 'package:flutter/material.dart';
import 'package:whowolf/src/theme.dart';

/// A tap target the keyboard reaches too: Tab focuses it (a lantern ring
/// shows where), Enter or Space taps it. Touch and mouse work as before.
class Tappable extends StatefulWidget {
  const Tappable({
    required this.child,
    required this.onTap,
    this.radius = 16,
    super.key,
  });

  final Widget child;

  /// `null`: not tappable, and not focusable either.
  final VoidCallback? onTap;

  /// The corner radius of the focus ring.
  final double radius;

  @override
  State<Tappable> createState() => _TappableState();
}

class _TappableState extends State<Tappable> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final onTap = widget.onTap;
    return FocusableActionDetector(
      enabled: onTap != null,
      mouseCursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onShowFocusHighlight: (on) => setState(() => _focused = on),
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            border: _focused
                ? Border.all(color: Palette.stageLanternTop, width: 2.5)
                : null,
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
