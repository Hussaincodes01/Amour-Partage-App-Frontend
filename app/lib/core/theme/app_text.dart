import 'package:flutter/painting.dart';

import 'app_colors.dart';

/// Type scale from the Figma theme (Plus Jakarta Sans; Cousine for timecodes).
abstract final class AppText {
  static const _family = 'PlusJakartaSans';

  static const display = TextStyle(
    fontFamily: _family,
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.6,
    color: AppColors.onSurface,
  );

  static const title = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const titleBold = TextStyle(
    fontFamily: _family,
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const headline = TextStyle(
    fontFamily: _family,
    fontSize: 18,
    height: 24 / 18,
    fontWeight: FontWeight.w600,
    color: AppColors.onSurface,
  );

  static const subhead = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 20 / 16,
    fontWeight: FontWeight.w700,
    color: AppColors.onSurface,
  );

  static const body = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurface,
  );

  static const bodyStrong = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.14,
    color: AppColors.onSurface,
  );

  static const small = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w400,
    color: AppColors.onSurfaceVariant,
  );

  static const smallStrong = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.24,
    color: AppColors.onSurface,
  );

  static const smallBold = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.24,
    color: AppColors.onSurface,
  );

  static const label = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const labelSemi = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const labelRegular = TextStyle(
    fontFamily: _family,
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );

  static const mono = TextStyle(
    fontFamily: 'Cousine',
    fontSize: 10,
    height: 14 / 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.onSurfaceVariant,
  );
}
