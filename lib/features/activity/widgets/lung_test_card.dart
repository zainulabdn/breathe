import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable.dart';
import '../../../dots/dot_matrix_text.dart';
import '../model/lung_metric.dart';
import 'painters/card_background_painter.dart';

/// The hero card. Its readout is the same [DotMatrixText] used on the test
/// screen, which is what lets the two share a Hero flight in Phase 5.
class LungTestCard extends StatefulWidget {
  const LungTestCard({
    required this.metric,
    this.onTap,
    this.radius = 40,
    super.key,
  });

  final LungMetric metric;
  final VoidCallback? onTap;
  final double radius;

  @override
  State<LungTestCard> createState() => _LungTestCardState();
}

class _LungTestCardState extends State<LungTestCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(
      seconds: CardBackgroundPainter.periodSeconds ~/ 1,
    ),
  );

  bool _revealed = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionScale.ambientAllowed(context)) {
      if (!_ambient.isAnimating) _ambient.repeat();
    } else {
      _ambient.stop();
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final metric = widget.metric;

    return Pressable(
      onTap: widget.onTap,
      pressedScale: 0.97,
      haptic: PressHaptic.light,
      semanticLabel: '${metric.metricName}, ${metric.semanticsValue}',
      child: RepaintBoundary(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            boxShadow: [
              BoxShadow(
                color: metric.glowColor.withValues(alpha: 0.35),
                blurRadius: 48,
                spreadRadius: -8,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(widget.radius),
            child: CustomPaint(
              painter: CardBackgroundPainter(
                animation: _ambient,
                gradient: metric.gradient,
                radius: widget.radius,
                bloomColor: metric.glowColor,
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Text(metric.cardLabel, style: AppText.cardLabel),
                        const Spacer(),
                        _EyeToggle(
                          revealed: _revealed,
                          onTap: () =>
                              setState(() => _revealed = !_revealed),
                        ),
                      ],
                    ),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          DotMatrixText(
                            // Hiding swaps to dashes, so the morph animation
                            // carries the reveal instead of a crossfade.
                            value: _revealed
                                ? metric.value
                                : '-' * metric.value.length,
                            cellSize: 6,
                            cellGap: 3,
                            glow: 0.55,
                            semanticsLabel: _revealed
                                ? metric.semanticsValue
                                : 'Value hidden',
                          ),
                          const SizedBox(height: 10),
                          Text(metric.unit, style: AppText.unitLabel),
                        ],
                      ),
                    ),
                    // Balances the header row so the readout sits optically
                    // centred rather than mathematically centred.
                    const SizedBox(height: 26),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _EyeToggle extends StatelessWidget {
  const _EyeToggle({required this.revealed, required this.onTap});

  final bool revealed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.85,
      semanticLabel: revealed ? 'Hide value' : 'Show value',
      child: SizedBox(
        width: 28,
        height: 28,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: Icon(
            revealed ? Icons.visibility_outlined : Icons.visibility_off_outlined,
            key: ValueKey(revealed),
            size: 18,
            color: AppColors.textPrimary.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
