import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'pressable.dart';

/// The 44x44 circular buttons flanking the app bar. 44 is both the mock's size
/// and the minimum comfortable tap target, so the hit box needs no padding.
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
    this.size = 44,
    this.iconSize = 18,
    this.background = AppColors.surfaceHigh,
    this.foreground = AppColors.textPrimary,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String semanticLabel;
  final double size;
  final double iconSize;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.92,
      semanticLabel: semanticLabel,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: background, shape: BoxShape.circle),
        child: Icon(icon, size: iconSize, color: foreground),
      ),
    );
  }
}
