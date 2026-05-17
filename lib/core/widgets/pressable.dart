import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion/motion.dart';

enum PressHaptic { none, selection, light, medium }

/// Scale-and-haptic press feedback. Every tappable surface in the app wraps in
/// this — docs/ANIMATION_SPEC.md 6.6 has no exceptions.
///
/// Press-down is a quick ease-out; release overshoots with `elasticOut`, which
/// is what makes a tap feel like it sprang back rather than merely un-scaled.
class Pressable extends StatefulWidget {
  const Pressable({
    required this.child,
    this.onTap,
    this.pressedScale = 0.96,
    this.haptic = PressHaptic.selection,
    this.semanticLabel,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final double pressedScale;
  final PressHaptic haptic;
  final String? semanticLabel;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 120),
    reverseDuration: const Duration(milliseconds: 220),
  );

  late final Animation<double> _scale = _controller.drive(
    Tween(begin: 1.0, end: widget.pressedScale).chain(
      CurveTween(curve: Curves.easeOut),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _fire() {
    switch (widget.haptic) {
      case PressHaptic.none:
        break;
      case PressHaptic.selection:
        HapticFeedback.selectionClick();
      case PressHaptic.light:
        HapticFeedback.lightImpact();
      case PressHaptic.medium:
        HapticFeedback.mediumImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final instant = MotionScale.of(context) == 0;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled && !instant ? (_) => _controller.forward() : null,
        onTapUp: enabled && !instant ? (_) => _release() : null,
        onTapCancel: enabled && !instant ? _release : null,
        onTap: enabled
            ? () {
                _fire();
                widget.onTap!();
              }
            : null,
        child: ScaleTransition(scale: _scale, child: widget.child),
      ),
    );
  }

  void _release() {
    // elasticOut only on the way back, so the bounce reads as release.
    _controller.animateBack(0, curve: Curves.elasticOut);
  }
}
