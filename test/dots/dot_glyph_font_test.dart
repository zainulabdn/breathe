import 'package:breathe/dots/dot_glyph_font.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DotGlyphFont', () {
    test('every supported glyph is 9 rows tall and rectangular', () {
      for (final char in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
        '.', ':', '-', ' ']) {
        final glyph = DotGlyphFont.glyph(char);
        expect(
          glyph.cells.length,
          glyph.cols * DotGlyph.rows,
          reason: 'glyph "$char" has a ragged bitmap',
        );
      }
    });

    test('digits are all the same width so readouts do not jitter', () {
      final widths = {
        for (final d in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'])
          DotGlyphFont.glyph(d).cols,
      };
      expect(widths, hasLength(1),
          reason: 'a variable-width digit makes the number shift on every '
              'value change, which defeats the morph animation');
      expect(widths.single, 7);
    });

    test('punctuation is narrower than a digit', () {
      expect(DotGlyphFont.glyph('.').cols, lessThan(7));
      expect(DotGlyphFont.glyph(':').cols, lessThan(7));
    });

    test('measureCols accounts for inter-glyph gaps', () {
      // "3.3" -> 7 + gap + 3 + gap + 7
      expect(
        DotGlyphFont.measureCols('3.3'),
        7 + DotGlyphFont.glyphGapCols + 3 + DotGlyphFont.glyphGapCols + 7,
      );
      expect(DotGlyphFont.measureCols(''), 0);
      expect(DotGlyphFont.measureCols('8'), 7);
    });

    test('unsupported characters fall back to blank instead of throwing', () {
      expect(DotGlyphFont.supports('Q'), isFalse);
      expect(() => DotGlyphFont.glyph('Q'), returnsNormally);
      expect(DotGlyphFont.glyph('Q').cells.every((lit) => !lit), isTrue);
    });

    test('every digit lights at least one cell in the top and bottom row', () {
      for (final d in ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9']) {
        final glyph = DotGlyphFont.glyph(d);
        final top = List.generate(glyph.cols, (c) => glyph.isLit(c, 0));
        final bottom =
            List.generate(glyph.cols, (c) => glyph.isLit(c, DotGlyph.rows - 1));
        expect(top.any((v) => v), isTrue, reason: '"$d" has an empty top row');
        expect(bottom.any((v) => v), isTrue,
            reason: '"$d" has an empty bottom row');
      }
    });
  });
}
