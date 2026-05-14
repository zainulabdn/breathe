import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.magenta,
      brightness: Brightness.dark,
    ).copyWith(surface: AppColors.bg);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      splashFactory: NoSplash.splashFactory,
      // Every press response in this app is a scale + haptic, painted by the
      // widget itself. Material's ink ripple fights that and looks wrong on the
      // gradient cards.
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        titleMedium: AppText.titleBar,
        bodyMedium: AppText.cardLabel,
        labelMedium: AppText.unitLabel,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppText.titleBar,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
    );
  }
}
