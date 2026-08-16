import 'package:breathe/core/theme/app_colors.dart';
import 'package:breathe/dots/dot_atlas.dart';
import 'package:breathe/dots/dot_matrix_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: child),
      ),
    );

void main() {
  setUpAll(DotAtlas.warmUpSync);

  testWidgets('sizes itself from the glyph grid', (tester) async {
    await tester.pumpWidget(
      _host(const DotMatrixText(value: '3.3', cellSize: 6, cellGap: 3, shimmer: 0)),
    );

    // "3.3" is 19 columns wide, 9 rows tall, pitch 9, minus one trailing gap.
    final size = tester.getSize(find.byType(DotMatrixText));
    expect(size.width, closeTo(19 * 9 - 3, 0.01));
    expect(size.height, closeTo(9 * 9 - 3, 0.01));
  });

  testWidgets('exposes the readout to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      _host(const DotMatrixText(value: '3.3', semanticsLabel: '3.3 liters', shimmer: 0)),
    );

    expect(find.bySemanticsLabel('3.3 liters'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('morphs to a new value and settles', (tester) async {
    await tester.pumpWidget(_host(const DotMatrixText(value: '3.3', shimmer: 0)));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(const DotMatrixText(value: '3.4', shimmer: 0)));
    await tester.pump(const Duration(milliseconds: 200)); // mid-morph
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('geometry changes snap rather than morph', (tester) async {
    await tester.pumpWidget(
      _host(const DotMatrixText(value: '5.5', cellSize: 6, cellGap: 3, shimmer: 0)),
    );
    await tester.pumpAndSettle();

    await tester.pumpWidget(
      _host(const DotMatrixText(value: '5.5', cellSize: 10, cellGap: 4, shimmer: 0)),
    );
    await tester.pump(); // one frame — a morph would still be mid-flight

    final size = tester.getSize(find.byType(DotMatrixText));
    expect(size.width, closeTo(19 * 14 - 4, 0.01));
  });

  testWidgets('renders every supported glyph without throwing',
      (tester) async {
    await tester.pumpWidget(
      _host(const DotMatrixText(value: '0123456789', shimmer: 0)),
    );
    await tester.pumpAndSettle();
    await tester.pumpWidget(_host(const DotMatrixText(value: '-1.4', shimmer: 0)));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
