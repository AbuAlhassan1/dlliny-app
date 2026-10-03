import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class MoversStrip extends StatelessWidget {
  final MoversResponse data;
  const MoversStrip({super.key, required this.data});

  String _title() {
    return (data.direction == 'fallers'
            ? LocaleKeys.business_analytics_movers_title_fallers
            : LocaleKeys.business_analytics_movers_title_risers)
        .tr();
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsTile(
      title: _title(),
      subtitle: LocaleKeys.business_analytics_movers_subtitle_week.tr(
        namedArgs: {'week': data.weekStart},
      ),
      child: data.entries.isEmpty
          ? AnalyticsTileEmpty(
              icon: TablerIcons.trending_up,
              message: LocaleKeys.business_analytics_movers_empty.tr(),
            )
          : SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: data.entries.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (_, i) => _MoverCard(entry: data.entries[i]),
              ),
            ),
    );
  }
}

class _MoverCard extends StatelessWidget {
  final MoverEntry entry;
  const _MoverCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final delta = entry.deltaFromPrev;
    final isUp = delta >= 0;
    final accent = isUp ? c.success : c.danger;
    final highlight = entry.isYou;

    return Container(
      width: 160,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: highlight
            ? c.primary.withValues(alpha: 0.10)
            : c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: highlight
              ? c.primary.withValues(alpha: 0.4)
              : c.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.venueNameAr.isNotEmpty
                      ? entry.venueNameAr
                      : entry.venueNameEn,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              if (highlight)
                Icon(TablerIcons.point_filled, color: c.primary, size: 12),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(
                isUp ? TablerIcons.trending_up : TablerIcons.trending_down,
                color: accent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Text(
                '${isUp ? '+' : ''}${delta.toStringAsFixed(1)}',
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.rankInCohort == null
                ? LocaleKeys.business_analytics_movers_points.tr(
                    namedArgs: {'score': entry.buzzScore.toStringAsFixed(1)},
                  )
                : '#${entry.rankInCohort} · ${entry.buzzScore.toStringAsFixed(1)}',
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
