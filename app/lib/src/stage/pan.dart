import 'package:flutter/widgets.dart';

/// How far the pages in front have been swiped from the first one shown
/// (in pages, negative to the left): the stage set behind pans with them,
/// the painted set slowly, the scenery a whole width per page (task 012).
class StagePan extends InheritedWidget {
  const StagePan({required this.pan, required super.child, super.key});

  final PanNotifier pan;

  /// The pan of the stage around, if there is one.
  static PanNotifier? of(BuildContext context) =>
      context.getInheritedWidgetOfExactType<StagePan>()?.pan;

  @override
  bool updateShouldNotify(StagePan old) => old.pan != pan;
}

/// The pan value, which knows when its stage is gone.
class PanNotifier extends ValueNotifier<double> {
  PanNotifier() : super(0);

  bool _gone = false;

  /// Sets the pan unless the stage has gone meanwhile.
  void set(double pan) {
    if (!_gone) value = pan;
  }

  @override
  void dispose() {
    _gone = true;
    super.dispose();
  }
}
