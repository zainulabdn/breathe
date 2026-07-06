import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable.dart';
import 'painters/tick_strip_painter.dart';

/// The tall left-hand tile — "Daily Smoke, 234 D/w" in the mock.
///
/// (The mock's label reads "Daily Smook"; corrected here. Flagged rather than
/// copied, in case the typo was intentional branding.)
class StatTileTall extends StatefulWidget {
  const StatTileTall({
    required this.label,
    required this.value,
    required this.unit,
    required this.scaleValue,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String unit;

  /// 0–1 position of the highlighted tick on the scale.
  final double scaleValue;

  final VoidCallback? onTap;

  @override
  State<StatTileTall> createState() => _StatTileTallState();
}

class _StatTileTallState extends State<StatTileTall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      pressedScale: 0.97,
      semanticLabel: '${widget.label}, ${widget.value} ${widget.unit}',
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.surface,
              Color.lerp(AppColors.surface, AppColors.bg, 0.6)!,
            ],
          ),
          borderRadius: BorderRadius.circular(28),
          // Same rim-light logic as the hero card, at tile scale.
          border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.label, style: AppText.cardLabel),
            const Spacer(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.value, style: AppText.tileNumber),
                const SizedBox(width: 4),
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(widget.unit, style: AppText.unitLabel),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 14,
              width: double.infinity,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: TickStripPainter(
                    animation: _entrance,
                    value: widget.scaleValue,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
