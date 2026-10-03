import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class ReelPlayBadge extends StatelessWidget {
  const ReelPlayBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return IgnorePointer(
      child: Center(
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: c.scrimSubtle,
          ),
          child: Icon(
            TablerIcons.player_play_filled,
            color: c.onMediaSurface,
            size: 30,
          ),
        ),
      ),
    );
  }
}
