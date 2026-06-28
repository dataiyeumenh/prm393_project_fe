import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_spacing.dart';
export 'app_typography.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true);
    final textTheme = GoogleFonts.interTextTheme(base.textTheme).apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    );

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.canvas,
      colorScheme: const ColorScheme.light(
        primary: AppColors.ink,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.charcoal,
        onSecondary: AppColors.onPrimary,
        surface: AppColors.canvas,
        onSurface: AppColors.ink,
        error: AppColors.sale,
        onError: AppColors.onPrimary,
      ),
      textTheme: textTheme.copyWith(
        displayLarge: AppTypography.displayCampaign,
        displayMedium: AppTypography.headingXl,
        displaySmall: AppTypography.headingLg,
        headlineMedium: AppTypography.headingLg,
        headlineSmall: AppTypography.headingMd,
        titleLarge: AppTypography.bodyStrong,
        titleMedium: AppTypography.bodyStrong,
        bodyLarge: AppTypography.bodyMd,
        bodyMedium: AppTypography.bodyMd,
        labelLarge: AppTypography.buttonMd,
        labelMedium: AppTypography.buttonSm,
        labelSmall: AppTypography.captionSm,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.canvas,
        foregroundColor: AppColors.ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.softCloud,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.full),
          borderSide: const BorderSide(color: AppColors.accentPink, width: 2),
        ),
      ),
      splashColor: Colors.transparent,
      highlightColor: AppColors.softCloud,
    );
  }
}
