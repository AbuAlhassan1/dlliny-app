import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class WeeklyVenuesSectionHeader extends StatelessWidget {
  final bool isFallback;

  final bool isRefreshing;
  const WeeklyVenuesSectionHeader({
    super.key,
    required this.isFallback,
    this.isRefreshing = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(TablerIcons.sparkles, size: 18, color: c.onSurface),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.hub_weekly_venues_section_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              if (isRefreshing) ...[
                const SizedBox(width: 8),
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: c.onSurfaceSecondary,
                  ),
                ),
              ],
            ],
          ),
          if (isFallback) ...[
            const SizedBox(height: 2),
            Text(
              LocaleKeys.hub_weekly_venues_section_subtitle.tr(),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontWeight: FontWeight.w500,
                fontSize: 11,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ],
      ),
    );
  }
}
