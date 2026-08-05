import 'package:flutter/material.dart';

import 'core/motion/motion.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class BreatheApp extends StatelessWidget {
  const BreatheApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Breathe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: appRouter,
      builder: (context, child) => AppMotion(child: child!),
    );
  }
}
