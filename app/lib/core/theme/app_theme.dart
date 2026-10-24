import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static final dark = build(AppColors.dark);
  static final light = build(AppColors.light);

  static ThemeData build(AppColors c) {
    final scheme = ColorScheme(
      brightness: c.brightness,
      primary: c.pink,
      onPrimary: Colors.white,
      primaryContainer: c.pink,
      onPrimaryContainer: Colors.white,
      secondary: c.lavender,
      onSecondary: c.bg,
      tertiary: c.success,
      onTertiary: c.bg,
      error: c.danger,
      onError: c.bg,
      surface: c.bg,
      onSurface: c.text,
      onSurfaceVariant: c.textMuted,
      surfaceContainerLowest: c.bg,
      surfaceContainerLow: c.surface,
      surfaceContainer: c.surface,
      surfaceContainerHigh: c.surfaceHigh,
      surfaceContainerHighest: c.surfaceHighest,
      outline: c.textFaint,
      outlineVariant: c.border,
      shadow: c.shadow,
    );
    TextStyle t(TextStyle s, [Color? color]) => s.copyWith(color: color ?? c.text);
    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.bg,
      canvasColor: c.bg,
      fontFamily: 'PlusJakartaSans',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      dividerColor: c.border,
      textTheme: TextTheme(
        headlineMedium: t(AppText.largeTitle),
        headlineSmall: t(AppText.display),
        titleLarge: t(AppText.title),
        titleMedium: t(AppText.headline),
        titleSmall: t(AppText.subhead),
        bodyLarge: t(AppText.body),
        bodyMedium: t(AppText.body),
        bodySmall: t(AppText.small, c.textMuted),
        labelLarge: t(AppText.smallStrong),
        labelMedium: t(AppText.caption, c.textMuted),
        labelSmall: t(AppText.label, c.textMuted),
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.pink,
        selectionColor: c.pink.withValues(alpha: 0.3),
        selectionHandleColor: c.pink,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
      extensions: [c],
    );
  }
}
