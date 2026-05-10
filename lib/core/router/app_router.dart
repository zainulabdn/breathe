import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/session/breath_pattern.dart';
import '../../features/activity/view/activity_view.dart';
import '../../features/dev/dot_lab_view.dart';
import '../../features/lung_test/view/expiratory_volume_view.dart';
import '../../features/onboarding/onboarding_view.dart';
import '../../features/session/view/pattern_picker_view.dart';
import '../../features/session/view/session_player_view.dart';
import '../../features/splash/splash_view.dart';

/// Routes are added as their phases land (docs/PLAN.md).
abstract final class Routes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const patterns = '/breathe';
  static const session = '/breathe/session';
  static const test = '/test';
  static const dotLab = '/lab';
}

/// Fade-through: the outgoing page fades out before the incoming fades in,
/// rather than crossfading through a muddy overlap (ANIMATION_SPEC 6.3).
CustomTransitionPage<void> _fadeThrough(Widget child, GoRouterState state) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 300),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: const Interval(0.35, 1, curve: Curves.easeOut),
        ),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0).animate(
            CurvedAnimation(
              parent: secondaryAnimation,
              curve: const Interval(0, 0.35, curve: Curves.easeIn),
            ),
          ),
          child: child,
        ),
      );
    },
  );
}

final GoRouter appRouter = GoRouter(
  initialLocation: Routes.splash,
  routes: [
    GoRoute(
      path: Routes.splash,
      pageBuilder: (context, state) => _fadeThrough(const SplashView(), state),
    ),
    GoRoute(
      path: Routes.onboarding,
      pageBuilder: (context, state) =>
          _fadeThrough(const OnboardingView(), state),
    ),
    GoRoute(
      path: Routes.home,
      pageBuilder: (context, state) => _fadeThrough(const ActivityView(), state),
    ),
    GoRoute(
      path: Routes.patterns,
      pageBuilder: (context, state) =>
          _fadeThrough(const PatternPickerView(), state),
    ),
    GoRoute(
      path: '${Routes.session}/:patternId',
      pageBuilder: (context, state) {
        final id = state.pathParameters['patternId'];
        final pattern = BreathPattern.presets.firstWhere(
          (p) => p.id == id,
          orElse: () => BreathPattern.coherent,
        );
        return _fadeThrough(SessionPlayerView(pattern: pattern), state);
      },
    ),
    GoRoute(
      path: Routes.test,
      pageBuilder: (context, state) =>
          _fadeThrough(const ExpiratoryVolumeView(), state),
    ),
    GoRoute(
      path: Routes.dotLab,
      builder: (context, state) => const DotLabView(),
    ),
  ],
);
