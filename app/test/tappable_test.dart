import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/stage/tappable.dart';

void main() {
  testWidgets('the keyboard reaches a tap target: Tab, then Enter or Space', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: Tappable(
            onTap: () => taps++,
            child: const SizedBox(width: 80, height: 80),
          ),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.pump();
    expect(taps, 2);
    await tester.tap(find.byType(Tappable));
    expect(taps, 3);
  });

  testWidgets('without a tap there is nothing to focus', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: Tappable(onTap: null, child: SizedBox(width: 80, height: 80)),
        ),
      ),
    );
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    final focus = FocusManager.instance.primaryFocus;
    expect(
      find.descendant(
        of: find.byType(Tappable),
        matching: find.byWidgetPredicate(
          (w) => w is Focus && w.focusNode == focus,
        ),
      ),
      findsNothing,
    );
  });
}
