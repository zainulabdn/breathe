import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text.dart';
import '../../dots/dot_field.dart';
import '../../dots/dot_matrix_text.dart';

/// Phase 1 harness for the dot-matrix engine.
///
/// Every parameter that the real screens will hard-code is a slider here, so
/// the values in DESIGN_SPEC can be dialled in against the mock before any
/// screen is built. Delete once Phase 2 locks the numbers.
class DotLabView extends StatefulWidget {
  const DotLabView({super.key});

  @override
  State<DotLabView> createState() => _DotLabViewState();
}

class _DotLabViewState extends State<DotLabView>
    with SingleTickerProviderStateMixin {
  // Glyph controls
  String _value = '3.3';
  double _cellSize = 6;
  double _cellGap = 3;
  double _glow = 0.55;
  bool _showGrid = true;
  Timer? _cycleTimer;
  final _random = math.Random();

  // Field controls
  double _fill = 0.45;
  double _spacing = 11;
  double _dotSize = 3.2;
  double _shimmer = 0.12;
  double _waveAmplitude = 6;

  late final AnimationController _breathe = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 5),
  );
  bool _autoBreathe = false;

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _breathe.dispose();
    super.dispose();
  }

  void _toggleCycle() {
    setState(() {
      if (_cycleTimer != null) {
        _cycleTimer!.cancel();
        _cycleTimer = null;
      } else {
        _cycleTimer = Timer.periodic(const Duration(milliseconds: 900), (_) {
          setState(() {
            _value = (_random.nextDouble() * 6).toStringAsFixed(1);
          });
        });
      }
    });
  }

  void _toggleBreathe() {
    setState(() {
      _autoBreathe = !_autoBreathe;
      if (_autoBreathe) {
        _breathe.repeat(reverse: true);
      } else {
        _breathe.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dot Lab')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          _section('DotMatrixText'),
          Container(
            height: 160,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.lungCardGradient,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: AppColors.magenta.withValues(alpha: 0.35),
                  blurRadius: 48,
                  spreadRadius: -8,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DotMatrixText(
                  value: _value,
                  cellSize: _cellSize,
                  cellGap: _cellGap,
                  glow: _glow,
                  showUnlitGrid: _showGrid,
                  semanticsLabel: '$_value liters',
                ),
                const SizedBox(height: 10),
                const Text('Liter', style: AppText.unitLabel),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in const ['0.0', '3.3', '5.5', '12.7', '-1.4'])
                _chip(preset, () => setState(() => _value = preset)),
              _chip(
                _cycleTimer == null ? 'cycle ▶' : 'cycle ■',
                _toggleCycle,
                active: _cycleTimer != null,
              ),
            ],
          ),
          _slider('cellSize', _cellSize, 2, 14, (v) => _cellSize = v),
          _slider('cellGap', _cellGap, 0, 8, (v) => _cellGap = v),
          _slider('glow', _glow, 0, 1, (v) => _glow = v),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('unlit grid', style: AppText.hint),
            value: _showGrid,
            onChanged: (v) => setState(() => _showGrid = v),
          ),

          const SizedBox(height: 24),
          _section('DotField — lung cloud'),
          SizedBox(
            height: 260,
            child: AnimatedBuilder(
              animation: _breathe,
              builder: (context, _) {
                final fill = _autoBreathe
                    ? Curves.easeInOutSine.transform(_breathe.value)
                    : _fill;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    DotField(
                      fillLevel: fill,
                      spacing: _spacing,
                      dotSize: _dotSize,
                      shimmer: _shimmer,
                      waveAmplitude: _waveAmplitude,
                      semanticsLabel: 'Lung fill '
                          '${(fill * 100).round()} percent',
                    ),
                    DotMatrixText(
                      value: (fill * 6).toStringAsFixed(1),
                      cellSize: 5,
                      cellGap: 2.5,
                      glow: 0.7,
                      showUnlitGrid: false,
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _chip(
                _autoBreathe ? 'auto ■' : 'auto ▶',
                _toggleBreathe,
                active: _autoBreathe,
              ),
            ],
          ),
          _slider('fill', _fill, 0, 1, (v) => _fill = v, enabled: !_autoBreathe),
          _slider('spacing', _spacing, 6, 20, (v) => _spacing = v),
          _slider('dotSize', _dotSize, 1.5, 8, (v) => _dotSize = v),
          _slider('shimmer', _shimmer, 0, 0.5, (v) => _shimmer = v),
          _slider('wave', _waveAmplitude, 0, 20, (v) => _waveAmplitude = v),
        ],
      ),
    );
  }

  Widget _section(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(label, style: AppText.sectionLabel),
      );

  Widget _chip(String label, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.magenta : AppColors.surfaceHigh,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: AppText.cardLabel),
      ),
    );
  }

  Widget _slider(
    String label,
    double value,
    double min,
    double max,
    ValueChanged<double> onChanged, {
    bool enabled = true,
  }) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Row(
        children: [
          SizedBox(
            width: 78,
            child: Text(label, style: AppText.hint),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              onChanged: enabled ? (v) => setState(() => onChanged(v)) : null,
            ),
          ),
          SizedBox(
            width: 44,
            child: Text(
              value.toStringAsFixed(2),
              style: AppText.hint,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
