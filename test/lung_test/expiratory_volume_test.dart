import 'package:breathe/domain/breath/breath_source.dart';
import 'package:breathe/dots/dot_atlas.dart';
import 'package:breathe/features/lung_test/controller/breath_test_controller.dart';
import 'package:breathe/features/lung_test/view/expiratory_volume_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

/// Captures the tick callback so tests can advance time by hand.
///
/// `Ticker.dispatchTick` is not public API, and driving a real ticker would
/// make these tests depend on frame scheduling. Holding the callback lets the
/// controller be exercised as the pure integrator it is.
class _FakeVsync implements TickerProvider {
  TickerCallback? _callback;

  @override
  Ticker createTicker(TickerCallback onTick) {
    _callback = onTick;
    return Ticker(onTick);
  }

  void tick(int frame) =>
      _callback!(Duration(milliseconds: 16 * frame));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(DotAtlas.warmUpSync);

  group('BreathTestController', () {
    test('accumulates volume only while air is actually moving', () async {
      final vsync = _FakeVsync();
      final source = SimulatedBreathSource();
      final controller =
          BreathTestController(vsync: vsync, source: source);
      addTearDown(() async {
        await controller.finish();
        controller.dispose();
      });

      await controller.start();

      // Idle: the ticker runs but nothing should accumulate.
      for (var i = 1; i <= 30; i++) {
        vsync.tick(i);
      }
      expect(controller.reading.value.liters, 0);
      expect(controller.reading.value.hint, TestHint.ready);

      // Blowing.
      source.setPressure(1);
      for (var i = 31; i <= 150; i++) {
        vsync.tick(i);
      }
      expect(controller.reading.value.liters, greaterThan(1));
      expect(controller.reading.value.peakFlow, greaterThan(0.9));
      expect(controller.reading.value.exhaleSeconds, greaterThan(1));
    });

    test('volume never decreases', () async {
      final vsync = _FakeVsync();
      final source = SimulatedBreathSource();
      final controller =
          BreathTestController(vsync: vsync, source: source);
      addTearDown(() async {
        await controller.finish();
        controller.dispose();
      });

      await controller.start();
      source.setPressure(1);

      var previous = 0.0;
      for (var i = 1; i <= 200; i++) {
        if (i == 100) source.setPressure(0); // stop mid-way
        vsync.tick(i);
        final litres = controller.reading.value.liters;
        expect(litres, greaterThanOrEqualTo(previous));
        previous = litres;
      }
    });

    test('reset clears the measurement', () async {
      final vsync = _FakeVsync();
      final source = SimulatedBreathSource();
      final controller =
          BreathTestController(vsync: vsync, source: source);
      addTearDown(() async {
        await controller.finish();
        controller.dispose();
      });

      await controller.start();
      source.setPressure(1);
      for (var i = 1; i <= 120; i++) {
        vsync.tick(i);
      }
      expect(controller.reading.value.liters, greaterThan(0));

      await controller.reset();
      expect(controller.reading.value.liters, 0);
      expect(controller.reading.value.peakFlow, 0);
      expect(controller.reading.value.exhaleSeconds, 0);
    });

    test('a hitched frame cannot integrate an absurd volume', () async {
      final vsync = _FakeVsync();
      final source = SimulatedBreathSource();
      final controller =
          BreathTestController(vsync: vsync, source: source);
      addTearDown(() async {
        await controller.finish();
        controller.dispose();
      });

      await controller.start();
      source.setPressure(1);

      vsync.tick(1);
      // A 5 second stall between frames.
      vsync.tick(313); // ~5 second stall

      expect(controller.reading.value.liters, lessThan(0.2),
          reason: 'dt is clamped, so a stall cannot fabricate litres');
    });
  });

  group('ExpiratoryVolumeView', () {
    for (final size in const [Size(375, 667), Size(393, 852), Size(320, 640)]) {
      testWidgets('lays out without overflow at ${size.width}x${size.height}',
          (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(
          const MaterialApp(home: ExpiratoryVolumeView()),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('press and hold drives the readout', (tester) async {
      tester.view.physicalSize = const Size(393, 852);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(const MaterialApp(home: ExpiratoryVolumeView()));
      await tester.pump();

      expect(find.text('Press and hold anywhere to blow'), findsOneWidget);

      final gesture = await tester.startGesture(const Offset(196, 300));
      for (var i = 0; i < 90; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await gesture.up();
      await tester.pump();

      expect(find.text('Liter'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
