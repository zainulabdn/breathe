import 'package:flutter/material.dart';

/// Single point of control for reduced motion (docs/ANIMATION_SPEC.md §7).
///
/// Every animated widget multiplies its durations by [MotionScale.of]. That
/// keeps the accessibility behaviour in one place instead of scattering
/// `disableAnimations` checks through forty widgets — and it doubles as a debug
/// knob: set the scale to 8 to inspect an animation in slow motion.
class MotionScale extends InheritedWidget {
  const MotionScale({required this.scale, required super.child, super.key});

  final double scale;

  static double of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<MotionScale>();
    return widget?.scale ?? 1.0;
  }

  /// True when ambient/looping decoration should not run at all.
  static bool ambientAllowed(BuildContext context) => of(context) > 0;

  @override
  bool updateShouldNotify(MotionScale oldWidget) => scale != oldWidget.scale;
}

/// Installs a [MotionScale] driven by the platform's reduce-motion setting.
class AppMotion extends StatelessWidget {
  const AppMotion({required this.child, this.debugScale = 1.0, super.key});

  final Widget child;
  final double debugScale;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return MotionScale(scale: reduced ? 0.0 : debugScale, child: child);
  }
}

extension MotionDuration on Duration {
  /// Scales this duration by the ambient [MotionScale].
  Duration scaled(BuildContext context) {
    final scale = MotionScale.of(context);
    if (scale == 1.0) return this;
    return Duration(microseconds: (inMicroseconds * scale).round());
  }
}
