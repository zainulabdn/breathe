import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One card in the Activity carousel.
///
/// Static sample data for Phase 2 — Phase 6 replaces [sample] with values read
/// through the repositories.
@immutable
class LungMetric {
  const LungMetric({
    required this.id,
    required this.cardLabel,
    required this.metricName,
    required this.value,
    required this.unit,
    required this.gradient,
    required this.glowColor,
  });

  /// Small label in the card's top-left ("Lung test").
  final String cardLabel;

  /// Name shown under the carousel ("Lung Capacity").
  final String metricName;

  final String id;
  final String value;
  final String unit;
  final LinearGradient gradient;

  /// Tint of the card's cast shadow — the coloured bloom under each card.
  final Color glowColor;

  String get semanticsValue => '$value $unit';

  static const List<LungMetric> sample = [
    LungMetric(
      id: 'vital_capacity',
      cardLabel: 'Lung test',
      metricName: 'Lung Capacity',
      value: '3.3',
      unit: 'Liter',
      gradient: AppColors.lungCardGradient,
      glowColor: AppColors.magenta,
    ),
    LungMetric(
      id: 'expiratory_volume',
      cardLabel: 'Exhale test',
      metricName: 'Expiratory Volume',
      value: '2.8',
      unit: 'Liter',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.indigoPeek, AppColors.violet, AppColors.trainingBlue],
        stops: [0.0, 0.5, 1.0],
      ),
      glowColor: AppColors.indigoPeek,
    ),
    LungMetric(
      id: 'peak_flow',
      cardLabel: 'Peak flow',
      metricName: 'Peak Flow',
      value: '5.5',
      unit: 'L/sec',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.peachPeek, AppColors.volumeAmber, AppColors.volumeRed],
        stops: [0.0, 0.5, 1.0],
      ),
      glowColor: AppColors.volumeAmber,
    ),
    LungMetric(
      id: 'breath_hold',
      cardLabel: 'Breath hold',
      metricName: 'Breath Hold',
      value: '42',
      unit: 'Seconds',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.trainingGlow, AppColors.indigoPeek, AppColors.violet],
        stops: [0.0, 0.5, 1.0],
      ),
      glowColor: AppColors.trainingGlow,
    ),
    LungMetric(
      id: 'resting_rate',
      cardLabel: 'Resting rate',
      metricName: 'Breaths / Minute',
      value: '12',
      unit: 'Per min',
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppColors.magenta, AppColors.volumeRed, AppColors.volumeAmber],
        stops: [0.0, 0.55, 1.0],
      ),
      glowColor: AppColors.volumeRed,
    ),
  ];
}
