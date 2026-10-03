import 'package:flutter/material.dart';

LinearGradient appPageGradient(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  if (isDark) {
    return const LinearGradient(
      begin: AlignmentDirectional.topStart,
      end: AlignmentDirectional.bottomEnd,
      colors: [
        Color(0xFF0A1016),
        Color(0xFF080D12),
        Color(0xFF06090D),
        Color(0xFF000000),
      ],
      stops: [0.0, 0.35, 0.7, 1.0],
    );
  }
  return const LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [
      Color(0xFFF2F4F7),
      Color(0xFFEDF0F4),
      Color(0xFFF7F9FB),
      Color(0xFFFFFFFF),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
  );
}
