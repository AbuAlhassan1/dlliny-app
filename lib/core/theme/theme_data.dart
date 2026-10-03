import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class Themes {
  static final ThemeData lightTheme = _buildTheme(
    colors: AppColors.light,
    brightness: Brightness.light,
  );

  static final ThemeData darkTheme = _buildTheme(
    colors: AppColors.dark,
    brightness: Brightness.dark,
  );

  static ThemeData _buildTheme({
    required AppColors colors,
    required Brightness brightness,
  }) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        secondary: colors.accent,
        onSecondary: colors.onSurface,
        error: colors.danger,
        onError: colors.onPrimary,
        surface: colors.surface,
        onSurface: colors.onSurface,
      ),
      appBarTheme: AppBarThemeData(
        backgroundColor: colors.background,
        foregroundColor: colors.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      dividerTheme: DividerThemeData(
        color: colors.divider,
        thickness: 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: colors.onSurface),
      textTheme: const TextTheme(
        bodyMedium: TextStyle(
          fontFamilyFallback: ["IBMPlexSans"],
        ),
      ).apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
      ),
      fontFamily: "IBMPlexSansArabic",
      extensions: [colors],
    );
  }
}
