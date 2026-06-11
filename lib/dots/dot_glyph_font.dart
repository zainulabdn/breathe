/// A 9-row bitmap font for the readouts. See docs/DESIGN_SPEC.md §4.
///
/// Digits are 7 columns wide; punctuation is narrower so "3.3" does not read
/// with a hole in the middle. Authored as strings because a human has to be
/// able to eyeball a glyph and fix it — they are parsed once into flat cell
/// lists at first use, so the string form costs nothing at paint time.
library;

class DotGlyph {
  const DotGlyph(this.cols, this.cells);

  /// Column count for this glyph (its advance width in cells).
  final int cols;

  /// Row-major lit cells, [rows] * [cols] entries.
  final List<bool> cells;

  static const int rows = 9;

  bool isLit(int col, int row) => cells[row * cols + col];
}

abstract final class DotGlyphFont {
  /// Blank columns inserted between adjacent glyphs.
  static const int glyphGapCols = 1;

  static const Map<String, List<String>> _source = {
    '0': [
      '.#####.',
      '##...##',
      '##...##',
      '##...##',
      '##...##',
      '##...##',
      '##...##',
      '##...##',
      '.#####.',
    ],
    '1': [
      '...##..',
      '..###..',
      '.####..',
      '...##..',
      '...##..',
      '...##..',
      '...##..',
      '...##..',
      '.#####.',
    ],
    '2': [
      '.#####.',
      '##...##',
      '.....##',
      '....##.',
      '...##..',
      '..##...',
      '.##....',
      '##.....',
      '#######',
    ],
    '3': [
      '.#####.',
      '##...##',
      '.....##',
      '....##.',
      '..####.',
      '....##.',
      '.....##',
      '##...##',
      '.#####.',
    ],
    '4': [
      '....##.',
      '...###.',
      '..#.##.',
      '.#..##.',
      '##..##.',
      '#######',
      '....##.',
      '....##.',
      '....##.',
    ],
    '5': [
      '#######',
      '##.....',
      '##.....',
      '######.',
      '.....##',
      '.....##',
      '.....##',
      '##...##',
      '.#####.',
    ],
    '6': [
      '..####.',
      '.##..##',
      '##.....',
      '##.....',
      '######.',
      '##...##',
      '##...##',
      '##...##',
      '.#####.',
    ],
    '7': [
      '#######',
      '.....##',
      '....##.',
      '....##.',
      '...##..',
      '...##..',
      '..##...',
      '..##...',
      '..##...',
    ],
    '8': [
      '.#####.',
      '##...##',
      '##...##',
      '##...##',
      '.#####.',
      '##...##',
      '##...##',
      '##...##',
      '.#####.',
    ],
    '9': [
      '.#####.',
      '##...##',
      '##...##',
      '##...##',
      '.######',
      '.....##',
      '.....##',
      '.##..##',
      '..####.',
    ],
    '.': ['...', '...', '...', '...', '...', '...', '...', '##.', '##.'],
    ':': ['...', '...', '##.', '##.', '...', '##.', '##.', '...', '...'],
    '-': ['.....', '.....', '.....', '.....', '#####', '.....', '.....', '.....', '.....'],
    ' ': ['...', '...', '...', '...', '...', '...', '...', '...', '...'],
  };

  static final Map<String, DotGlyph> _cache = {
    for (final entry in _source.entries) entry.key: _parse(entry.value),
  };

  static DotGlyph _parse(List<String> rows) {
    assert(rows.length == DotGlyph.rows, 'every glyph must be 9 rows tall');
    final cols = rows.first.length;
    final cells = <bool>[];
    for (final row in rows) {
      assert(row.length == cols, 'glyph rows must all be the same width');
      for (var c = 0; c < cols; c++) {
        cells.add(row.codeUnitAt(c) == 0x23); // '#'
      }
    }
    return DotGlyph(cols, cells);
  }

  /// Returns the glyph for [char], falling back to a blank so an unexpected
  /// character leaves a gap instead of throwing mid-paint.
  static DotGlyph glyph(String char) => _cache[char] ?? _cache[' ']!;

  static bool supports(String char) => _cache.containsKey(char);

  /// Total column count for [text], including inter-glyph gaps.
  static int measureCols(String text) {
    if (text.isEmpty) return 0;
    var cols = 0;
    for (var i = 0; i < text.length; i++) {
      cols += glyph(text[i]).cols;
      if (i != text.length - 1) cols += glyphGapCols;
    }
    return cols;
  }
}
