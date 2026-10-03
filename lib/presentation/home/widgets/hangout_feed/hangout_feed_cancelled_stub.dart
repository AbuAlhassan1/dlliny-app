import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class HangoutFeedCancelledStub extends StatelessWidget {
  final String? title;
  const HangoutFeedCancelledStub({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 14),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.onSurface.withValues(alpha: 0.06),
        ),
      ),
      child: Row(
        children: [
          Icon(
            TablerIcons.calendar_off,
            color: c.onSurfaceSecondary,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title?.isNotEmpty == true
                  ? LocaleKeys.hangout_cancelled_with_title.tr(
                      namedArgs: {'title': title!},
                    )
                  : LocaleKeys.hangout_cancelled_generic.tr(),
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
