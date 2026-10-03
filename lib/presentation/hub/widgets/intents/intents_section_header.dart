import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class IntentsSectionHeader extends StatelessWidget {
  final bool isRefreshing;
  const IntentsSectionHeader({super.key, this.isRefreshing = false});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
      child: Row(
        children: [
          Icon(TablerIcons.bulb, size: 22, color: c.onSurface),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.hub_intents_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 20,
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
    );
  }
}
