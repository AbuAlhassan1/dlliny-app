import 'package:flutter/material.dart';

@immutable
class AppColors extends ThemeExtension<AppColors> {
  static const Color neonBlue = Color(0xFF00fbfb);
  static const Color purple = Color(0xFF4c0283);
  static const Color lightPurple = Color(0xFFdbb5fe);
  static const Color onSurfaceDarkPurple = Color(0xFF251F36);
  static const Color onSurfaceLightPurple = Color(0xFFCDBEF5);
  static const Color darkPurple = Color(0xFF14121b);
  static const Color darkBorder = Color(0xFF342952);
  static const Color lightBorder = Color(0xFFA795DA);
  static const Color darkerPurple = Color(0xFF0e0e0e);
  static const Color lightGrey = Color(0xFF767679);
  static const Color lighterGrey = Color(0xFFefeff0);

  final Color background;
  final Color surface;
  final Color surfaceMuted;
  final Color surfaceElevated;

  final Color border;
  final Color borderStrong;
  final Color divider;

  final Color onSurface;
  final Color onSurfaceSecondary;
  final Color onSurfaceMuted;
  final Color onSurfaceDisabled;

  final Color primary;
  final Color onPrimary;

  final Color surfaceAccent;
  final Color onSurfaceAccent;
  final Color onSurfaceAccentSecondary;
  final Color onSurfaceAccentMuted;

  final Color scrim;
  final Color scrimSubtle;

  final Color accent;
  final Color danger;
  final Color success;
  final Color warning;

  final Color mediaSurface;
  final Color onMediaSurface;

  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceMuted,
    required this.surfaceElevated,
    required this.border,
    required this.borderStrong,
    required this.divider,
    required this.onSurface,
    required this.onSurfaceSecondary,
    required this.onSurfaceMuted,
    required this.onSurfaceDisabled,
    required this.primary,
    required this.onPrimary,
    required this.surfaceAccent,
    required this.onSurfaceAccent,
    required this.onSurfaceAccentSecondary,
    required this.onSurfaceAccentMuted,
    required this.scrim,
    required this.scrimSubtle,
    required this.accent,
    required this.danger,
    required this.success,
    required this.warning,
    required this.mediaSurface,
    required this.onMediaSurface,
  });

  static const AppColors dark = AppColors(
    background: Color(0xFF000000),
    surface: Color(0xFF131313),
    surfaceMuted: Color(0xFF1A1A1A),
    surfaceElevated: Color(0xFF111111),

    border: Color(0x14FFFFFF),
    borderStrong: Color(0x4DFFFFFF),
    divider: Colors.white12,

    onSurface: Colors.white,
    onSurfaceSecondary: Colors.white70,
    onSurfaceMuted: Color(0x7CFFFFFF),
    onSurfaceDisabled: Colors.white24,

    primary: Colors.white,
    onPrimary: Colors.black,

    surfaceAccent: Color(0xFFF9F7F2),
    onSurfaceAccent: Colors.black87,
    onSurfaceAccentSecondary: Colors.black54,
    onSurfaceAccentMuted: Color(0x66000000),

    scrim: Color(0xCC000000),
    scrimSubtle: Color(0x66000000),

    accent: Color(0xFF00FBFB),
    danger: Colors.red,
    success: Color(0xFF1DA1F2),
    warning: Colors.amber,

    mediaSurface: Color(0xFF000000),
    onMediaSurface: Colors.white,
  );

  static const AppColors light = AppColors(
    background: Color(0xFFFFFFFF),
    surface: Color(0xFFFAFAFA),
    surfaceMuted: Color(0xFFF2F2F2),
    surfaceElevated: Color(0xFFFFFFFF),

    border: Color(0x14000000),
    borderStrong: Color(0x4D000000),
    divider: Colors.black12,

    onSurface: Color(0xFF0F0F0F),
    onSurfaceSecondary: Colors.black54,
    onSurfaceMuted: Color(0x7C000000),
    onSurfaceDisabled: Colors.black26,

    primary: Color(0xFF0F0F0F),
    onPrimary: Colors.white,

    surfaceAccent: Color(0xFF131313),
    onSurfaceAccent: Colors.white,
    onSurfaceAccentSecondary: Colors.white70,
    onSurfaceAccentMuted: Color(0x66FFFFFF),

    scrim: Color(0xCC000000),
    scrimSubtle: Color(0x66000000),

    accent: Color(0xFF00C2C2),
    danger: Color(0xFFD32F2F),
    success: Color(0xFF1DA1F2),
    warning: Color(0xFFFFA000),

    mediaSurface: Color(0xFF000000),
    onMediaSurface: Colors.white,
  );

  @override
  AppColors copyWith({
    Color? background,
    Color? surface,
    Color? surfaceMuted,
    Color? surfaceElevated,
    Color? border,
    Color? borderStrong,
    Color? divider,
    Color? onSurface,
    Color? onSurfaceSecondary,
    Color? onSurfaceMuted,
    Color? onSurfaceDisabled,
    Color? primary,
    Color? onPrimary,
    Color? surfaceAccent,
    Color? onSurfaceAccent,
    Color? onSurfaceAccentSecondary,
    Color? onSurfaceAccentMuted,
    Color? scrim,
    Color? scrimSubtle,
    Color? accent,
    Color? danger,
    Color? success,
    Color? warning,
    Color? mediaSurface,
    Color? onMediaSurface,
  }) {
    return AppColors(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      divider: divider ?? this.divider,
      onSurface: onSurface ?? this.onSurface,
      onSurfaceSecondary: onSurfaceSecondary ?? this.onSurfaceSecondary,
      onSurfaceMuted: onSurfaceMuted ?? this.onSurfaceMuted,
      onSurfaceDisabled: onSurfaceDisabled ?? this.onSurfaceDisabled,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      surfaceAccent: surfaceAccent ?? this.surfaceAccent,
      onSurfaceAccent: onSurfaceAccent ?? this.onSurfaceAccent,
      onSurfaceAccentSecondary:
          onSurfaceAccentSecondary ?? this.onSurfaceAccentSecondary,
      onSurfaceAccentMuted:
          onSurfaceAccentMuted ?? this.onSurfaceAccentMuted,
      scrim: scrim ?? this.scrim,
      scrimSubtle: scrimSubtle ?? this.scrimSubtle,
      accent: accent ?? this.accent,
      danger: danger ?? this.danger,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      mediaSurface: mediaSurface ?? this.mediaSurface,
      onMediaSurface: onMediaSurface ?? this.onMediaSurface,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      onSurface: Color.lerp(onSurface, other.onSurface, t)!,
      onSurfaceSecondary:
          Color.lerp(onSurfaceSecondary, other.onSurfaceSecondary, t)!,
      onSurfaceMuted: Color.lerp(onSurfaceMuted, other.onSurfaceMuted, t)!,
      onSurfaceDisabled:
          Color.lerp(onSurfaceDisabled, other.onSurfaceDisabled, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
      surfaceAccent: Color.lerp(surfaceAccent, other.surfaceAccent, t)!,
      onSurfaceAccent:
          Color.lerp(onSurfaceAccent, other.onSurfaceAccent, t)!,
      onSurfaceAccentSecondary: Color.lerp(
          onSurfaceAccentSecondary, other.onSurfaceAccentSecondary, t)!,
      onSurfaceAccentMuted:
          Color.lerp(onSurfaceAccentMuted, other.onSurfaceAccentMuted, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
      scrimSubtle: Color.lerp(scrimSubtle, other.scrimSubtle, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      mediaSurface: Color.lerp(mediaSurface, other.mediaSurface, t)!,
      onMediaSurface: Color.lerp(onMediaSurface, other.onMediaSurface, t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColors get c => Theme.of(this).extension<AppColors>()!;
}
