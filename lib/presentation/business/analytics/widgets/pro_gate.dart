import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/paywall_sheet.dart';

class ProGate extends StatelessWidget {
  final bool locked;

  final String feature;

  final Widget child;

  const ProGate({
    super.key,
    required this.locked,
    required this.feature,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!locked) return child;
    final c = context.c;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Stack(
        children: [
          IgnorePointer(
            child: Opacity(opacity: 0.55, child: child),
          ),
          Positioned.fill(
            child: Container(color: c.scrimSubtle),
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () =>
                    showAnalyticsPaywallSheet(context, feature: feature),
                child: Center(
                  child: _UnlockPill(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnlockPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: c.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.crown, color: c.onPrimary, size: 16),
          const SizedBox(width: 8),
          Text(
            LocaleKeys.business_analytics_pro_gate_unlock_pill.tr(),
            style: TextStyle(
              color: c.onPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
