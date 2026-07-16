import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../dots/dot_atlas.dart';
import '../controller/breath_test_controller.dart';
import 'breath_slider.dart';

/// The blurred navy sheet at the bottom of the test screen.
///
/// The mock labels its two flanking numbers "CO2" and "O". No phone sensor can
/// measure either — there is no gas sensor in an iPhone — so they are relabelled
/// to quantities the microphone genuinely produces: exhale duration and peak
/// flow. Same layout, same weight, nothing invented. See
/// docs/BREATH_ENGINE.md §6.
class TestSheet extends StatelessWidget {
  const TestSheet({required this.reading, super.key});

  final BreathReading reading;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.sheetNavy,
                AppColors.sheetNavy.withValues(alpha: 0.82),
              ],
            ),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Stat(
                    value: reading.exhaleSeconds.toStringAsFixed(2),
                    label: 'SEC',
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 16,
                          child: _DotCluster(),
                        ),
                        const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: Tween(
                                begin: const Offset(0, 0.45),
                                end: Offset.zero,
                              ).animate(animation),
                              child: child,
                            ),
                          ),
                          child: Text(
                            reading.hint.label,
                            key: ValueKey(reading.hint),
                            style: AppText.hint.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _Stat(
                    value: (reading.peakFlow * 2).toStringAsFixed(2),
                    label: 'PEAK',
                    alignEnd: true,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BreathSlider(
                progress: reading.fillFraction,
                flow: reading.flow,
                // The yellow segment runs ahead of the knob by the current
                // flow, so it is a live reading rather than a second copy of
                // the knob's position — passing fillFraction here meant the
                // trail had zero length and never appeared at all.
                peakProgress:
                    (reading.fillFraction + reading.flow * 0.28).clamp(0.0, 1.0),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.value,
    required this.label,
    this.alignEnd = false,
  });

  final String value;
  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        crossAxisAlignment:
            alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: AppText.cardLabel.copyWith(fontSize: 15),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppText.unitLabel.copyWith(
              fontSize: 10,
              letterSpacing: 0.8,
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

/// The small pyramid of dots above the hint in the mock.
class _DotCluster extends StatelessWidget {
  const _DotCluster();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _ClusterPainter());
  }
}

class _ClusterPainter extends CustomPainter {
  final DotBatch _dots = DotBatch();

  @override
  void paint(Canvas canvas, Size size) {
    _dots.reset();
    const rows = 3;
    for (var r = 0; r < rows; r++) {
      final count = r + 2;
      final y = size.height * (0.18 + 0.32 * r);
      for (var i = 0; i < count; i++) {
        final f = count == 1 ? 0.5 : i / (count - 1);
        _dots.add(
          x: size.width * (0.5 + (f - 0.5) * (0.30 + 0.22 * r)),
          y: y,
          diameter: 2.2,
          color: Colors.white,
          opacity: 0.75 - r * 0.15,
        );
      }
    }
    _dots.paint(canvas);
  }

  @override
  bool shouldRepaint(_ClusterPainter oldDelegate) => false;
}
