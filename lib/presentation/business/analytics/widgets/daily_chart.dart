import 'package:easy_localization/easy_localization.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class DailyChart extends StatefulWidget {
  final DailySeriesResponse data;
  const DailyChart({super.key, required this.data});

  @override
  State<DailyChart> createState() => _DailyChartState();
}

enum _Metric { mentions, followers, reviews }

class _DailyChartState extends State<DailyChart> {
  _Metric _metric = _Metric.mentions;

  List<int>? _cachedSeries;
  DailySeriesResponse? _cachedDataRef;
  _Metric? _cachedMetric;

  int _valueFor(DailyPoint p) {
    switch (_metric) {
      case _Metric.mentions:
        return p.memoryMentionCount;
      case _Metric.followers:
        return p.newFollowers;
      case _Metric.reviews:
        return p.reviewCount;
    }
  }

  String _labelFor(_Metric m) {
    switch (m) {
      case _Metric.mentions:
        return LocaleKeys.business_analytics_daily_mentions.tr();
      case _Metric.followers:
        return LocaleKeys.business_analytics_daily_followers.tr();
      case _Metric.reviews:
        return LocaleKeys.business_analytics_daily_reviews.tr();
    }
  }

  @override
  void didUpdateWidget(covariant DailyChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.data, widget.data)) {
      _cachedSeries = null;
      _cachedDataRef = null;
    }
  }

  List<int> _filledSeries() {
    if (_cachedSeries != null &&
        identical(_cachedDataRef, widget.data) &&
        _cachedMetric == _metric) {
      return _cachedSeries!;
    }
    final from = DateTime.parse(widget.data.from);
    final to = DateTime.parse(widget.data.to);
    final byDate = <String, DailyPoint>{
      for (final p in widget.data.points) p.date: p,
    };
    final days = to.difference(from).inDays + 1;
    final series = [
      for (var i = 0; i < days; i++)
        () {
          final d = from.add(Duration(days: i));
          final key =
              '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
          final point = byDate[key];
          return point == null ? 0 : _valueFor(point);
        }(),
    ];
    _cachedSeries = series;
    _cachedDataRef = widget.data;
    _cachedMetric = _metric;
    return series;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final series = _filledSeries();
    final hasAny = series.any((v) => v > 0);
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_daily_title.tr(),
      subtitle: '${widget.data.from} → ${widget.data.to}',
      trailing: _MetricToggle(
        current: _metric,
        onChanged: (m) => setState(() => _metric = m),
        labelFor: _labelFor,
      ),
      child: hasAny
          ? SizedBox(
              height: 160,
              child: _LineChart(
                series: series,
                color: c.primary,
                fillColor: c.primary.withValues(alpha: 0.12),
                gridColor: c.divider,
                tickColor: c.onSurfaceMuted,
              ),
            )
          : AnalyticsTileEmpty(
              icon: TablerIcons.chart_line,
              message: LocaleKeys.business_analytics_daily_empty.tr(),
            ),
    );
  }
}

class _MetricToggle extends StatelessWidget {
  final _Metric current;
  final ValueChanged<_Metric> onChanged;
  final String Function(_Metric) labelFor;

  const _MetricToggle({
    required this.current,
    required this.onChanged,
    required this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: 26,
      child: ToggleButtons(
        isSelected: [
          for (final m in _Metric.values) m == current,
        ],
        onPressed: (i) => onChanged(_Metric.values[i]),
        borderRadius: BorderRadius.circular(18),
        constraints: const BoxConstraints(minWidth: 56, minHeight: 26),
        selectedColor: c.onPrimary,
        fillColor: c.primary,
        color: c.onSurfaceSecondary,
        borderColor: c.border,
        selectedBorderColor: c.primary,
        textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        children: [
          for (final m in _Metric.values)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(labelFor(m)),
            ),
        ],
      ),
    );
  }
}

class _LineChart extends StatelessWidget {
  final List<int> series;
  final Color color;
  final Color fillColor;
  final Color gridColor;
  final Color tickColor;

  const _LineChart({
    required this.series,
    required this.color,
    required this.fillColor,
    required this.gridColor,
    required this.tickColor,
  });

  @override
  Widget build(BuildContext context) {
    final spots = <FlSpot>[
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].toDouble()),
    ];
    final maxV = series.fold<int>(0, (m, v) => v > m ? v : m);
    final maxY = (maxV == 0 ? 4 : maxV).toDouble();
    final yPad = maxY * 0.15;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
          getDrawingHorizontalLine: (_) =>
              FlLine(color: gridColor, strokeWidth: 0.5),
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
              getTitlesWidget: (value, _) => Text(
                value.toInt().toString(),
                style: TextStyle(color: tickColor, fontSize: 10),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: true),
        minY: 0,
        maxY: maxY + yPad,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.25,
            barWidth: 2,
            color: color,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(show: true, color: fillColor),
          ),
        ],
      ),
    );
  }
}
