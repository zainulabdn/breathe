import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../domain/breath/breath_source.dart';
import '../../../dots/dot_field.dart';
import '../../../dots/dot_matrix_text.dart';
import '../controller/breath_test_controller.dart';
import '../widgets/particle_stream.dart';
import '../widgets/test_sheet.dart';

/// The second mock screen.
///
/// Runs on [SimulatedBreathSource] — press and hold anywhere to blow. Phase 4
/// swaps in the microphone behind the same [BreathSource] interface; nothing on
/// this screen changes.
class ExpiratoryVolumeView extends StatefulWidget {
  const ExpiratoryVolumeView({super.key});

  @override
  State<ExpiratoryVolumeView> createState() => _ExpiratoryVolumeViewState();
}

class _ExpiratoryVolumeViewState extends State<ExpiratoryVolumeView>
    with TickerProviderStateMixin {
  final _source = SimulatedBreathSource();
  late final BreathTestController _controller = BreathTestController(
    vsync: this,
    source: _source,
  );

  /// Flow alone, so the particle stream does not rebuild on every field of the
  /// reading.
  final ValueNotifier<double> _flow = ValueNotifier(0);

  @override
  void initState() {
    super.initState();
    _controller.reading.addListener(_syncFlow);
    _controller.start();
  }

  void _syncFlow() => _flow.value = _controller.reading.value.flow;

  @override
  void dispose() {
    _controller.reading.removeListener(_syncFlow);
    _controller.dispose();
    _flow.dispose();
    super.dispose();
  }

  void _press(bool down) {
    _source.setPressure(down ? 1 : 0);
    if (down) HapticFeedback.lightImpact();
  }

  Future<void> _finish() async {
    await _controller.finish();
    HapticFeedback.heavyImpact();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _press(true),
        onTapUp: (_) => _press(false),
        onTapCancel: () => _press(false),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text('Expiratory Volume', style: AppText.titleBar),
              Expanded(
                child: ValueListenableBuilder<BreathReading>(
                  valueListenable: _controller.reading,
                  builder: (context, reading, _) =>
                      _Stage(reading: reading, flow: _flow),
                ),
              ),
              ValueListenableBuilder<BreathReading>(
                valueListenable: _controller.reading,
                builder: (context, reading, _) => TestSheet(reading: reading),
              ),
              Container(
                color: AppColors.sheetNavy.withValues(alpha: 0.82),
                padding: EdgeInsets.fromLTRB(
                  22,
                  6,
                  22,
                  10 + MediaQuery.viewPaddingOf(context).bottom,
                ),
                child: Row(
                  children: [
                    CircleIconButton(
                      icon: Icons.refresh,
                      onTap: _controller.reset,
                      semanticLabel: 'Restart test',
                      background: Colors.white.withValues(alpha: 0.10),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      // Dark and translucent, per the mock. A solid white pill
                      // on a navy sheet is the brightest thing on the screen
                      // and pulls focus off the readout.
                      child: PillButton(
                        label: 'Finish Test',
                        onTap: _finish,
                        background: Colors.white.withValues(alpha: 0.07),
                        foreground: AppColors.textPrimary,
                        border: Colors.white.withValues(alpha: 0.14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleIconButton(
                      icon: Icons.close,
                      onTap: () => context.pop(),
                      semanticLabel: 'Close test',
                      background: AppColors.textPrimary,
                      foreground: AppColors.bg,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({required this.reading, required this.flow});

  final BreathReading reading;
  final ValueListenable<double> flow;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: DotField(
              fillLevel: reading.fillFraction,
              spacing: 10,
              dotSize: 2.8,
              glow: 0.55,
              semanticsLabel:
                  'Lung fill ${(reading.fillFraction * 100).round()} percent',
            ),
          ),
        ),
        const SizedBox(height: 6),
        DotMatrixText(
          value: reading.litersLabel,
          cellSize: 6,
          cellGap: 3,
          glow: 0.7,
          showUnlitGrid: false,
          semanticsLabel: '${reading.litersLabel} liters',
        ),
        const SizedBox(height: 8),
        const Text('Liter', style: AppText.unitLabel),
        Expanded(
          flex: 4,
          child: _StreamArea(reading: reading, flow: flow),
        ),
      ],
    );
  }
}

class _StreamArea extends StatelessWidget {
  const _StreamArea({required this.reading, required this.flow});

  final BreathReading reading;
  final ValueListenable<double> flow;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: ParticleStream(flow: flow)),
        // Shown until the user has actually blown something. Gating this on
        // `stage == ready` was wrong: start() moves straight to `measuring`,
        // so the prompt would never have appeared at all.
        if (reading.stage != TestStage.finished && reading.liters < 0.05)
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Text(
              'Press and hold anywhere to blow',
              textAlign: TextAlign.center,
              style: AppText.hint.copyWith(color: AppColors.textTertiary),
            ),
          ),
      ],
    );
  }
}
