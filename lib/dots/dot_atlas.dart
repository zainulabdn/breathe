import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// A single white circle texture plus a reusable batch buffer.
///
/// Every dot in this app — glyph cells, lung cloud, particles, gauges — is one
/// sprite from this atlas, submitted through [DotBatch] as a single
/// `drawRawAtlas` call. See docs/ANIMATION_SPEC.md §0.
///
/// The naive alternative (a `drawCircle` per dot) costs one draw call each and
/// falls over somewhere around 400 dots on a mid-range Android; the test screen
/// needs ~1500.
abstract final class DotAtlas {
  static const double _texSize = 32;
  static const double _circleDiameter = 30; // 1px padding for antialiasing

  static ui.Image? _image;
  static ui.Image? _glow;

  static bool get isReady => _image != null && _glow != null;

  /// Hard-edged dot, for the dots themselves.
  static ui.Image get image => _image!;

  /// Soft radial falloff, for bloom passes.
  ///
  /// Scaling the hard circle up and fading it does *not* read as glow — at
  /// realistic dot spacings each "glow" resolves as a flat disc with a visible
  /// rim, which looks like a dark halo ring around every dot on a black ground.
  /// A gradient sprite is the only thing that actually falls off.
  static ui.Image get glow => _glow!;

  /// Scale factor that renders a dot of [diameter] logical pixels.
  static double scaleFor(double diameter) => diameter / _circleDiameter;

  /// The glow sprite fades to nothing at its edge, so its extent is the full
  /// texture rather than the inset circle.
  static double glowScaleFor(double diameter) => diameter / _texSize;

  static ui.Picture _drawDot() {
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder).drawCircle(
      const Offset(_texSize / 2, _texSize / 2),
      _circleDiameter / 2,
      Paint()
        ..color = const Color(0xFFFFFFFF)
        ..isAntiAlias = true,
    );
    return recorder.endRecording();
  }

  static ui.Picture _drawGlow() {
    final recorder = ui.PictureRecorder();
    const rect = Rect.fromLTWH(0, 0, _texSize, _texSize);
    ui.Canvas(recorder).drawRect(
      rect,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFFFFFFFF), Color(0x00FFFFFF)],
          stops: [0.0, 1.0],
        ).createShader(rect),
    );
    return recorder.endRecording();
  }

  /// Must be awaited before the first frame. Called from `main()`.
  static Future<void> warmUp() async {
    const size = _texSize ~/ 1;
    _image ??= await _drawDot().toImage(size, size);
    _glow ??= await _drawGlow().toImage(size, size);
  }

  /// Synchronous variant for tests, which cannot await before pumping.
  static void warmUpSync() {
    const size = _texSize ~/ 1;
    _image ??= _drawDot().toImageSync(size, size);
    _glow ??= _drawGlow().toImageSync(size, size);
  }
}

/// Growable, reusable buffers for one `drawRawAtlas` submission.
///
/// Create one per painter and [reset] it each frame rather than allocating —
/// at 120fps with 1500 dots, per-frame allocation of three typed lists is
/// enough garbage to show up as jank.
class DotBatch {
  /// [soft] selects the glow sprite instead of the hard dot — use it for the
  /// bloom pass that every dot surface draws underneath its core pass.
  DotBatch({this.soft = false});

  final bool soft;

  Float32List _transforms = Float32List(0);
  Float32List _rects = Float32List(0);
  Int32List _colors = Int32List(0);
  int _count = 0;

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  int get length => _count;
  bool get isEmpty => _count == 0;

  void reset() => _count = 0;

  void _ensure(int capacity) {
    if (_colors.length >= capacity) return;
    var next = _colors.isEmpty ? 64 : _colors.length;
    while (next < capacity) {
      next *= 2;
    }
    _transforms = Float32List(next * 4)..setRange(0, _count * 4, _transforms);
    _rects = Float32List(next * 4)..setRange(0, _count * 4, _rects);
    _colors = Int32List(next)..setRange(0, _count, _colors);
  }

  /// Adds one dot centred on ([x], [y]).
  ///
  /// [opacity] is folded into the sprite colour rather than applied as a layer,
  /// so per-dot fades cost nothing extra.
  void add({
    required double x,
    required double y,
    required double diameter,
    required Color color,
    double opacity = 1.0,
  }) {
    if (diameter <= 0 || opacity <= 0.004) return;
    _ensure(_count + 1);

    final s = soft
        ? DotAtlas.glowScaleFor(diameter)
        : DotAtlas.scaleFor(diameter);
    final i4 = _count * 4;

    // RSTransform with rotation 0, anchored at the texture centre so that
    // (x, y) is the dot's centre rather than its top-left corner.
    const anchor = 16.0; // _texSize / 2
    _transforms[i4] = s; // scos
    _transforms[i4 + 1] = 0; // ssin
    _transforms[i4 + 2] = x - s * anchor; // tx
    _transforms[i4 + 3] = y - s * anchor; // ty

    _rects[i4] = 0;
    _rects[i4 + 1] = 0;
    _rects[i4 + 2] = 32;
    _rects[i4 + 3] = 32;

    _colors[_count] = color.withValues(alpha: color.a * opacity).toARGB32();
    _count++;
  }

  void paint(Canvas canvas) {
    if (_count == 0 || !DotAtlas.isReady) return;
    canvas.drawRawAtlas(
      soft ? DotAtlas.glow : DotAtlas.image,
      Float32List.view(_transforms.buffer, 0, _count * 4),
      Float32List.view(_rects.buffer, 0, _count * 4),
      Int32List.view(_colors.buffer, 0, _count),
      BlendMode.modulate,
      null,
      _paint,
    );
  }
}
