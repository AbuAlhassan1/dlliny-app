import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class PeerBenchmarkBars extends StatelessWidget {
  final PeerBenchmarkResponse data;
  const PeerBenchmarkBars({super.key, required this.data});

  String _labelFor(String key) {
    switch (key) {
      case 'memory_mentions':
        return LocaleKeys.business_analytics_peer_benchmark_metric_story_mentions.tr();
      case 'hangout_attendees':
        return LocaleKeys.business_analytics_peer_benchmark_metric_attendance.tr();
      case 'post_count':
        return LocaleKeys.business_analytics_peer_benchmark_metric_posts.tr();
      case 'new_followers':
        return LocaleKeys.business_analytics_peer_benchmark_metric_new_followers.tr();
      case 'review_count':
        return LocaleKeys.business_analytics_peer_benchmark_metric_reviews.tr();
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_peer_benchmark_title.tr(),
      subtitle: '${data.from} → ${data.to}',
      child: data.metrics.isEmpty
          ? AnalyticsTileEmpty(
              icon: TablerIcons.chart_arrows,
              message: LocaleKeys.business_analytics_peer_benchmark_empty.tr(),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final metric in data.metrics) ...[
                  _MetricRow(
                    label: _labelFor(metric.key),
                    metric: metric,
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final BenchmarkMetric metric;
  const _MetricRow({required this.label, required this.metric});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final lo = [metric.p25, metric.you].reduce((a, b) => a < b ? a : b);
    final hi = [metric.p75, metric.you].reduce((a, b) => a > b ? a : b);
    final span = (hi - lo).abs() < 0.001 ? 1.0 : (hi - lo);
    final padded = lo - span * 0.1;
    final paddedHi = hi + span * 0.1;
    final range = paddedHi - padded;
    double frac(double v) => ((v - padded) / range).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _PercentilePill(percentile: metric.percentileYou),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            return SizedBox(
              height: 22,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 10,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: c.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * frac(metric.p25),
                    width: (w * frac(metric.p75)) -
                        (w * frac(metric.p25)).clamp(0.0, w),
                    top: 8,
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: c.primary.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  Positioned(
                    left: w * frac(metric.median) - 1,
                    top: 4,
                    child: Container(
                      width: 2,
                      height: 14,
                      color: c.onSurfaceSecondary,
                    ),
                  ),
                  Positioned(
                    left: w * frac(metric.you) - 7,
                    top: 4,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: c.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: c.background, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              LocaleKeys.business_analytics_peer_benchmark_you_value.tr(
                namedArgs: {'value': metric.you.toStringAsFixed(0)},
              ),
              style: TextStyle(
                color: c.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              LocaleKeys.business_analytics_peer_benchmark_median_value.tr(
                namedArgs: {'value': metric.median.toStringAsFixed(0)},
              ),
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 11),
            ),
          ],
        ),
      ],
    );
  }
}

class _PercentilePill extends StatelessWidget {
  final int percentile;
  const _PercentilePill({required this.percentile});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isTop = percentile >= 50;
    final tone = isTop ? c.success : c.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        LocaleKeys.business_analytics_peer_benchmark_percentile.tr(
          namedArgs: {'n': '${percentile.clamp(0, 100)}'},
        ),
        style: TextStyle(
          color: tone,
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }
}
