import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

Future<void> showAnalyticsPaywallSheet(
  BuildContext context, {
  required String feature,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _PaywallBody(feature: feature),
  );
}

class _PaywallBody extends StatelessWidget {
  final String feature;
  const _PaywallBody({required this.feature});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.onSurfaceDisabled,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: c.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(TablerIcons.crown, color: c.primary, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              feature,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              LocaleKeys.business_analytics_paywall_feature_subtitle.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 14),
            ),
            const SizedBox(height: 18),
            _Bullet(
              icon: TablerIcons.chart_arcs,
              text: LocaleKeys.business_analytics_paywall_bullet_competitive.tr(),
            ),
            const SizedBox(height: 10),
            _Bullet(
              icon: TablerIcons.users_group,
              text: LocaleKeys.business_analytics_paywall_bullet_audience.tr(),
            ),
            const SizedBox(height: 10),
            _Bullet(
              icon: TablerIcons.filter,
              text: LocaleKeys.business_analytics_paywall_bullet_funnel.tr(),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(TablerIcons.sparkles, size: 18),
              label: Text(
                LocaleKeys.business_analytics_paywall_upgrade_cta.tr(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              LocaleKeys.business_analytics_paywall_billing_soon.tr(),
              textAlign: TextAlign.center,
              style: TextStyle(color: c.onSurfaceMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Bullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: c.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: c.onSurface, fontSize: 13, height: 1.4),
          ),
        ),
      ],
    );
  }
}
