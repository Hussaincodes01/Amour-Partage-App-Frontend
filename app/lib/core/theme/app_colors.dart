import 'package:flutter/painting.dart';

/// Colour tokens taken from the Figma theme (Material 3 dark palette).
abstract final class AppColors {
  // Surfaces
  static const bg = Color(0xFF100C18);
  static const surfaceLow = Color(0xFF1D1A26);
  static const surface = Color(0xFF211E2A);
  static const surfaceHigh = Color(0xFF2C2834);
  static const surfaceHighest = Color(0xFF373340);
  static const surfaceBright = Color(0xFF3B3744);

  // Content
  static const onSurface = Color(0xFFE7DFF0);
  static const onSurfaceVariant = Color(0xFFE2BDC7);
  static const outline = Color(0xFFA98891);
  static const outlineVariant = Color(0xFF5A3F48);

  // Brand
  static const primary = Color(0xFFFFB0C9);
  static const hotPink = Color(0xFFFF4799);
  static const deepPink = Color(0xFFB90066);
  static const primaryFixed = Color(0xFFFFD9E3);
  static const lavender = Color(0xFFDDB7FF);
  static const violet = Color(0xFF6F00BE);
  static const lavenderFixed = Color(0xFFF0DBFF);
  static const onLavender = Color(0xFF2C0051);
  static const mint = Color(0xFF4EDEA3);
  static const mintDeep = Color(0xFF00A572);
  static const mintBright = Color(0xFF6FFBBE);
  static const onMint = Color(0xFF003824);
  static const error = Color(0xFFFFB4AB);
  static const crimson = Color(0xFF93000A);

  /// `rgba(16,12,24,a)` — the inset/scrim colour used all over the design.
  static Color ink(double a) => bg.withValues(alpha: a);

  /// `rgba(44,40,52,a)` — translucent raised surface.
  static Color raised(double a) => surfaceHigh.withValues(alpha: a);

  /// `rgba(33,30,42,a)`
  static Color muted(double a) => surface.withValues(alpha: a);
}

abstract final class AppGradients {
  static const pinkViolet = LinearGradient(colors: [AppColors.hotPink, AppColors.violet]);
  static const pinkLavender = LinearGradient(colors: [AppColors.hotPink, AppColors.lavender]);
  static const pinkBlush = LinearGradient(colors: [AppColors.hotPink, AppColors.primary]);
  static const pinkDeep = LinearGradient(colors: [AppColors.hotPink, AppColors.deepPink]);

  /// 45° ring used around avatars.
  static const avatarRing = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [AppColors.hotPink, AppColors.lavender, AppColors.primary],
  );

  static const playButton = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [AppColors.hotPink, AppColors.hotPink, AppColors.lavender],
  );

  static const duoFx = LinearGradient(
    begin: Alignment.bottomLeft,
    end: Alignment.topRight,
    colors: [AppColors.violet, AppColors.hotPink, AppColors.primary],
  );

  static const progress = LinearGradient(
    colors: [AppColors.violet, AppColors.hotPink, AppColors.primary],
  );

  static const mintTab = LinearGradient(colors: [AppColors.mintDeep, AppColors.mint]);
}
