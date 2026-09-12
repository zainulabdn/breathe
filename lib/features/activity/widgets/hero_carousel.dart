import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../model/lung_metric.dart';
import 'lung_test_card.dart';

/// Carousel of metric cards with continuous parallax.
///
/// The neighbour transform is driven by `PageController.page` — a fractional
/// value — rather than by the settled index, so the cards track the finger
/// instead of snapping when the page commits. That difference is most of what
/// makes the mock's carousel feel expensive.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({
    required this.metrics,
    required this.onPageChanged,
    this.onCardTap,
    this.viewportFraction = 0.72,
    super.key,
  });

  final List<LungMetric> metrics;
  final ValueChanged<double> onPageChanged;
  final void Function(LungMetric)? onCardTap;
  final double viewportFraction;

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  late final PageController _controller = PageController(
    viewportFraction: widget.viewportFraction,
  );

  /// Long enough that a card finishes its own motion before it slides away.
  /// CardBackgroundPainter drifts the bloom on an 8s cycle and runs the orbit
  /// on a 5s one, and the readout shimmers on 5s. At 4s the card was swapped
  /// before any of those completed a single pass, so the only motion the eye
  /// ever registered was the slide itself — the card read as a static image
  /// being shuffled. 12s leaves ~11s at rest: one full bloom, two orbits.
  static const _advanceEvery = Duration(seconds: 12);

  /// How long to leave the carousel alone after the user touches it. Resuming
  /// immediately fights the user for control of the thing they just grabbed.
  static const _resumeAfter = Duration(seconds: 7);

  double _page = 0;
  Timer? _autoAdvance;
  Timer? _resume;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MotionScale.ambientAllowed(context)) {
      _startAutoAdvance();
    } else {
      _autoAdvance?.cancel();
      _autoAdvance = null;
    }
  }

  void _startAutoAdvance() {
    _autoAdvance?.cancel();
    _autoAdvance = Timer.periodic(_advanceEvery, (_) {
      if (!mounted || !_controller.hasClients) return;
      final next = (_page.round() + 1) % widget.metrics.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  /// Any touch stops the rotation; it restarts once the user has been idle.
  void _onUserInteraction() {
    _autoAdvance?.cancel();
    _autoAdvance = null;
    _resume?.cancel();
    _resume = Timer(_resumeAfter, () {
      if (mounted && MotionScale.ambientAllowed(context)) _startAutoAdvance();
    });
  }

  void _handleScroll() {
    final page = _controller.page;
    if (page == null || page == _page) return;
    setState(() => _page = page);
    widget.onPageChanged(page);
  }

  @override
  void dispose() {
    _autoAdvance?.cancel();
    _resume?.cancel();
    _controller
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      // Listener rather than the scroll notifications: a tap that never becomes
      // a drag still means the user is reaching for the card, and the rotation
      // should get out of the way.
      onPointerDown: (_) => _onUserInteraction(),
      child: PageView.builder(
        controller: _controller,
        itemCount: widget.metrics.length,
        padEnds: true,
        itemBuilder: (context, index) {
          final delta = (_page - index).abs().clamp(0.0, 1.0);
          final scale = 1.0 - 0.14 * delta;
          final dim = 0.45 * delta;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Transform.scale(
              scale: scale,
              child: Stack(
                fit: StackFit.passthrough,
                children: [
                  LungTestCard(
                    metric: widget.metrics[index],
                    onTap: widget.onCardTap == null
                        ? null
                        : () => widget.onCardTap!(widget.metrics[index]),
                  ),
                  // A scrim, not an Opacity. The cards contain `drawRawAtlas`
                  // content, which Impeller cannot push inherited opacity into —
                  // an Opacity here forces a saveLayer on every frame of every
                  // swipe. Over a near-black page a black scrim is visually the
                  // same thing and composites with no offscreen pass.
                  if (dim > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.bg.withValues(alpha: dim),
                            borderRadius: BorderRadius.circular(40),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
