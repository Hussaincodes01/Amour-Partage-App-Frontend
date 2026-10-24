import 'package:flutter/painting.dart';

/// Type scale (Plus Jakarta Sans; Cousine for timecodes).
///
/// Styles carry no colour: text inherits the theme's text colour, and
/// secondary text sets `color: context.colors.textMuted`.
abstract final class AppText {
  static const _family = 'PlusJakartaSans';

  /// Screen titles ("Together", "Memories").
  static const largeTitle = TextStyle(fontFamily: _family, fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700, letterSpacing: -0.6);

  static const display = TextStyle(fontFamily: _family, fontSize: 24, height: 30 / 24, fontWeight: FontWeight.w700, letterSpacing: -0.5);

  static const title = TextStyle(fontFamily: _family, fontSize: 20, height: 26 / 20, fontWeight: FontWeight.w700, letterSpacing: -0.3);

  static const headline = TextStyle(fontFamily: _family, fontSize: 17, height: 22 / 17, fontWeight: FontWeight.w600, letterSpacing: -0.1);

  static const subhead = TextStyle(fontFamily: _family, fontSize: 15, height: 20 / 15, fontWeight: FontWeight.w600);

  static const body = TextStyle(fontFamily: _family, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w400);

  static const bodyStrong = TextStyle(fontFamily: _family, fontSize: 15, height: 22 / 15, fontWeight: FontWeight.w600);

  static const small = TextStyle(fontFamily: _family, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w400);

  static const smallStrong = TextStyle(fontFamily: _family, fontSize: 13, height: 18 / 13, fontWeight: FontWeight.w600);

  static const caption = TextStyle(fontFamily: _family, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500);

  /// Small uppercase section labels.
  static const label = TextStyle(fontFamily: _family, fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.8);

  static const mono = TextStyle(fontFamily: 'Cousine', fontSize: 11, height: 14 / 11, fontWeight: FontWeight.w700, letterSpacing: 0.3);
}
