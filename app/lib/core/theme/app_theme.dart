import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_text.dart';

abstract final class AppTheme {
  static ThemeData get dark {
    const scheme = ColorScheme.dark(
      surface: AppColors.bg,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      primary: AppColors.hotPink,
      onPrimary: Colors.white,
      primaryContainer: AppColors.hotPink,
      secondary: AppColors.lavender,
      secondaryContainer: AppColors.violet,
      tertiary: AppColors.mint,
      error: AppColors.error,
      errorContainer: AppColors.crimson,
      outline: AppColors.outline,
      outlineVariant: AppColors.outlineVariant,
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      fontFamily: 'PlusJakartaSans',
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      textTheme: const TextTheme(
        headlineSmall: AppText.display,
        titleLarge: AppText.title,
        titleMedium: AppText.headline,
        bodyLarge: AppText.body,
        bodyMedium: AppText.body,
        bodySmall: AppText.small,
        labelSmall: AppText.label,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: AppColors.hotPink,
        selectionColor: Color(0x55FF4799),
        selectionHandleColor: AppColors.hotPink,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {TargetPlatform.android: FadeForwardsPageTransitionsBuilder()},
      ),
    );
  }
}
