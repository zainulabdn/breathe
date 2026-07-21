import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../core/widgets/pill_button.dart';
import '../../core/widgets/pressable.dart';
import '../../data/models/profile_draft.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../dots/assembling_dots.dart';
import '../activity/widgets/page_dots_indicator.dart';
import 'widgets/dot_slider_row.dart';

class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView>
    with TickerProviderStateMixin {
  static const _pageCount = 3;

  final _controller = PageController();
  double _page = 0;

  late final AnimationController _hero = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  ProfileDraft _profile = const ProfileDraft(
    birthYear: 1996,
    heightCm: 172,
    sex: null,
  );

  int get _age => DateTime.now().year - (_profile.birthYear ?? 1996);

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      final page = _controller.page;
      if (page != null && page != _page) setState(() => _page = page);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _hero.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    // Only the profile page gates progress, and only on sex — age and height
    // have sane defaults, but there is no defensible default for sex and it
    // changes the predicted value materially.
    if (_page.round() == 1) return _profile.sex != null;
    return true;
  }

  Future<void> _next() async {
    final index = _page.round();
    if (index < _pageCount - 1) {
      await _controller.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      return;
    }

    final repository = ref.read(onboardingRepositoryProvider);
    await repository.saveProfile(_profile);
    await repository.markComplete();
    if (mounted) context.go(Routes.home);
  }

  Future<void> _skip() async {
    final repository = ref.read(onboardingRepositoryProvider);
    await repository.markComplete();
    if (mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page.round() == _pageCount - 1;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 8, 12, 0),
                child: Pressable(
                  onTap: _skip,
                  semanticLabel: 'Skip onboarding',
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Text('Skip', style: AppText.hint),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                children: [
                  _WelcomePage(hero: _hero),
                  _ProfilePage(
                    profile: _profile,
                    age: _age,
                    onChanged: (p) => setState(() => _profile = p),
                  ),
                  const _MicPage(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  PageDotsIndicator(page: _page, count: _pageCount),
                  const SizedBox(height: 22),
                  PillButton(
                    label: isLast ? 'Start breathing' : 'Continue',
                    onTap: _canAdvance ? _next : null,
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

class _WelcomePage extends StatelessWidget {
  const _WelcomePage({required this.hero});

  final AnimationController hero;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 220,
            height: 170,
            child: AssemblingDots(
              progress: CurvedAnimation(
                parent: hero,
                curve: const Interval(0, 0.8),
              ),
              spacing: 11,
              dotSize: 3.4,
              color: AppColors.magenta,
            ),
          ),
          const SizedBox(height: 44),
          const Text(
            'Breathe on purpose',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.6,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Guided sessions to steady your breathing, and a quick check-in '
            'to watch your progress over time.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.profile,
    required this.age,
    required this.onChanged,
  });

  final ProfileDraft profile;
  final int age;
  final ValueChanged<ProfileDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final year = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const Text(
            'A little about you',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Breathing capacity varies with age, height and sex. These give '
            'your results something to be measured against.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          DotSliderRow(
            label: 'Age',
            value: age,
            min: 12,
            max: 90,
            unit: 'years',
            onChanged: (v) => onChanged(profile.copyWith(birthYear: year - v)),
          ),
          const SizedBox(height: 18),
          DotSliderRow(
            label: 'Height',
            value: profile.heightCm ?? 172,
            min: 120,
            max: 210,
            unit: 'cm',
            accent: AppColors.indigoPeek,
            onChanged: (v) => onChanged(profile.copyWith(heightCm: v)),
          ),
          const SizedBox(height: 18),
          DotSliderRow(
            label: 'Cigarettes',
            value: profile.cigarettesPerWeek,
            min: 0,
            max: 150,
            unit: 'per week',
            accent: AppColors.volumeAmber,
            onChanged: (v) =>
                onChanged(profile.copyWith(cigarettesPerWeek: v)),
          ),
          const SizedBox(height: 26),
          const Text('Sex', style: AppText.cardLabel),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final option in Sex.values) ...[
                Expanded(
                  child: _SegmentChip(
                    label: switch (option) {
                      Sex.female => 'Female',
                      Sex.male => 'Male',
                      Sex.preferNotToSay => 'Rather not',
                    },
                    selected: profile.sex == option,
                    onTap: () => onChanged(profile.copyWith(sex: option)),
                  ),
                ),
                if (option != Sex.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      pressedScale: 0.95,
      semanticLabel: label,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOut,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(23),
        ),
        child: Text(
          label,
          style: AppText.cardLabel,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _MicPage extends StatelessWidget {
  const _MicPage();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.surfaceHigh,
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(Icons.mic_none_rounded,
                size: 28, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 26),
          const Text(
            'How the breath check works',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          const _Point(
            'Breathe out at your phone and the microphone listens to the '
            'sound of the airflow.',
          ),
          const _Point(
            'Audio is processed on your device, moment to moment, and never '
            'recorded, saved or uploaded.',
          ),
          const _Point(
            "We'll ask for microphone access the first time you run a check "
            "— not now.",
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.surfaceHigh),
            ),
            child: const Text(
              'This is a wellness estimate, not a medical measurement. It is '
              'good at showing how your own breathing changes over time, and '
              'it is not a spirometer. For any health concern, talk to a '
              'clinician.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _Point extends StatelessWidget {
  const _Point(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 5,
            height: 5,
            margin: const EdgeInsets.only(top: 8, right: 12),
            decoration: const BoxDecoration(
              color: AppColors.magenta,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
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
