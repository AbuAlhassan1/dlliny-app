import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class MemoryCaption extends StatelessWidget {
  final String text;

  const MemoryCaption({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Positioned(
      left: 16,
      right: 16,
      bottom: 100,
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: c.onMediaSurface,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          shadows: [Shadow(blurRadius: 8, color: c.scrimSubtle)],
        ),
      ),
    );
  }
}
