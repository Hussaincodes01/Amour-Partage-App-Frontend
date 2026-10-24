import 'package:flutter/widgets.dart';

/// Motion tokens. Every animation is time-based, so it renders at whatever
/// refresh rate the display runs (60/90/120/144/165 Hz) without speeding up.
abstract final class Motion {
  static const fast = Duration(milliseconds: 160);
  static const medium = Duration(milliseconds: 280);
  static const slow = Duration(milliseconds: 420);
  static const stagger = Duration(milliseconds: 55);

  /// Entrance "pop": quick settle with a hint of overshoot.
  static const pop = Cubic(0.18, 1.25, 0.4, 1.0);
  static const emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const fadeIn = Curves.easeOutCubic;
  static const fadeOut = Curves.easeInCubic;

  /// True when the user asked the OS to reduce or remove animations.
  static bool reduced(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}
