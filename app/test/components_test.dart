import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:whowolf/src/game/figures.dart';
import 'package:whowolf/src/game/widgets.dart';
import 'package:whowolf/src/theme.dart';

Widget _host(Widget child) => MaterialApp(
  theme: buildTheme(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('text takes ink on paper and moonlight on the night', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            Panel(paper: true, child: Body('paper')),
            Panel(child: Body('night')),
          ],
        ),
      ),
    );
    Color colorOf(String text) =>
        tester.widget<Text>(find.text(text)).style!.color!;
    expect(colorOf('paper'), Palette.inkSoft);
    expect(colorOf('night'), Palette.moon200);
  });

  testWidgets('a stamp shows its label, a little crooked', (tester) async {
    await tester.pumpWidget(_host(const Stamp('Dorf')));
    expect(find.text('Dorf'), findsOneWidget);
    final turn = tester.widget<Transform>(
      find.ancestor(of: find.text('Dorf'), matching: find.byType(Transform)),
    );
    expect(turn.transform.getRotation().entry(0, 1), isNot(0));
  });

  testWidgets('a turning figure shows its grey back, then its front', (
    tester,
  ) async {
    Widget figure({required bool back}) => _host(
      TurningFigure(
        asset: 'assets/figures/werwolf.webp',
        backAsset: 'assets/figures/magd.webp',
        showBack: back,
        height: 200,
        sway: false,
      ),
    );
    await tester.pumpWidget(figure(back: true));
    // The back: the stamp on grey board, cut to the persona's outline.
    expect(find.text('Whowolf'), findsOneWidget);
    await tester.pumpWidget(figure(back: false));
    await tester.pumpAndSettle();
    expect(find.text('Whowolf'), findsNothing);
    final images = tester.widgetList<Image>(find.byType(Image));
    expect(
      images.map((i) => (i.image as AssetImage).assetName),
      contains('assets/figures/werwolf.webp'),
    );
  });

  testWidgets('buttons are disabled without a callback', (tester) async {
    await tester.pumpWidget(
      _host(
        const Column(
          children: [
            PrimaryButton(label: 'go', onPressed: null),
            SecondaryButton(label: 'later', onPressed: null),
          ],
        ),
      ),
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).enabled,
      isFalse,
    );
    expect(
      tester.widget<OutlinedButton>(find.byType(OutlinedButton)).enabled,
      isFalse,
    );
  });
}
