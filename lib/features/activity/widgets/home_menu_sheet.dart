import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pressable.dart';

/// Navigation sheet behind the app bar's menu button.
///
/// Stands in for the real navigation that Phase 6 will design. Its job right
/// now is testability: every screen in the app should be one tap from here, so
/// nothing built has to be reached by guessing which card is tappable.
class HomeMenuSheet extends ConsumerWidget {
  const HomeMenuSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => const HomeMenuSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        14,
        16,
        20 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 22),
          _Item(
            icon: Icons.air_rounded,
            label: 'Breathing sessions',
            detail: 'Coherent, Box, 4-7-8, Energize',
            accent: AppColors.magenta,
            onTap: () {
              Navigator.of(context).pop();
              context.push(Routes.patterns);
            },
          ),
          _Item(
            icon: Icons.speed_rounded,
            label: 'Breath check',
            detail: 'Press and hold to blow (simulated)',
            accent: AppColors.indigoPeek,
            onTap: () {
              Navigator.of(context).pop();
              context.push(Routes.test);
            },
          ),
          _Item(
            icon: Icons.grain_rounded,
            label: 'Dot lab',
            detail: 'Tune the dot engine parameters',
            accent: AppColors.volumeAmber,
            onTap: () {
              Navigator.of(context).pop();
              context.push(Routes.dotLab);
            },
          ),
          _Item(
            icon: Icons.restart_alt_rounded,
            label: 'Replay onboarding',
            detail: 'Restarts the flow without relaunching',
            accent: AppColors.textTertiary,
            onTap: () {
              Navigator.of(context).pop();
              context.go(Routes.onboarding);
            },
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({
    required this.icon,
    required this.label,
    required this.detail,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String detail;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      haptic: PressHaptic.light,
      semanticLabel: label,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, size: 19, color: accent),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppText.cardLabel),
                  const SizedBox(height: 2),
                  Text(
                    detail,
                    style: AppText.unitLabel.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}
