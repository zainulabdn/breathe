import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../core/widgets/pressable.dart';
import '../../../domain/session/breath_pattern.dart';

/// Acknowledgement required before a rapid-breathing or long-hold pattern runs.
///
/// Not legal boilerplate and not dismissible by tapping outside: hyperventilation
/// -style patterns genuinely cause people to faint, and the difference between a
/// scare and an injury is usually whether they were standing, driving or in
/// water. See docs/BREATH_ENGINE.md §7.
class SafetySheet extends StatelessWidget {
  const SafetySheet({required this.pattern, super.key});

  final BreathPattern pattern;

  static Future<bool?> show(BuildContext context, BreathPattern pattern) {
    return showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => SafetySheet(pattern: pattern),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        24 + MediaQuery.viewPaddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.volumeAmber, size: 22),
              const SizedBox(width: 10),
              Text('Before you start ${pattern.name}',
                  style: AppText.sectionLabel),
            ],
          ),
          const SizedBox(height: 18),
          const _Rule('Sit or lie down. Never do this driving, standing at '
              'height, or in or near water.'),
          const _Rule('Stop immediately if you feel dizzy, tingly or '
              'light-headed, and breathe normally.'),
          const _Rule('Skip it if you are pregnant, or have a heart or '
              'respiratory condition, unless your clinician says otherwise.'),
          const SizedBox(height: 22),
          PillButton(
            label: 'I understand',
            onTap: () => Navigator.of(context).pop(true),
          ),
          const SizedBox(height: 8),
          Center(
            child: Pressable(
              onTap: () => Navigator.of(context).pop(false),
              semanticLabel: 'Cancel',
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                child: Text('Not now', style: AppText.hint),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Rule extends StatelessWidget {
  const _Rule(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 7, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.volumeAmber,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
