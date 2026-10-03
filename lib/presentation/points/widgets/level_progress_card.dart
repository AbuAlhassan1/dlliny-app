import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/points/controllers/user_points_bloc.dart';

class LevelProgressCard extends StatelessWidget {
  const LevelProgressCard({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<UserPointsBloc, UserPointsState>(
      builder: (context, state) {
        final p = state.points;
        if (p == null) {
          return const SizedBox(height: 72);
        }

        final progressFraction = p.isMaxLevel
            ? 1.0
            : _progressWithinLevel(p);

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: c.divider),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _LevelBadge(level: p.level, isMax: p.isMaxLevel),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          LocaleKeys.points_total_points
                              .plural(p.totalPoints, format: NumberFormat.compact()),
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.isMaxLevel
                              ? LocaleKeys.points_max_level_caption.tr()
                              : LocaleKeys.points_to_next_level.tr(
                                  namedArgs: {
                                    'points': p.pointsToNextLevel.toString(),
                                    'level': (p.level + 1).toString(),
                                  },
                                ),
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 12,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progressFraction,
                  minHeight: 6,
                  backgroundColor: c.surfaceMuted,
                  valueColor: AlwaysStoppedAnimation<Color>(c.primary),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _progressWithinLevel(dynamic p) {
    final band = (p.nextLevelThreshold as int) - (p.currentLevelThreshold as int);
    if (band <= 0) return 0;
    final covered = (p.totalPoints as int) - (p.currentLevelThreshold as int);
    return (covered / band).clamp(0.0, 1.0);
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;
  final bool isMax;
  const _LevelBadge({required this.level, required this.isMax});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: isMax ? c.success : c.primary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: isMax
          ? Icon(TablerIcons.trophy_filled, color: c.onPrimary, size: 22)
          : Text(
              '$level',
              style: TextStyle(
                color: c.onPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
    );
  }
}
