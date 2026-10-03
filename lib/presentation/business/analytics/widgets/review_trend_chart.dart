import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class ReviewTrendChart extends StatefulWidget {
  final ReviewTrendResponse data;
  const ReviewTrendChart({super.key, required this.data});

  @override
  State<ReviewTrendChart> createState() => _ReviewTrendChartState();
}

class _ReviewTrendChartState extends State<ReviewTrendChart> {
  List<int>? _cachedCounts;
  ReviewTrendResponse? _cachedDataRef;

  @override
  void didUpdateWidget(covariant ReviewTrendChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _cachedCounts = null;
      _cachedDataRef = null;
    }
  }

  List<int> _filledCounts() {
    if (_cachedCounts != null && identical(_cachedDataRef, widget.data)) {
      return _cachedCounts!;
    }
    final data = widget.data;
    final from = DateTime.parse(data.from);
    final to = DateTime.parse(data.to);
    final byDate = <String, ReviewTrendPoint>{
      for (final p in data.points) p.date: p,
    };
    final days = to.difference(from).inDays + 1;
    final counts = [
      for (var i = 0; i < days; i++)
        () {
          final d = from.add(Duration(days: i));
          final key =
              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          return byDate[key]?.count ?? 0;
        }(),
    ];
    _cachedCounts = counts;
    _cachedDataRef = data;
    return counts;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final data = widget.data;
    final counts = _filledCounts();
    final hasAny = counts.any((v) => v > 0);

    return AnalyticsTile(
      title: LocaleKeys.business_analytics_review_trend_title.tr(),
      subtitle: '${data.from} → ${data.to}',
      trailing: _RatingPill(
        rating: data.trailingAverage,
        total: data.totalReviews,
      ),
      child: hasAny
          ? SizedBox(
              height: 110,
              child: BarChart(
                BarChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  alignment: BarChartAlignment.spaceBetween,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => c.surfaceElevated,
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < counts.length; i++)
                      BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: counts[i].toDouble(),
                            width: 4,
                            borderRadius: BorderRadius.circular(2),
                            color: c.primary,
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            )
          : AnalyticsTileEmpty(
              icon: TablerIcons.star,
              message: LocaleKeys.business_analytics_review_trend_empty.tr(),
            ),
    );
  }
}

class _RatingPill extends StatelessWidget {
  final double rating;
  final int total;
  const _RatingPill({required this.rating, required this.total});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(TablerIcons.star_filled, color: Colors.amber, size: 12),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: const TextStyle(
              color: Colors.amber,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '·  $total',
            style: TextStyle(color: c.onSurfaceMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
