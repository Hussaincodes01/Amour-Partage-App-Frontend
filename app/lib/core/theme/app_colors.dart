import 'package:flutter/material.dart';

/// Brand colours. They look the same in both themes.
abstract final class Brand {
  static const pink = Color(0xFFFF4799);
  static const violet = Color(0xFF6F00BE);
  static const lilac = Color(0xFFB57BFF);
  static const blush = Color(0xFFFFB0C9);
}

abstract final class AppGradients {
  /// Primary call-to-action fill.
  static const pinkViolet = LinearGradient(colors: [Brand.pink, Brand.violet]);

  /// Softer fill for secondary highlights (progress, rings).
  static const pinkLilac = LinearGradient(colors: [Brand.pink, Brand.lilac]);

  /// Ring around avatars.
  static const avatarRing = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [Brand.pink, Brand.lilac],
  );
}

/// Theme-dependent colour tokens. Read them with `context.colors`.
///
/// *Midnight* (dark) keeps the Figma palette; *Daylight* (light) is a warm
/// off-white version with the same brand pink and violet.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.brightness,
    required this.bg,
    required this.surface,
    required this.surfaceHigh,
    required this.surfaceHighest,
    required this.text,
    required this.textMuted,
    required this.textFaint,
    required this.border,
    required this.accent,
    required this.lavender,
    required this.success,
    required this.danger,
    required this.shadow,
    required this.bubbleMine,
    required this.bubblePartner,
  });

  final Brightness brightness;

  /// Page background.
  final Color bg;

  /// Cards and sheets.
  final Color surface;

  /// Chips, inputs and buttons that sit on a card.
  final Color surfaceHigh;

  /// Tracks, handles and pressed states.
  final Color surfaceHighest;

  final Color text;
  final Color textMuted;
  final Color textFaint;

  /// Hairlines and dividers.
  final Color border;

  /// Pink used for text, icons and links (tuned for contrast in each theme).
  final Color accent;

  /// Secondary accent for text and icons.
  final Color lavender;

  final Color success;
  final Color danger;
  final Color shadow;

  final Color bubbleMine;
  final Color bubblePartner;

  /// Brand pink fill (buttons, selected states). Same in both themes.
  Color get pink => Brand.pink;
  Color get violet => Brand.violet;

  bool get isDark => brightness == Brightness.dark;

  /// Background colour at [a] opacity (frosted bars, scrims).
  Color bgA(double a) => bg.withValues(alpha: a);

  static const dark = AppColors(
    brightness: Brightness.dark,
    bg: Color(0xFF100C18),
    surface: Color(0xFF1C1925),
    surfaceHigh: Color(0xFF292532),
    surfaceHighest: Color(0xFF363240),
    text: Color(0xFFEFE8F5),
    textMuted: Color(0xFFC4B5C2),
    textFaint: Color(0xFF8D7F8B),
    border: Color(0xFF2E2A38),
    accent: Color(0xFFFFB0C9),
    lavender: Color(0xFFDDB7FF),
    success: Color(0xFF4EDEA3),
    danger: Color(0xFFFFB4AB),
    shadow: Color(0xFF000000),
    bubbleMine: Color(0xFFE8337F),
    bubblePartner: Color(0xFF292532),
  );

  static const light = AppColors(
    brightness: Brightness.light,
    bg: Color(0xFFFBF7F5),
    surface: Color(0xFFFFFFFF),
    surfaceHigh: Color(0xFFF5EDF0),
    surfaceHighest: Color(0xFFEADFE4),
    text: Color(0xFF221A24),
    textMuted: Color(0xFF6B5B66),
    textFaint: Color(0xFF9E909A),
    border: Color(0xFFEFE4E9),
    accent: Color(0xFFD1236B),
    lavender: Color(0xFF7448BF),
    success: Color(0xFF00875A),
    danger: Color(0xFFBA1A1A),
    shadow: Color(0xFF5A2140),
    bubbleMine: Color(0xFFE8337F),
    bubblePartner: Color(0xFFF2E9ED),
  );

  @override
  AppColors copyWith() => this;

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other == null) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppColors(
      brightness: t < 0.5 ? brightness : other.brightness,
      bg: l(bg, other.bg),
      surface: l(surface, other.surface),
      surfaceHigh: l(surfaceHigh, other.surfaceHigh),
      surfaceHighest: l(surfaceHighest, other.surfaceHighest),
      text: l(text, other.text),
      textMuted: l(textMuted, other.textMuted),
      textFaint: l(textFaint, other.textFaint),
      border: l(border, other.border),
      accent: l(accent, other.accent),
      lavender: l(lavender, other.lavender),
      success: l(success, other.success),
      danger: l(danger, other.danger),
      shadow: l(shadow, other.shadow),
      bubbleMine: l(bubbleMine, other.bubbleMine),
      bubblePartner: l(bubblePartner, other.bubblePartner),
    );
  }
}

extension AppColorsContext on BuildContext {
  /// The current theme's colour tokens.
  AppColors get colors => Theme.of(this).extension<AppColors>() ?? AppColors.dark;
}
