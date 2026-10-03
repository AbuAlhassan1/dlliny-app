import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class FootfallHeatmap extends StatelessWidget {
  final FootfallHeatmapResponse data;

  final String? title;
  final String? subtitle;

  const FootfallHeatmap({
    super.key,
    required this.data,
    this.title,
    this.subtitle,
  });

  List<String> _dayLabels() => [
        LocaleKeys.business_analytics_footfall_day_sun.tr(),
        LocaleKeys.business_analytics_footfall_day_mon.tr(),
        LocaleKeys.business_analytics_footfall_day_tue.tr(),
        LocaleKeys.business_analytics_footfall_day_wed.tr(),
        LocaleKeys.business_analytics_footfall_day_thu.tr(),
        LocaleKeys.business_analytics_footfall_day_fri.tr(),
        LocaleKeys.business_analytics_footfall_day_sat.tr(),
      ];

  Map<int, Map<int, int>> _grid() {
    final grid = <int, Map<int, int>>{};
    for (final cell in data.cells) {
      grid.putIfAbsent(cell.dayOfWeek, () => {})[cell.hourOfDay] = cell.count;
    }
    return grid;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final grid = _grid();
    final maxCount = data.maxCount == 0 ? 1 : data.maxCount;
    final dayLabels = _dayLabels();

    return AnalyticsTile(
      title: title ?? LocaleKeys.business_analytics_footfall_title.tr(),
      subtitle: subtitle ??
          LocaleKeys.business_analytics_footfall_subtitle_30_days.tr(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 32),
            child: Row(
              children: [
                for (final h in [0, 6, 12, 18])
                  Expanded(
                    flex: 1,
                    child: Text(
                      h.toString().padLeft(2, '0'),
                      style: TextStyle(
                        color: c.onSurfaceMuted,
                        fontSize: 9,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          for (var day = 0; day < 7; day++) ...[
            _DayRow(
              label: dayLabels[day],
              hours: grid[day] ?? const {},
              maxCount: maxCount,
              cellColor: c.primary,
              labelColor: c.onSurfaceSecondary,
              emptyColor: c.onSurface.withValues(alpha: 0.05),
            ),
            const SizedBox(height: 3),
          ],
          if (data.privacyFloorApplied) ...[
            const SizedBox(height: 10),
            _PrivacyFootnote(),
          ],
        ],
      ),
    );
  }
}

class _DayRow extends StatelessWidget {
  final String label;
  final Map<int, int> hours;
  final int maxCount;
  final Color cellColor;
  final Color labelColor;
  final Color emptyColor;

  const _DayRow({
    required this.label,
    required this.hours,
    required this.maxCount,
    required this.cellColor,
    required this.labelColor,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            label,
            style: TextStyle(color: labelColor, fontSize: 10),
          ),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Row(
            children: [
              for (var h = 0; h < 24; h++)
                Expanded(
                  child: _Cell(
                    count: hours[h] ?? 0,
                    maxCount: maxCount,
                    fillColor: cellColor,
                    emptyColor: emptyColor,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  final int count;
  final int maxCount;
  final Color fillColor;
  final Color emptyColor;

  const _Cell({
    required this.count,
    required this.maxCount,
    required this.fillColor,
    required this.emptyColor,
  });

  @override
  Widget build(BuildContext context) {
    final raw = (count / maxCount).clamp(0.0, 1.0);
    final eased = raw == 0 ? 0.0 : 0.18 + 0.82 * raw;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 0.5, vertical: 0.5),
      child: Tooltip(
        message: '$count',
        triggerMode: TooltipTriggerMode.tap,
        child: Container(
          height: 14,
          decoration: BoxDecoration(
            color: count == 0
                ? emptyColor
                : fillColor.withValues(alpha: eased),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}

class _PrivacyFootnote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Icon(TablerIcons.shield_lock, color: c.onSurfaceMuted, size: 12),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            LocaleKeys.business_analytics_footfall_privacy_note.tr(),
            style: TextStyle(
              color: c.onSurfaceMuted,
              fontSize: 10,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
