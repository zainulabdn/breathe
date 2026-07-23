import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../../../domain/session/breath_pattern.dart';
import '../widgets/safety_sheet.dart';

class PatternPickerView extends StatefulWidget {
  const PatternPickerView({super.key});

  @override
  State<PatternPickerView> createState() => _PatternPickerViewState();
}

class _PatternPickerViewState extends State<PatternPickerView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..forward();

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  Future<void> _open(BreathPattern pattern) async {
    // Rapid-breathing and long-hold patterns must be acknowledged before they
    // can run. See docs/BREATH_ENGINE.md §7.
    if (pattern.needsSafetyNotice) {
      final accepted = await SafetySheet.show(context, pattern);
      if (accepted != true) return;
    }
    if (mounted) context.push('${Routes.session}/${pattern.id}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.arrow_back,
                      onTap: () => context.pop(),
                      semanticLabel: 'Back',
                    ),
                    const Expanded(
                      child: Text(
                        'Breathe',
                        textAlign: TextAlign.center,
                        style: AppText.titleBar,
                      ),
                    ),
                    const SizedBox(width: 44),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: BreathPattern.presets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pattern = BreathPattern.presets[index];
                    return StaggeredEntrance(
                      controller: _entrance,
                      index: index,
                      child: _PatternCard(
                        pattern: pattern,
                        accent: _accents[index % _accents.length],
                        onTap: () => _open(pattern),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _accents = [
    AppColors.indigoPeek,
    AppColors.magenta,
    AppColors.violet,
    AppColors.volumeAmber,
  ];
}

class _PatternCard extends StatelessWidget {
  const _PatternCard({
    required this.pattern,
    required this.accent,
    required this.onTap,
  });

  final BreathPattern pattern;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final minutes = (pattern.totalSeconds(pattern.defaultCycles) / 60).round();

    return Pressable(
      onTap: onTap,
      pressedScale: 0.98,
      haptic: PressHaptic.light,
      semanticLabel: '${pattern.name}, $minutes minutes',
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: accent.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(pattern.name, style: AppText.sectionLabel),
                const Spacer(),
                Text(pattern.summary, style: AppText.unitLabel),
              ],
            ),
            const SizedBox(height: 10),
            Text(pattern.description, style: AppText.hint),
            const SizedBox(height: 14),
            Row(
              children: [
                Text('$minutes min', style: AppText.unitLabel),
                const SizedBox(width: 12),
                Text('${pattern.defaultCycles} cycles',
                    style: AppText.unitLabel),
                if (pattern.needsSafetyNotice) ...[
                  const Spacer(),
                  Icon(Icons.info_outline,
                      size: 15, color: AppColors.textTertiary),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
