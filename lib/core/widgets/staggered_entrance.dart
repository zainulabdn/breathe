import 'package:flutter/material.dart';

import '../motion/motion.dart';

/// Fade + rise entrance, staggered by [index] off a shared controller.
///
/// Written by hand rather than pulling in `flutter_animate`: the whole
/// behaviour is a fade and a translate, and owning it keeps reduced-motion
/// handling in [MotionScale] instead of split across two systems.
class StaggeredEntrance extends StatelessWidget {
  const StaggeredEntrance({
    required this.controller,
    required this.index,
    required this.child,
    this.stagger = 0.06,
    this.slide = 0.08,
    super.key,
  });

  final Animation<double> controller;
  final int index;
  final Widget child;

  /// Fraction of the parent timeline between successive children.
  final double stagger;

  /// Rise distance as a fraction of the child's own height.
  final double slide;

  @override
  Widget build(BuildContext context) {
    if (MotionScale.of(context) == 0) return child;

    final begin = (index * stagger).clamp(0.0, 0.7);
    final window = Interval(begin, (begin + 0.45).clamp(0.0, 1.0));

    // Position overshoots and settles; opacity does not — a fade that runs
    // backwards past 1 clips to nothing visible and just wastes the first
    // frames of the entrance.
    final motion = CurvedAnimation(
      parent: controller,
      curve: Interval(
        window.begin,
        window.end,
        curve: Curves.easeOutBack,
      ),
    );
    final fade = CurvedAnimation(
      parent: controller,
      curve: Interval(window.begin, window.end, curve: Curves.easeOut),
    );

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => Opacity(
        opacity: fade.value.clamp(0.0, 1.0),
        child: Transform.scale(
          // A touch of scale with the overshoot is what reads as "bouncy"
          // rather than merely "sliding".
          scale: 0.94 + 0.06 * motion.value,
          child: FractionalTranslation(
            translation: Offset(0, slide * (1 - motion.value)),
            child: child,
          ),
        ),
      ),
      child: child,
    );
  }
}
