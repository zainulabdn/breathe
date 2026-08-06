import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/repositories/onboarding_repository.dart';
import 'dots/dot_atlas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // The dot sprite must exist before the first frame — every painter in the
  // app draws from it.
  await DotAtlas.warmUp();

  final prefs = await SharedPreferences.getInstance();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const BreatheApp(),
    ),
  );
}
