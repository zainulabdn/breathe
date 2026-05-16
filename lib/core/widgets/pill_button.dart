import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text.dart';
import 'pressable.dart';

/// The primary action pill — "Continue", "Finish Test".
class PillButton extends StatelessWidget {
  const PillButton({
    required this.label,
    required this.onTap,
    this.filled = true,
    this.expand = true,
    this.background,
    this.foreground,
    this.border,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final bool filled;
  final bool expand;

  /// Overrides for contexts that already sit on a coloured surface, where the
  /// default white pill would blow out.
  final Color? background;
  final Color? foreground;
  final Color? border;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    return Pressable(
      onTap: onTap,
      haptic: PressHaptic.light,
      semanticLabel: label,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 220),
        opacity: enabled ? 1 : 0.4,
        child: Container(
          width: expand ? double.infinity : null,
          height: 54,
          alignment: Alignment.center,
          padding: expand ? null : const EdgeInsets.symmetric(horizontal: 28),
          decoration: BoxDecoration(
            color: background ??
                (filled ? AppColors.textPrimary : AppColors.surfaceHigh),
            borderRadius: BorderRadius.circular(27),
            border: border == null ? null : Border.all(color: border!),
          ),
          child: Text(
            label,
            style: AppText.button.copyWith(
              color: foreground ??
                  (filled ? AppColors.bg : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }
}
