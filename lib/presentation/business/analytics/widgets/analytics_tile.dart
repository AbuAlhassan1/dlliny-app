import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class AnalyticsTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;

  const AnalyticsTile({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class AnalyticsTileLoading extends StatelessWidget {
  final double height;
  const AnalyticsTileLoading({super.key, this.height = 80});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SizedBox(
      height: height,
      child: Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: c.onSurface),
        ),
      ),
    );
  }
}

class AnalyticsTileError extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const AnalyticsTileError({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Icon(TablerIcons.alert_circle, color: c.danger, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 10),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton.icon(
              onPressed: onRetry,
              icon: Icon(TablerIcons.refresh, size: 16, color: c.onSurface),
              label: Text(
                LocaleKeys.common_retry.tr(),
                style: TextStyle(color: c.onSurface),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class AnalyticsTileEmpty extends StatelessWidget {
  final String? message;
  final IconData icon;
  const AnalyticsTileEmpty({
    super.key,
    this.message,
    this.icon = TablerIcons.chart_dots,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceDisabled, size: 28),
            const SizedBox(height: 6),
            Text(
              message ?? LocaleKeys.business_analytics_empty_no_data.tr(),
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
