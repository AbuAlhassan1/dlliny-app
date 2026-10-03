import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class LeaderboardCard extends StatelessWidget {
  final CategoryLeaderboardResponse data;
  const LeaderboardCard({super.key, required this.data});

  String _cohortLabel() {
    final cat = data.cohort.categoryNameAr ?? data.cohort.categoryNameEn;
    final dist = data.cohort.districtNameAr ?? data.cohort.districtNameEn;
    if (cat != null && dist != null) return '$cat · $dist';
    return cat ?? dist ?? LocaleKeys.business_analytics_leaderboard_no_group_fallback.tr();
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_leaderboard_title.tr(),
      subtitle: '${_cohortLabel()} · ${data.cohort.size}',
      child: data.entries.isEmpty
          ? AnalyticsTileEmpty(
              icon: TablerIcons.trophy,
              message: LocaleKeys.business_analytics_leaderboard_empty.tr(),
            )
          : Column(
              children: [
                for (final entry in data.entries) _Row(entry: entry),
              ],
            ),
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  const _Row({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final highlight = entry.isYou;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: highlight
            ? c.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: highlight
            ? Border.all(color: c.primary.withValues(alpha: 0.4))
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: highlight ? c.primary : c.onSurfaceSecondary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              entry.venueNameAr.isNotEmpty
                  ? entry.venueNameAr
                  : entry.venueNameEn,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurface,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w500,
                fontSize: 13,
              ),
            ),
          ),
          if (highlight) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: c.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                LocaleKeys.business_analytics_leaderboard_you_indicator.tr(),
                style: TextStyle(
                  color: c.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 10,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
          Text(
            entry.buzzScore.toStringAsFixed(1),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
