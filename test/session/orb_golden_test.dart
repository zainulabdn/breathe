import 'package:breathe/core/theme/app_colors.dart';
import 'package:breathe/domain/session/breath_pattern.dart';
import 'package:breathe/domain/session/pattern_engine.dart';
import 'package:breathe/dots/dot_atlas.dart';
import 'package:breathe/features/session/widgets/breathing_orb.dart';
import 'package:breathe/features/session/widgets/phase_ring.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(DotAtlas.warmUpSync);

  /// Renders the orb exactly as the player composes it: engine sampled at
  /// [elapsed], plus two trailing samples for the outer layers.
  Widget stageAt(PatternEngine engine, double elapsed) {
    final frame = engine.frameAt(elapsed);
    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PhaseRing(
            progress: frame.phaseProgress,
            color: BreathingOrb.colorFor(frame.phase),
          ),
          BreathingOrb(
            amplitudes: [
              frame.amplitude,
              engine.frameAt(elapsed - 0.12).amplitude,
              engine.frameAt(elapsed - 0.24).amplitude,
            ],
            phase: frame.phase,
          ),
        ],
      ),
    );
  }

  testWidgets('orb through one full box cycle', (tester) async {
    final engine = PatternEngine(pattern: BreathPattern.box, cycles: 2);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: AppColors.bg,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  stageAt(engine, 1), // inhaling
                  stageAt(engine, 5), // holding full
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  stageAt(engine, 10), // exhaling
                  stageAt(engine, 14), // holding empty
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(Column).first,
      matchesGoldenFile('goldens/orb_box_cycle.png'),
    );
  });
}
