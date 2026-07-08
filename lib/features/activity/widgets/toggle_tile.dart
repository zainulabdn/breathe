import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';

/// The "Training" tile with a spring-driven switch.
///
/// Uses a real [SpringSimulation] rather than a curve so the knob's overshoot
/// is physical — a flung toggle settles differently from a tapped one, which
/// is the detail that separates this from a stock Switch.
class ToggleTile extends StatefulWidget {
  const ToggleTile({
    required this.label,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<ToggleTile> createState() => _ToggleTileState();
}

class _ToggleTileState extends State<ToggleTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _knob = AnimationController.unbounded(
    vsync: this,
    value: widget.value ? 1 : 0,
  );

  static final SpringDescription _spring = SpringDescription.withDampingRatio(
    mass: 1,
    stiffness: 500,
    ratio: 0.72,
  );

  @override
  void didUpdateWidget(ToggleTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    _animateTo(widget.value ? 1 : 0);
  }

  void _animateTo(double target) {
    if (MotionScale.of(context) == 0) {
      _knob.value = target;
      return;
    }
    _knob.animateWith(
      SpringSimulation(_spring, _knob.value, target, _knob.velocity),
    );
  }

  @override
  void dispose() {
    _knob.dispose();
    super.dispose();
  }

  void _toggle() {
    HapticFeedback.lightImpact();
    widget.onChanged(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: widget.value,
      label: widget.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _toggle,
        child: AnimatedBuilder(
          animation: _knob,
          builder: (context, child) {
            final t = _knob.value.clamp(0.0, 1.0);
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: Color.lerp(
                  AppColors.trainingBlue.withValues(alpha: 0.55),
                  AppColors.trainingBlue,
                  t,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  // Glow ramps with the on-state.
                  BoxShadow(
                    color: AppColors.trainingGlow.withValues(alpha: 0.42 * t),
                    blurRadius: 32,
                    spreadRadius: -10,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppText.cardLabel,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _Knob(t: _knob.value),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Knob extends StatelessWidget {
  const _Knob({required this.t});

  /// Unclamped so the spring's overshoot pushes the knob slightly past the end
  /// of the track, exactly as a physical switch would.
  final double t;

  static const double _width = 46;
  static const double _height = 27;
  static const double _knobSize = 21;

  @override
  Widget build(BuildContext context) {
    final travel = _width - _knobSize - 6;
    final clamped = t.clamp(0.0, 1.0);

    return Container(
      width: _width,
      height: _height,
      decoration: BoxDecoration(
        color: Color.lerp(
          Colors.white.withValues(alpha: 0.16),
          AppColors.trainingGlow,
          clamped,
        ),
        borderRadius: BorderRadius.circular(_height / 2),
      ),
      child: Stack(
        children: [
          Positioned(
            left: 3 + travel * t.clamp(-0.12, 1.12),
            top: (_height - _knobSize) / 2,
            child: Container(
              width: _knobSize,
              height: _knobSize,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
