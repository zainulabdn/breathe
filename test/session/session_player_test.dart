import 'package:breathe/data/repositories/onboarding_repository.dart';
import 'package:breathe/domain/session/breath_pattern.dart';
import 'package:breathe/dots/dot_atlas.dart';
import 'package:breathe/features/session/view/session_player_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The session player is the app's densest screen and its layout is fixed
/// height in places, so it is the one most likely to overflow on a short or
/// narrow device. These tests pump it at several sizes and fail on any
/// overflow — a 2px overflow on the header shipped once already.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(DotAtlas.warmUpSync);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    // wakelock_plus talks to a platform channel that does not exist in tests.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dev.fluttercommunity.plus/wakelock'),
      (call) async => null,
    );
  });

  Future<void> pumpPlayer(
    WidgetTester tester,
    BreathPattern pattern,
    Size size,
  ) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(home: SessionPlayerView(pattern: pattern)),
      ),
    );
    await tester.pump();
  }

  // Includes an iPhone SE-class height, which is where fixed-height rows bite.
  const sizes = <String, Size>{
    'iPhone SE': Size(375, 667),
    'iPhone 17 Pro': Size(393, 852),
    'narrow': Size(320, 640),
  };

  for (final entry in sizes.entries) {
    testWidgets('lays out without overflow on ${entry.key}', (tester) async {
      await pumpPlayer(tester, BreathPattern.coherent, entry.value);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 2));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('long pattern names do not overflow the header', (tester) async {
    const wordy = BreathPattern(
      id: 'wordy',
      name: 'An Extremely Long Pattern Name That Should Ellipsize',
      description: 'x',
      phases: [
        PhaseSpec(PhaseType.inhale, 4),
        PhaseSpec(PhaseType.exhale, 4),
      ],
      defaultCycles: 2,
    );

    await pumpPlayer(tester, wordy, const Size(320, 640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('shows the phase label and counts the breath down',
      (tester) async {
    await pumpPlayer(tester, BreathPattern.box, const Size(393, 852));

    expect(find.text('Breathe in'), findsOneWidget);

    // Past the 4s inhale and into the hold.
    await tester.pump(const Duration(milliseconds: 4200));
    expect(find.text('Hold'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
