import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/staggered_entrance.dart';
import '../model/lung_metric.dart';
import '../widgets/gauge_tile.dart';
import '../widgets/hero_carousel.dart';
import '../widgets/home_menu_sheet.dart';
import '../widgets/page_dots_indicator.dart';
import '../widgets/stat_tile_tall.dart';
import '../widgets/toggle_tile.dart';

/// The Activity screen — the first mock screen.
///
/// Data is static for Phase 2; Phase 6 wires it through the repositories.
class ActivityView extends StatefulWidget {
  const ActivityView({super.key});

  @override
  State<ActivityView> createState() => _ActivityViewState();
}

class _ActivityViewState extends State<ActivityView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..forward();

  final _metrics = LungMetric.sample;
  double _page = 0;
  bool _training = true;

  LungMetric get _active => _metrics[_page.round().clamp(0, _metrics.length - 1)];

  @override
  void dispose() {
    _entrance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              StaggeredEntrance(
                controller: _entrance,
                index: 0,
                child: _AppBar(
                  onBack: () => context.canPop() ? context.pop() : null,
                  onMenu: () => HomeMenuSheet.show(context),
                ),
              ),
              const SizedBox(height: 24),

              // Carousel bleeds past the page padding so neighbours peek.
              StaggeredEntrance(
                controller: _entrance,
                index: 1,
                child: SizedBox(
                  height: height * 0.42,
                  child: OverflowBox(
                    maxWidth: MediaQuery.sizeOf(context).width,
                    child: HeroCarousel(
                      metrics: _metrics,
                      onPageChanged: (page) => setState(() => _page = page),
                      // The Hero flight (ANIMATION_SPEC 3.1–3.4) is still to
                      // come; this is the plain transition for now.
                      onCardTap: (metric) => context.push(Routes.test),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              StaggeredEntrance(
                controller: _entrance,
                index: 2,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween(
                        begin: const Offset(0, 0.4),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    _active.metricName,
                    key: ValueKey(_active.id),
                    style: AppText.sectionLabel,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              StaggeredEntrance(
                controller: _entrance,
                index: 3,
                child: PageDotsIndicator(page: _page, count: _metrics.length),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: StaggeredEntrance(
                  controller: _entrance,
                  index: 4,
                  child: _TileGrid(
                    training: _training,
                    onTrainingChanged: (v) => setState(() => _training = v),
                    onOpenTest: () => context.push(Routes.test),
                    onOpenSessions: () => context.push(Routes.patterns),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  const _AppBar({required this.onBack, required this.onMenu});

  final VoidCallback onBack;
  final VoidCallback onMenu;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: Row(
        children: [
          CircleIconButton(
            icon: Icons.arrow_back,
            onTap: onBack,
            semanticLabel: 'Back',
          ),
          const Expanded(
            child: Text(
              'Activity',
              textAlign: TextAlign.center,
              style: AppText.titleBar,
            ),
          ),
          CircleIconButton(
            icon: Icons.menu,
            onTap: onMenu,
            semanticLabel: 'Menu',
          ),
        ],
      ),
    );
  }
}

class _TileGrid extends StatelessWidget {
  const _TileGrid({
    required this.training,
    required this.onTrainingChanged,
    required this.onOpenTest,
    required this.onOpenSessions,
  });

  final bool training;
  final ValueChanged<bool> onTrainingChanged;
  final VoidCallback onOpenTest;
  final VoidCallback onOpenSessions;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: StatTileTall(
            label: 'Daily Smoke',
            value: '234',
            unit: 'D/w',
            scaleValue: 0.62,
            onTap: onOpenSessions,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ToggleTile(
                label: 'Training',
                value: training,
                onChanged: onTrainingChanged,
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GaugeTile(
                  label: 'Breath Volume',
                  value: '5.5',
                  unit: 'L',
                  fraction: 0.68,
                  onTap: onOpenTest,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
