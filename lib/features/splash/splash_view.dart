import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/motion/motion.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../data/repositories/onboarding_repository.dart';
import '../../dots/assembling_dots.dart';

/// Splash: the lung silhouette collapses inward out of scattered dots, the
/// wordmark fades under it, then the app routes on.
///
/// Deliberately short. A splash that outlasts the work it hides is just a
/// delay, so this holds ~1.5s total and routes as soon as the assembly lands.
class SplashView extends ConsumerStatefulWidget {
  const SplashView({super.key});

  @override
  ConsumerState<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends ConsumerState<SplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  late final Animation<double> _assemble = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.64),
  );

  late final Animation<double> _wordmark = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.45, 0.85, curve: Curves.easeOut),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    if (!mounted) return;
    if (MotionScale.of(context) == 0) {
      _controller.value = 1;
    } else {
      await _controller.forward();
    }
    if (!mounted) return;

    final onboarded = ref.read(onboardingRepositoryProvider).isComplete;
    context.go(onboarded ? Routes.home : Routes.onboarding);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 190,
              height: 150,
              child: AssemblingDots(
                progress: _assemble,
                spacing: 10,
                dotSize: 3.2,
                semanticsLabel: 'Breathe',
              ),
            ),
            const SizedBox(height: 34),
            FadeTransition(
              opacity: _wordmark,
              child: AnimatedBuilder(
                animation: _wordmark,
                builder: (context, child) => Transform.translate(
                  offset: Offset(0, 10 * (1 - _wordmark.value)),
                  child: child,
                ),
                child: const Text(
                  'BREATHE',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 7,
                    color: AppColors.textSecondary,
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
