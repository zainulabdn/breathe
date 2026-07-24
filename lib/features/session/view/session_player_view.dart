import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/motion/motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text.dart';
import '../../../core/widgets/circle_icon_button.dart';
import '../../../core/widgets/pill_button.dart';
import '../../../data/models/session_record.dart';
import '../../../data/repositories/session_repository.dart';
import '../../../domain/session/breath_pattern.dart';
import '../../../domain/session/pattern_engine.dart';
import '../../../domain/session/session_cues.dart';
import '../../../dots/breath_shapes.dart';
import '../../../dots/assembling_dots.dart';
import '../../../dots/dot_matrix_text.dart';
import '../widgets/breathing_orb.dart';
import '../widgets/phase_ring.dart';

class SessionPlayerView extends ConsumerStatefulWidget {
  const SessionPlayerView({required this.pattern, super.key});

  final BreathPattern pattern;

  @override
  ConsumerState<SessionPlayerView> createState() => _SessionPlayerViewState();
}

class _SessionPlayerViewState extends ConsumerState<SessionPlayerView>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final PatternEngine _engine = PatternEngine(
    pattern: widget.pattern,
    cycles: widget.pattern.defaultCycles,
  );

  /// One controller for the entire session. Its value maps linearly to elapsed
  /// seconds; every phase is derived from that, never from chained timers.
  late final AnimationController _session = AnimationController(
    vsync: this,
    duration: Duration(milliseconds: (_engine.totalSeconds * 1000).round()),
  );

  late final AnimationController _dissolve = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
    value: 1,
  );

  final SessionCues _cues = SessionCues();
  final DateTime _startedAt = DateTime.now();

  bool _running = false;
  bool _finished = false;
  bool _saved = false;

  double get _elapsed => _session.value * _engine.totalSeconds;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
    _session.addListener(_onTick);
    _session.addStatusListener(_onStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    _session
      ..removeListener(_onTick)
      ..removeStatusListener(_onStatus)
      ..dispose();
    _dissolve.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding pauses rather than silently running on — a session that
    // "completed" in your pocket is a lie in the history.
    if (state != AppLifecycleState.resumed && _running) _pause();
  }

  void _start() {
    setState(() => _running = true);
    _cues.reset();
    _session.forward();
  }

  void _pause() {
    _session.stop();
    if (mounted) setState(() => _running = false);
  }

  void _resume() {
    setState(() => _running = true);
    _session.forward();
  }

  void _onTick() {
    if (!_finished) _cues.update(_engine.frameAt(_elapsed));
    setState(() {});
  }

  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) _finish(finished: true);
  }

  Future<void> _finish({required bool finished}) async {
    if (_finished) return;
    _session.stop();
    setState(() {
      _finished = true;
      _running = false;
    });

    _cues.complete();
    if (MotionScale.of(context) > 0) {
      await _dissolve.reverse(from: 1);
    } else {
      _dissolve.value = 0;
    }
    await _save(finished: finished);
  }

  Future<void> _save({required bool finished}) async {
    if (_saved) return;
    _saved = true;
    final frame = _engine.frameAt(_elapsed);
    await ref.read(sessionRepositoryProvider).add(
          SessionRecord(
            id: '${_startedAt.microsecondsSinceEpoch}',
            patternId: widget.pattern.id,
            startedAt: _startedAt,
            durationSec: _elapsed.round(),
            // A cycle counts only once it is finished.
            completedCycles: finished ? _engine.cycles : frame.cycleIndex,
            finished: finished,
          ),
        );
  }

  Future<void> _endEarly() async {
    await _finish(finished: false);
  }

  @override
  Widget build(BuildContext context) {
    final frame = _engine.frameAt(_elapsed);
    final orbColor = BreathingOrb.colorFor(frame.phase);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const SizedBox(height: 8),
              _Header(
                title: widget.pattern.name,
                subtitle: widget.pattern.summary,
                running: _running,
                finished: _finished,
                onClose: () => context.pop(),
                onTogglePlay: _running ? _pause : _resume,
              ),
              Expanded(
                child: Center(
                  child: _finished
                      ? _Summary(
                          dissolve: _dissolve,
                          color: orbColor,
                          cycles: _engine.frameAt(_elapsed).cycleIndex,
                          totalCycles: _engine.cycles,
                          seconds: _elapsed.round(),
                        )
                      : _Stage(frame: frame, engine: _engine, color: orbColor),
                ),
              ),
              if (_finished)
                PillButton(label: 'Done', onTap: () => context.pop())
              else
                _FooterProgress(
                  progress: _session.value,
                  cycle: frame.cycleIndex + 1,
                  totalCycles: _engine.cycles,
                  onEnd: _endEarly,
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stage extends StatelessWidget {
  const _Stage({
    required this.frame,
    required this.engine,
    required this.color,
  });

  final SessionFrame frame;
  final PatternEngine engine;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // The trailing layers are the same engine sampled in the past.
    final amplitudes = [
      frame.amplitude,
      engine.frameAt(frame.elapsedSeconds - 0.12).amplitude,
      engine.frameAt(frame.elapsedSeconds - 0.24).amplitude,
    ];

    // Rate of change of the breath, from a short backwards difference. Scaled
    // so a normal inhale lands near 1 — this is what the orb squashes with.
    const dt = 0.08;
    final previous = engine.frameAt(frame.elapsedSeconds - dt).amplitude;
    final velocity = ((frame.amplitude - previous) / dt / 0.6).clamp(-1.0, 1.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 290,
          height: 290,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PhaseRing(progress: frame.phaseProgress, color: color),
              BreathingOrb(
                amplitudes: amplitudes,
                phase: frame.phase,
                velocity: velocity,
              ),
              DotMatrixText(
                value: '${frame.phaseSecondsRemaining}',
                cellSize: 5,
                cellGap: 2.4,
                glow: 0.8,
                showUnlitGrid: false,
                semanticsLabel:
                    '${frame.phase.label}, ${frame.phaseSecondsRemaining} '
                    'seconds remaining',
              ),
            ],
          ),
        ),
        const SizedBox(height: 40),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween(begin: const Offset(0, 0.5), end: Offset.zero)
                  .animate(animation),
              child: child,
            ),
          ),
          child: Text(
            frame.phase.label,
            key: ValueKey(frame.phase),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.3,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({
    required this.dissolve,
    required this.color,
    required this.cycles,
    required this.totalCycles,
    required this.seconds,
  });

  final AnimationController dissolve;
  final Color color;
  final int cycles;
  final int totalCycles;
  final int seconds;

  @override
  Widget build(BuildContext context) {
    final minutes = seconds ~/ 60;
    final rest = seconds % 60;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 240,
          height: 240,
          // The orb scatters back into dots — AssemblingDots run in reverse.
          child: AssemblingDots(
            progress: dissolve,
            pathBuilder: BreathShapes.orb,
            spacing: 11,
            dotSize: 3.2,
            color: color,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Session complete',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$minutes min ${rest.toString().padLeft(2, '0')} sec  ·  '
          '$cycles of $totalCycles cycles',
          style: AppText.hint,
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.running,
    required this.finished,
    required this.onClose,
    required this.onTogglePlay,
  });

  final String title;
  final String subtitle;
  final bool running;
  final bool finished;
  final VoidCallback onClose;
  final VoidCallback onTogglePlay;

  @override
  Widget build(BuildContext context) {
    // Deliberately not height-constrained: a two-line stack of titleBar +
    // unitLabel is a couple of pixels taller than the 44pt buttons beside it,
    // and pinning the row to 44 overflows. The buttons set the minimum height.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        CircleIconButton(
          icon: Icons.close,
          onTap: onClose,
          semanticLabel: 'Close session',
        ),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppText.titleBar.copyWith(height: 1.15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: AppText.unitLabel.copyWith(height: 1.15),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        if (finished)
          const SizedBox(width: 44)
        else
          CircleIconButton(
            icon: running ? Icons.pause : Icons.play_arrow,
            onTap: onTogglePlay,
            semanticLabel: running ? 'Pause' : 'Resume',
          ),
      ],
    );
  }
}

class _FooterProgress extends StatelessWidget {
  const _FooterProgress({
    required this.progress,
    required this.cycle,
    required this.totalCycles,
    required this.onEnd,
  });

  final double progress;
  final int cycle;
  final int totalCycles;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            DotMatrixText(
              value: '$cycle',
              cellSize: 3,
              cellGap: 1.5,
              glow: 0.3,
              showUnlitGrid: false,
              litColor: AppColors.textSecondary,
              semanticsLabel: 'Cycle $cycle of $totalCycles',
            ),
            const SizedBox(width: 8),
            Text('of $totalCycles cycles', style: AppText.hint),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 3,
            backgroundColor: AppColors.surfaceHigh,
            valueColor: const AlwaysStoppedAnimation(AppColors.textSecondary),
          ),
        ),
        const SizedBox(height: 18),
        PillButton(label: 'End session', onTap: onEnd, filled: false),
      ],
    );
  }
}
