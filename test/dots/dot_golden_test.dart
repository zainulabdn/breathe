import 'package:breathe/core/theme/app_colors.dart';
import 'package:breathe/dots/dot_atlas.dart';
import 'package:breathe/dots/dot_field.dart';
import 'package:breathe/dots/dot_matrix_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Goldens are the guard against silent dot-geometry drift — a one-cell change
/// in a glyph is invisible in a unit test and obvious here.
/// Regenerate with `flutter test --update-goldens`.
void main() {
  setUpAll(DotAtlas.warmUpSync);

  Widget frame(Widget child, {Size size = const Size(400, 240)}) {
    return MediaQuery(
      data: const MediaQueryData(),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Container(
            width: size.width,
            height: size.height,
            color: AppColors.bg,
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('glyph sheet — every supported character', (tester) async {
    await tester.pumpWidget(
      frame(
        size: const Size(400, 260),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            DotMatrixText(value: '01234', cellSize: 5, cellGap: 2, shimmer: 0),
            SizedBox(height: 14),
            DotMatrixText(value: '56789', cellSize: 5, cellGap: 2, shimmer: 0),
            SizedBox(height: 14),
            DotMatrixText(value: '-1.2:3', cellSize: 5, cellGap: 2, shimmer: 0),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Column),
      matchesGoldenFile('goldens/glyph_sheet.png'),
    );
  });

  testWidgets('readout on the lung card gradient', (tester) async {
    await tester.pumpWidget(
      frame(
        Container(
          width: 300,
          height: 200,
          decoration: BoxDecoration(
            gradient: AppColors.lungCardGradient,
            borderRadius: BorderRadius.circular(40),
          ),
          alignment: Alignment.center,
          child: const DotMatrixText(value: '3.3', cellSize: 7, cellGap: 3.5, shimmer: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(Container).last,
      matchesGoldenFile('goldens/readout_on_card.png'),
    );
  });

  testWidgets('lung field at empty / half / full', (tester) async {
    await tester.pumpWidget(
      frame(
        size: const Size(420, 200),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: const [
            SizedBox(width: 130, height: 170, child: DotField(fillLevel: 0.0, bubbles: 0, wobble: 0)),
            SizedBox(width: 130, height: 170, child: DotField(fillLevel: 0.5, bubbles: 0, wobble: 0)),
            SizedBox(width: 130, height: 170, child: DotField(fillLevel: 1.0, bubbles: 0, wobble: 0)),
          ],
        ),
      ),
    );
    await tester.pump();
    await expectLater(
      find.byType(Row),
      matchesGoldenFile('goldens/lung_field_levels.png'),
    );
  });
}
