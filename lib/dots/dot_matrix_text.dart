import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion/motion.dart';
import '../core/theme/app_colors.dart';
import 'dot_atlas.dart';
import 'dot_glyph_font.dart';

/// The LED-style readout: "3.3", "0.0", the cycle counter.
///
/// Changing [value] morphs rather than swaps — dots that stay lit hold their
/// position, dots that switch off fade and shrink, dots that switch on pop in.
/// See docs/ANIMATION_SPEC.md 2.6.
class DotMatrixText extends StatefulWidget {
  const DotMatrixText({
    required this.value,
    this.cellSize = 6,
    this.cellGap = 3,
    this.litColor = AppColors.textPrimary,
    this.unlitColor = AppColors.dotOff,
    this.showUnlitGrid = true,
    this.glow = 0.55,
    this.shimmer = 0.16,
    this.semanticsLabel,
    super.key,
  });

  final String value;
  final double cellSize;
  final double cellGap;
  final Color litColor;
  final Color unlitColor;

  /// Draws the faint backdrop of unlit cells. This is most of the design's
  /// texture — off only for tiny inline readouts.
  final bool showUnlitGrid;

  /// Bloom strength, 0–1. Painted as a second, larger, dimmer atlas pass.
  final double glow;

  /// Slow per-dot brightness drift, 0–1.
  ///
  /// A readout showing a number that will not change for hours is otherwise a
  /// still image sitting in the middle of an animated screen. This gives it a
  /// pulse without inventing data — the value is untouched, only its glow
  /// breathes.
  ///
  /// Note for tests: this loops forever, so `pumpAndSettle` will time out on
  /// any tree containing one. Pass 0 in tests that need to settle, and in
  /// goldens, where a shimmering frame is not reproducible anyway.
  final double shimmer;

  /// Screen readers cannot read painted dots. Defaults to [value], but pass a
  /// unit-qualified string ("3.3 liters") wherever the number has one.
  final String? semanticsLabel;

  @override
  State<DotMatrixText> createState() => _DotMatrixTextState();
}

// Two controllers (morph + ambient shimmer), so this cannot be a
// SingleTickerProviderStateMixin.
class _DotMatrixTextState extends State<DotMatrixText>
    with TickerProviderStateMixin {
  static const Duration _morphDuration = Duration(milliseconds: 450);

  late final AnimationController _morph = AnimationController(
    vsync: this,
    duration: _morphDuration,
    value: 1,
  );

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );

  List<Offset> _holding = const [];
  List<Offset> _entering = const [];
  List<Offset> _exiting = const [];
  List<Offset> _grid = const [];
  Size _size = Size.zero;

  double get _pitch => widget.cellSize + widget.cellGap;

  @override
  void initState() {
    super.initState();
    _rebuildLayout(previous: null);
  }

  @override
  void didUpdateWidget(DotMatrixText oldWidget) {
    super.didUpdateWidget(oldWidget);
    final geometryChanged = oldWidget.cellSize != widget.cellSize ||
        oldWidget.cellGap != widget.cellGap;
    if (oldWidget.value == widget.value && !geometryChanged) return;

    if (geometryChanged) {
      // Geometry changes are a re-layout, not a value morph — snap.
      _rebuildLayout(previous: null);
      _morph.value = 1;
      return;
    }

    _rebuildLayout(previous: oldWidget.value);
    _morph
      ..duration = _morphDuration.scaled(context)
      ..forward(from: 0);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wanted = widget.shimmer > 0 && MotionScale.ambientAllowed(context);
    if (wanted && !_ambient.isAnimating) {
      _ambient.repeat();
    } else if (!wanted && _ambient.isAnimating) {
      _ambient
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _morph.dispose();
    _ambient.dispose();
    super.dispose();
  }

  /// Lays out [widget.value], and if [previous] is given, diffs the two cell
  /// sets into hold / enter / exit buckets.
  void _rebuildLayout({required String? previous}) {
    final cols = DotGlyphFont.measureCols(widget.value);
    _size = Size(
      cols * _pitch - widget.cellGap,
      DotGlyph.rows * _pitch - widget.cellGap,
    );

    final grid = <Offset>[];
    final next = _layout(widget.value, _size, grid: grid);
    _grid = grid;

    if (previous == null) {
      _holding = next;
      _entering = const [];
      _exiting = const [];
      return;
    }

    // Both strings are centred in the same box, so unchanged cells land on
    // identical coordinates and match exactly. Differing widths shift the old
    // glyphs, which just means more dots animate — still reads correctly.
    final old = _layout(previous, _size);
    final oldKeys = {for (final o in old) _key(o): o};
    final newKeys = {for (final o in next) _key(o): o};

    final holding = <Offset>[];
    final entering = <Offset>[];
    final exiting = <Offset>[];

    for (final entry in newKeys.entries) {
      (oldKeys.containsKey(entry.key) ? holding : entering).add(entry.value);
    }
    for (final entry in oldKeys.entries) {
      if (!newKeys.containsKey(entry.key)) exiting.add(entry.value);
    }

    _holding = holding;
    _entering = entering;
    _exiting = exiting;
  }

  /// Quantises to a quarter pixel so float drift never breaks a match.
  static int _key(Offset o) =>
      (o.dx * 4).round() * 1000003 + (o.dy * 4).round();

  /// Centres [text] inside [box] and returns its lit dot centres. When [grid]
  /// is supplied it is filled with every cell centre, lit or not.
  List<Offset> _layout(String text, Size box, {List<Offset>? grid}) {
    final cols = DotGlyphFont.measureCols(text);
    final width = cols * _pitch - widget.cellGap;
    final height = DotGlyph.rows * _pitch - widget.cellGap;
    final originX = (box.width - width) / 2;
    final originY = (box.height - height) / 2;
    final half = widget.cellSize / 2;

    final lit = <Offset>[];
    var col = 0;
    for (var i = 0; i < text.length; i++) {
      final glyph = DotGlyphFont.glyph(text[i]);
      for (var r = 0; r < DotGlyph.rows; r++) {
        for (var c = 0; c < glyph.cols; c++) {
          final offset = Offset(
            originX + (col + c) * _pitch + half,
            originY + r * _pitch + half,
          );
          grid?.add(offset);
          if (glyph.isLit(c, r)) lit.add(offset);
        }
      }
      col += glyph.cols + (i == text.length - 1 ? 0 : DotGlyphFont.glyphGapCols);
    }
    return lit;
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticsLabel ?? widget.value,
      excludeSemantics: true,
      child: RepaintBoundary(
        child: CustomPaint(
          size: _size,
          isComplex: true,
          painter: _GlyphPainter(
            progress: _morph,
            ambient: _ambient,
            holding: _holding,
            entering: _entering,
            exiting: _exiting,
            grid: widget.showUnlitGrid ? _grid : const [],
            cellSize: widget.cellSize,
            litColor: widget.litColor,
            unlitColor: widget.unlitColor,
            glow: widget.glow,
            shimmer: widget.shimmer,
          ),
        ),
      ),
    );
  }
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter({
    required this.progress,
    required this.ambient,
    required this.holding,
    required this.entering,
    required this.exiting,
    required this.grid,
    required this.cellSize,
    required this.litColor,
    required this.unlitColor,
    required this.glow,
    required this.shimmer,
  }) : super(repaint: Listenable.merge([progress, ambient]));

  final Animation<double> progress;
  final Animation<double> ambient;
  final double shimmer;
  final List<Offset> holding;
  final List<Offset> entering;
  final List<Offset> exiting;
  final List<Offset> grid;
  final double cellSize;
  final Color litColor;
  final Color unlitColor;
  final double glow;

  static const _exitCurve = Interval(0.0, 0.4, curve: Curves.easeIn);
  static const _enterCurve = Interval(0.3, 1.0, curve: Curves.easeOutBack);

  final DotBatch _bloom = DotBatch(soft: true);
  final DotBatch _core = DotBatch();

  @override
  void paint(Canvas canvas, Size size) {
    _bloom.reset();
    _core.reset();

    final t = progress.value;
    final exitT = _exitCurve.transform(t);
    final enterT = _enterCurve.transform(t);

    for (final dot in grid) {
      _core.add(x: dot.dx, y: dot.dy, diameter: cellSize, color: unlitColor);
    }

    for (var i = 0; i < holding.length; i++) {
      _emit(holding[i], 1.0, _shimmerAt(i));
    }
    for (final dot in exiting) {
      _emit(dot, 1.0 - exitT, 1.0 - exitT);
    }
    for (final dot in entering) {
      // Pops in from 40% — easeOutBack overshoots past 1.0, which is the pop.
      _emit(dot, 0.4 + 0.6 * enterT, enterT.clamp(0.0, 1.0));
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  /// Deterministic phase per dot, so the shimmer travels across the glyph
  /// instead of every dot pulsing in unison.
  double _shimmerAt(int index) {
    if (shimmer <= 0) return 1;
    final phase = ((index * 2654435761) % 997) / 997.0;
    return (1 - shimmer +
            shimmer *
                (0.5 +
                    0.5 *
                        math.sin((ambient.value + phase) * 2 * math.pi)))
        .clamp(0.0, 1.0);
  }

  void _emit(Offset dot, double scale, double opacity) {
    if (glow > 0) {
      _bloom.add(
        x: dot.dx,
        y: dot.dy,
        diameter: cellSize * scale * 3.4,
        color: litColor,
        // Higher than it looks: the glow sprite falls off to zero at its rim,
        // so its average coverage is far below this peak value.
        opacity: opacity * glow * 0.42,
      );
    }
    _core.add(
      x: dot.dx,
      y: dot.dy,
      diameter: cellSize * scale,
      color: litColor,
      opacity: opacity,
    );
  }

  @override
  bool shouldRepaint(_GlyphPainter old) =>
      old.holding != holding ||
      old.entering != entering ||
      old.exiting != exiting ||
      old.grid != grid ||
      old.cellSize != cellSize ||
      old.litColor != litColor ||
      old.unlitColor != unlitColor ||
      old.glow != glow;
}
