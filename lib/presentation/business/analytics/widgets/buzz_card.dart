import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class BuzzCard extends StatelessWidget {
  final BuzzAnalyticsResponse data;
  const BuzzCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final rankLabel = (data.rankInCohort != null && data.cohortSize != null)
        ? '#${data.rankInCohort} من ${data.cohortSize}'
        : '—';
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_buzz_title.tr(),
      subtitle: LocaleKeys.business_analytics_buzz_subtitle_week.tr(
        namedArgs: {'week': data.weekStart},
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.buzzScore.toStringAsFixed(1),
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      TablerIcons.trophy,
                      color: c.onSurfaceSecondary,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rankLabel,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                if (data.deltaFromPrev != null) ...[
                  const SizedBox(height: 6),
                  _DeltaPill(delta: data.deltaFromPrev!),
                ] else ...[
                  const SizedBox(height: 6),
                  Text(
                    LocaleKeys.business_analytics_buzz_new_this_week.tr(),
                    style: TextStyle(
                      color: c.onSurfaceMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (data.trend.length >= 2)
            SizedBox(
              width: 110,
              height: 56,
              child: _Sparkline(points: data.trend),
            ),
        ],
      ),
    );
  }
}

class _DeltaPill extends StatelessWidget {
  final double delta;
  const _DeltaPill({required this.delta});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isUp = delta >= 0;
    final color = isUp ? c.success : c.danger;
    final icon = isUp ? TablerIcons.trending_up : TablerIcons.trending_down;
    final sign = isUp ? '+' : '';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
          Text(
            '$sign${delta.toStringAsFixed(1)}',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<BuzzTrendPoint> points;
  const _Sparkline({required this.points});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].buzzScore),
    ];
    final values = points.map((p) => p.buzzScore).toList();
    final minY = values.reduce((a, b) => a < b ? a : b);
    final maxY = values.reduce((a, b) => a > b ? a : b);
    final pad = (maxY - minY).abs() < 0.001 ? 1.0 : (maxY - minY) * 0.2;
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: minY - pad,
        maxY: maxY + pad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            barWidth: 2,
            color: c.primary,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: c.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
