import 'dart:math';

import 'package:flutter/material.dart';

/// How a screen arranges itself, decided from the window alone: a phone in
/// the hand, a tablet upright, or a wide window (desktop, tablet or phone
/// held sideways) that has room for two columns.
@immutable
class StageLayout {
  const StageLayout._(this.size);

  /// The layout for the current window.
  factory StageLayout.of(BuildContext context) =>
      StageLayout._(MediaQuery.sizeOf(context));

  final Size size;

  /// Side by side instead of one long column: wide windows, and anything
  /// held sideways that is wider than a phone is tall.
  bool get twoColumns =>
      size.width >= 1000 || (size.width >= 720 && size.width > size.height);

  /// Little height to spare (a phone sideways, a small window).
  bool get short => size.height < 560;

  /// More than a phone: bigger figures, more cards per row.
  bool get roomy => size.shortestSide >= 600;

  /// The width of a single column.
  double get columnWidth => roomy ? 640 : 560;
}

/// The height the scroll column around a widget shows at once, so pictures
/// can fit the window instead of pushing the rest out of sight. `null`
/// outside a [StageScroll].
class ColumnSpace extends InheritedWidget {
  const ColumnSpace({required this.height, required super.child, super.key});

  final double height;

  static double? heightOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ColumnSpace>()?.height;

  @override
  bool updateShouldNotify(ColumnSpace old) => old.height != height;
}

/// A scrolling column on the stage. It keeps clear of what floats above
/// and below it (the app bar, the narrator, the home indicator: whatever
/// [MediaQuery.paddingOf] reports) but scrolls underneath it, fading out
/// on the way instead of stopping at a hard edge. Short content starts at
/// the top, under the title, as on a stage bill (task 012).
class StageScroll extends StatelessWidget {
  const StageScroll({
    required this.child,
    this.maxWidth = 560,
    this.horizontal = 20,
    super.key,
  });

  final Widget child;
  final double maxWidth;
  final double horizontal;

  /// How far content fades before it reaches the edge.
  static const double fade = 28;

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.paddingOf(context);
    final top = insets.top + 12;
    final bottom = insets.bottom + 28;
    return LayoutBuilder(
      builder: (context, box) {
        final viewport = max(0, box.maxHeight - top - bottom).toDouble();
        final height = box.maxHeight;
        return ShaderMask(
          blendMode: BlendMode.dstIn,
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [
              _at(insets.top - fade, height),
              _at(insets.top + 4, height),
              _at(height - insets.bottom - fade, height),
              _at(height - insets.bottom + 4, height),
            ],
            colors: const [
              Color(0x00000000),
              Color(0xFF000000),
              Color(0xFF000000),
              Color(0x00000000),
            ],
          ).createShader(rect),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            removeBottom: true,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                horizontal + insets.left,
                top,
                horizontal + insets.right,
                bottom,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ColumnSpace(height: viewport, child: child),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static double _at(double y, double height) =>
      height <= 0 ? 0 : (y / height).clamp(0, 1);
}

/// How tall a figure may stand so the rest of its column still fits:
/// [phone] on an ordinary phone, larger on tablets and wide windows,
/// smaller when the window is short. [share] is the part of the visible
/// column height it may take (on wide windows [wideShare]).
double figureHeight(
  BuildContext context, {
  required double phone,
  double share = 0.34,
  double wideShare = 0.62,
}) {
  final layout = StageLayout.of(context);
  final space = ColumnSpace.heightOf(context) ?? layout.size.height * 0.7;
  final most = layout.twoColumns
      ? 540.0
      : layout.roomy
      ? phone * 1.5
      : phone;
  final wanted = space * (layout.twoColumns ? wideShare : share);
  return wanted.clamp(min(120, most), most).toDouble();
}
