import 'package:flutter/material.dart';

/// Normalised (0–1) silhouettes that dot fields get masked to.
///
/// Kept apart from the painters so the shape can be tuned in the dot lab
/// without touching rendering code.
abstract final class BreathShapes {
  /// The rounded dome behind the readout on the Expiratory Volume screen.
  static Path lungDome(Size size) => _scaled(_lungDome, size);

  static final Path _lungDome = Path()
    ..moveTo(0.50, 0.00)
    ..cubicTo(0.80, 0.00, 1.00, 0.22, 1.00, 0.50)
    ..cubicTo(1.00, 0.76, 0.90, 0.94, 0.74, 0.99)
    ..cubicTo(0.66, 1.01, 0.58, 1.00, 0.50, 1.00)
    ..cubicTo(0.42, 1.00, 0.34, 1.01, 0.26, 0.99)
    ..cubicTo(0.10, 0.94, 0.00, 0.76, 0.00, 0.50)
    ..cubicTo(0.00, 0.22, 0.20, 0.00, 0.50, 0.00)
    ..close();

  /// Plain circle, for the session player's orb field.
  static Path orb(Size size) => Path()
    ..addOval(Rect.fromLTWH(0, 0, size.width, size.height));

  static Path _scaled(Path normalised, Size size) => normalised.transform(
        (Matrix4.identity()..scaleByDouble(size.width, size.height, 1, 1))
            .storage,
      );
}
