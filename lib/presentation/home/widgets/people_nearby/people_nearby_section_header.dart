import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class PeopleNearbySectionHeader extends StatelessWidget {
  const PeopleNearbySectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 15),
      child: Row(
        children: [
          Icon(TablerIcons.route, size: 16, color: c.onSurface),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.people_nearby_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}
