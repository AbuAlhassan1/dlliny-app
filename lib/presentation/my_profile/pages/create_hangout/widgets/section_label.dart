import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class SectionLabel extends StatelessWidget {
  final String label;
  const SectionLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      label,
      style: TextStyle(color: c.onSurfaceMuted, fontSize: 12),
    );
  }
}
