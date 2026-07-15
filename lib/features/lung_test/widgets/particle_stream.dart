import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../dots/dot_atlas.dart';

/// Dots detaching and falling as the user exhales, over the sparse static rows
/// the mock shows below the readout.
///
/// Spawn rate follows flow, so the stream visibly answers how hard you are
/// blowing — it is the fastest feedback on the screen, ahead of the readout,
/// which is smoothed.
class ParticleStream extends StatefulWidget {
  const ParticleStream({
    required this.flow,
    this.maxParticles = 120,
    super.key,
  });

  /// 0–1 smoothed flow.
  final ValueListenable<double> flow;

  final int maxParticles;

  @override
  State<ParticleStream> createState() => _ParticleStreamState();
}

class _Particle {
  _Particle(this.x, this.y, this.vx, this.vy, this.size);
  double x, y, vx, vy, size;
  double age = 0;
  static const double lifetime = 1.2;
}

class _ParticleStreamState extends State<ParticleStream>
    with SingleTickerProviderStateMixin {
  static const double _gravity = 380;

  final List<_Particle> _particles = [];
  final _random = math.Random(11);
  final ValueNotifier<int> _repaint = ValueNotifier(0);

  late final Ticker _ticker = createTicker(_onTick);
  Duration _last = Duration.zero;
  double _spawnCredit = 0;
  Size _size = Size.zero;

  @override
  void initState() {
    super.initState();
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _repaint.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = _last == Duration.zero
        ? 1 / 60
        : ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;

    final flow = widget.flow.value;
    final allowed = MotionScale.ambientAllowed(context);

    if (allowed && _size.width > 0) {
      // Up to ~70 particles/sec at full flow. Fractional credit carries over so
      // low rates still spawn, just less often.
      _spawnCredit += flow * 70 * dt;
      while (_spawnCredit >= 1 && _particles.length < widget.maxParticles) {
        _spawnCredit -= 1;
        _particles.add(
          _Particle(
            _size.width * (0.18 + _random.nextDouble() * 0.64),
            -4,
            (_random.nextDouble() - 0.5) * 26,
            20 + _random.nextDouble() * 40,
            2 + _random.nextDouble() * 1.8,
          ),
        );
      }
    }

    for (var i = _particles.length - 1; i >= 0; i--) {
      final p = _particles[i];
      p.age += dt;
      if (p.age >= _Particle.lifetime || p.y > _size.height + 12) {
        _particles.removeAt(i);
        continue;
      }
      p.vy += _gravity * dt;
      p.x += p.vx * dt;
      p.y += p.vy * dt;
    }

    _repaint.value++;
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: LayoutBuilder(
        builder: (context, constraints) {
          _size = constraints.biggest;
          return CustomPaint(
            size: _size,
            isComplex: true,
            painter: _StreamPainter(
              repaint: _repaint,
              particles: _particles,
            ),
          );
        },
      ),
    );
  }
}

class _StreamPainter extends CustomPainter {
  _StreamPainter({required Listenable repaint, required this.particles})
      : super(repaint: repaint);

  final List<_Particle> particles;

  final DotBatch _core = DotBatch();
  final DotBatch _bloom = DotBatch(soft: true);

  @override
  void paint(Canvas canvas, Size size) {
    _core.reset();
    _bloom.reset();

    _paintStaticRows(size);

    for (final p in particles) {
      // Full brightness, then fade over the last third of the life.
      final remaining = 1 - p.age / _Particle.lifetime;
      final opacity = remaining > 0.33 ? 1.0 : remaining / 0.33;

      _bloom.add(
        x: p.x,
        y: p.y,
        diameter: p.size * 4,
        color: AppColors.textPrimary,
        opacity: opacity * 0.30,
      );
      _core.add(
        x: p.x,
        y: p.y,
        diameter: p.size,
        color: AppColors.textPrimary,
        opacity: opacity,
      );
    }

    _bloom.paint(canvas);
    _core.paint(canvas);
  }

  /// The sparse rows under the readout in the mock — density and brightness
  /// both thin out downward, so the field reads as dissipating rather than
  /// as a second grid.
  void _paintStaticRows(Size size) {
    const rows = 5;
    for (var r = 0; r < rows; r++) {
      final t = r / (rows - 1);
      final y = size.height * (0.10 + 0.72 * t);
      final count = (9 - r * 1.6).round();
      if (count <= 0) continue;
      final spread = size.width * (0.42 - 0.06 * r);

      for (var i = 0; i < count; i++) {
        final f = count == 1 ? 0.5 : i / (count - 1);
        _core.add(
          x: size.width / 2 + (f - 0.5) * 2 * spread,
          y: y,
          diameter: 2.4,
          color: AppColors.textPrimary,
          opacity: 0.20 * (1 - t * 0.7),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StreamPainter oldDelegate) => true;
}
