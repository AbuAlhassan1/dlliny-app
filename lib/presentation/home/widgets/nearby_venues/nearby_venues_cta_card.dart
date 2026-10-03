import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';

class NearbyVenuesPermissionDeniedCard extends StatelessWidget {
  final bool canRetry;
  const NearbyVenuesPermissionDeniedCard({
    super.key,
    required this.canRetry,
  });

  @override
  Widget build(BuildContext context) {
    return _CtaCard(
      icon: TablerIcons.map_pin_off,
      title: LocaleKeys.home_nearby_venues_cta_permission_title.tr(),
      ctaLabel: canRetry
          ? LocaleKeys.home_nearby_venues_cta_enable_location.tr()
          : LocaleKeys.home_nearby_venues_cta_open_settings.tr(),
      onTap: () => context
          .read<NearbyVenuesBloc>()
          .add(RequestNearbyVenuesPermission()),
    );
  }
}

class NearbyVenuesLocationDisabledCard extends StatelessWidget {
  const NearbyVenuesLocationDisabledCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _CtaCard(
      icon: TablerIcons.location_off,
      title: LocaleKeys.home_nearby_venues_cta_disabled_title.tr(),
      ctaLabel: LocaleKeys.home_nearby_venues_cta_open_settings.tr(),
      onTap: () => context
          .read<NearbyVenuesBloc>()
          .add(RequestNearbyVenuesPermission()),
    );
  }
}

class _CtaCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String ctaLabel;
  final VoidCallback onTap;
  const _CtaCard({
    required this.icon,
    required this.title,
    required this.ctaLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 16, end: 16),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.onSurfaceSecondary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onTap,
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                ctaLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
