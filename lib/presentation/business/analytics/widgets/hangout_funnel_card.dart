import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class HangoutFunnelCard extends StatelessWidget {
  final HangoutFunnelResponse data;
  const HangoutFunnelCard({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final maxV = [
      data.hangoutsCreated,
      data.invited,
      data.accepted,
      data.declined,
      data.pendingNow,
      data.acceptedAfterEvent,
    ].reduce((a, b) => a > b ? a : b);
    final scale = maxV == 0 ? 1 : maxV;

    return AnalyticsTile(
      title: LocaleKeys.business_analytics_hangout_funnel_title.tr(),
      subtitle: '${data.from} → ${data.to}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(
            icon: TablerIcons.calendar_event,
            label: LocaleKeys.business_analytics_hangout_funnel_label_created.tr(),
            value: data.hangoutsCreated,
            fraction: data.hangoutsCreated / scale,
            color: c.primary,
          ),
          _Row(
            icon: TablerIcons.send,
            label: LocaleKeys.business_analytics_hangout_funnel_label_invites.tr(),
            value: data.invited,
            fraction: data.invited / scale,
            color: c.onSurface,
          ),
          _Row(
            icon: TablerIcons.check,
            label: LocaleKeys.business_analytics_hangout_funnel_label_accepted.tr(),
            value: data.accepted,
            fraction: data.accepted / scale,
            color: c.success,
          ),
          _Row(
            icon: TablerIcons.x,
            label: LocaleKeys.business_analytics_hangout_funnel_label_rejected.tr(),
            value: data.declined,
            fraction: data.declined / scale,
            color: c.danger,
          ),
          _Row(
            icon: TablerIcons.clock,
            label: LocaleKeys.business_analytics_hangout_funnel_label_pending.tr(),
            value: data.pendingNow,
            fraction: data.pendingNow / scale,
            color: c.warning,
          ),
          _Row(
            icon: TablerIcons.map_pin_check,
            label: LocaleKeys.business_analytics_hangout_funnel_label_estimated_attendance.tr(),
            tooltip: LocaleKeys.business_analytics_hangout_funnel_attendance_note.tr(),
            value: data.acceptedAfterEvent,
            fraction: data.acceptedAfterEvent / scale,
            color: c.accent,
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? tooltip;
  final int value;
  final num fraction;
  final Color color;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    required this.fraction,
    required this.color,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final pct = fraction.clamp(0.0, 1.0).toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, color: c.onSurfaceSecondary, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
              ),
              if (tooltip != null) ...[
                const SizedBox(width: 4),
                Tooltip(
                  message: tooltip!,
                  triggerMode: TooltipTriggerMode.tap,
                  child: Icon(
                    TablerIcons.info_circle,
                    size: 12,
                    color: c.onSurfaceMuted,
                  ),
                ),
              ],
              const Spacer(),
              Text(
                '$value',
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              minHeight: 6,
              value: pct,
              backgroundColor: c.onSurface.withValues(alpha: 0.06),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
