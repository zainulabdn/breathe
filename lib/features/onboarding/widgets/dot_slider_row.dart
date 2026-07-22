import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../dots/dot_matrix_text.dart';

/// A labelled slider whose value reads out in the app's dot-matrix numerals.
///
/// Using the same readout here as on the hero card means onboarding teaches the
/// visual language before the user reaches the screens that depend on it.
class DotSliderRow extends StatelessWidget {
  const DotSliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.unit,
    this.accent = AppColors.magenta,
    super.key,
  });

  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;
  final String unit;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(child: Text(label, style: AppText.cardLabel)),
            DotMatrixText(
              value: '$value',
              cellSize: 3.4,
              cellGap: 1.6,
              glow: 0.4,
              litColor: accent,
              showUnlitGrid: false,
              semanticsLabel: '$label $value $unit',
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(unit, style: AppText.unitLabel),
            ),
          ],
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 3,
            activeTrackColor: accent,
            inactiveTrackColor: AppColors.surfaceHigh,
            thumbColor: AppColors.textPrimary,
            overlayShape: SliderComponentShape.noOverlay,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 9),
          ),
          child: Slider(
            value: value.toDouble().clamp(min.toDouble(), max.toDouble()),
            min: min.toDouble(),
            max: max.toDouble(),
            onChanged: (v) => onChanged(v.round()),
          ),
        ),
      ],
    );
  }
}
