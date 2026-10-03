import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class FunnelViz extends StatelessWidget {
  final ConversionFunnelResponse data;
  const FunnelViz({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final impressions = data.totalImpressions;
    final stages = <_FunnelStage>[
      _FunnelStage(
        label: LocaleKeys.business_analytics_funnel_stage_reach.tr(),
        value: impressions,
        icon: TablerIcons.eye,
        color: c.primary,
        sampled: true,
      ),
      _FunnelStage(
        label: LocaleKeys.business_analytics_funnel_stage_profile.tr(),
        value: data.profileViews,
        icon: TablerIcons.user_search,
        color: c.onSurface,
        sampled: true,
      ),
      _FunnelStage(
        label: LocaleKeys.business_analytics_funnel_stage_followers.tr(),
        value: data.newFollowers,
        icon: TablerIcons.user_plus,
        color: c.accent,
      ),
      _FunnelStage(
        label: LocaleKeys.business_analytics_funnel_stage_visit_intent.tr(),
        value: data.visitIntent,
        icon: TablerIcons.map_pin,
        color: c.success,
      ),
      _FunnelStage(
        label: LocaleKeys.business_analytics_funnel_stage_repeat_visit.tr(),
        value: data.repeatVisitors,
        icon: TablerIcons.repeat,
        color: c.warning,
      ),
    ];

    final maxV = stages.fold<int>(
      0,
      (m, s) => s.value > m ? s.value : m,
    );
    final scale = maxV == 0 ? 1 : maxV;

    return AnalyticsTile(
      title: LocaleKeys.business_analytics_funnel_title.tr(),
      subtitle: '${data.from} → ${data.to}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final stage in stages) ...[
            _StageRow(stage: stage, scale: scale.toDouble()),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          _SampleRateFootnote(rate: data.impressionsSampleRate),
        ],
      ),
    );
  }
}

class _FunnelStage {
  final String label;
  final int value;
  final IconData icon;
  final Color color;
  final bool sampled;
  const _FunnelStage({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.sampled = false,
  });
}

class _StageRow extends StatelessWidget {
  final _FunnelStage stage;
  final double scale;
  const _StageRow({required this.stage, required this.scale});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final fraction = (stage.value / scale).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(stage.icon, color: c.onSurfaceSecondary, size: 14),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                stage.label,
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
              ),
            ),
            Text(
              '${stage.value}',
              style: TextStyle(
                color: c.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
            if (stage.sampled) ...[
              const SizedBox(width: 4),
              Icon(
                TablerIcons.percentage,
                color: c.onSurfaceMuted,
                size: 11,
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: c.onSurface.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: fraction.isNaN ? 0.0 : fraction,
              child: Container(
                height: 8,
                decoration: BoxDecoration(
                  color: stage.color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _SampleRateFootnote extends StatelessWidget {
  final double rate;
  const _SampleRateFootnote({required this.rate});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = (rate * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: c.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.info_circle, color: c.onSurfaceMuted, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              LocaleKeys.business_analytics_funnel_sample_disclaimer.tr(
                namedArgs: {'pct': '$pct'},
              ),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 11,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
