import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable.dart';
import 'painters/dotted_arc_painter.dart';

/// The "Breath Volume" tile: a value plus a dotted arc gauge.
class GaugeTile extends StatefulWidget {
  const GaugeTile({
    required this.label,
    required this.value,
    required this.unit,
    required this.fraction,
    this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final String unit;

  /// 0–1 position on the gauge.
  final double fraction;

  final VoidCallback? onTap;

  @override
  State<GaugeTile> createState() => _GaugeTileState();
}

class _GaugeTileState extends State<GaugeTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _reveal = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: widget.onTap,
      pressedScale: 0.97,
      semanticLabel: '${widget.label}, ${widget.value} ${widget.unit}',
      child: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.bottomLeft,
            end: Alignment.topRight,
            colors: [AppColors.volumeRed, AppColors.volumeAmber],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: AppColors.volumeRed.withValues(alpha: 0.3),
              blurRadius: 32,
              spreadRadius: -12,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gauge sits behind the text, bled to the tile's right edge.
            Positioned(
              right: 10,
              bottom: 14,
              width: 84,
              height: 44,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: DottedArcPainter(
                    animation: _reveal,
                    value: widget.fraction,
                    // White, not acid yellow — in the mock this gauge is a
                    // quiet texture behind the number, not a second focal point.
                    litColor: Colors.white,
                    dotCount: 24,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.label, style: AppText.cardLabel),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.value, style: AppText.tileNumber),
                      const SizedBox(width: 3),
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(widget.unit, style: AppText.unitLabel),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
