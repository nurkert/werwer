import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/stage/stage_pages.dart';

void main() {
  Widget host(double keyboard) => MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        viewInsets: EdgeInsets.only(bottom: keyboard),
      ),
      child: const Scaffold(
        resizeToAvoidBottomInset: false,
        body: StagePages(
          pages: [
            (
              label: 'a',
              child: Column(
                children: [
                  SizedBox(height: 600),
                  TextField(key: Key('field')),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );

  testWidgets('the page keeps its size and slides the field above the '
      'keyboard', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    await tester.pumpWidget(host(0));
    final before = tester.getSize(find.byKey(const Key('field')));
    await tester.tap(find.byKey(const Key('field')));
    await tester.pumpWidget(host(340));
    await tester.pumpAndSettle();
    final field = find.byKey(const Key('field'));
    // Not scaled down to fit the smaller space.
    expect(tester.getSize(field), before);
    // Its bottom sits above the keyboard.
    expect(tester.getBottomLeft(field).dy, lessThanOrEqualTo(844 - 340));
    await tester.pumpWidget(host(0));
    await tester.pumpAndSettle();
    expect(tester.getBottomLeft(field).dy, greaterThan(844 - 340));
  });
}
