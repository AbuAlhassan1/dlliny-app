import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class PeopleNearbyEnableCard extends StatelessWidget {
  final bool busy;

  final VoidCallback onEnable;

  const PeopleNearbyEnableCard({
    super.key,
    required this.busy,
    required this.onEnable,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Line(
              icon: TablerIcons.map_pin,
              text: LocaleKeys.people_nearby_enable_line_area.tr(),
            ),
            const SizedBox(height: 8),
            _Line(
              icon: TablerIcons.users,
              text: LocaleKeys.people_nearby_enable_line_mutual_opt_in.tr(),
            ),
            const SizedBox(height: 8),
            _Line(
              icon: TablerIcons.eye_off,
              text: LocaleKeys.people_nearby_enable_line_reversible.tr(),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 40,
              child: FilledButton(
                onPressed: busy ? null : onEnable,
                style: FilledButton.styleFrom(
                  backgroundColor: c.primary,
                  foregroundColor: c.onPrimary,
                  disabledBackgroundColor: c.primary,
                  disabledForegroundColor: c.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: busy
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.onPrimary,
                        ),
                      )
                    : Text(
                        LocaleKeys.people_nearby_enable_cta.tr(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Line({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 15, color: c.onSurfaceSecondary),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }
}
