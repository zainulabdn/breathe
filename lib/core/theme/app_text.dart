import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Type scale from docs/DESIGN_SPEC.md §2.
///
/// TODO(phase-7): bundle Inter (or Satoshi) as an asset and set `fontFamily`
/// here. Until then we ride the platform default — SF Pro on iOS, Roboto on
/// Android — which is close enough that it does not block layout work. The
/// large readouts are painted dots, not text, so they are unaffected.
abstract final class AppText {
  static const _family = null;

  static const titleBar = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.textPrimary,
  );

  static const cardLabel = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const unitLabel = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textSecondary,
  );

  static const sectionLabel = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
  );

  static const tileNumber = TextStyle(
    fontFamily: _family,
    fontSize: 34,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.5,
    color: AppColors.textPrimary,
  );

  static const hint = TextStyle(
    fontFamily: _family,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const button = TextStyle(
    fontFamily: _family,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
