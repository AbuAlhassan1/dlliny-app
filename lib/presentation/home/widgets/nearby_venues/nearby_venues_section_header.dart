import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class NearbyVenuesSectionHeader extends StatelessWidget {
  final VoidCallback? onShowAll;
  const NearbyVenuesSectionHeader({super.key, this.onShowAll});

  @override
  Widget build(BuildContext context) {
    final c = context.c;

    final nearbyState = context.watch<NearbyVenuesBloc>().state;
    final deviceLocation = nearbyState is NearbyVenuesLoaded
        ? nearbyState.locationName?.trim()
        : null;
    final location = (deviceLocation != null && deviceLocation.isNotEmpty)
        ? deviceLocation
        : _profileLocation(context.watch<MyProfileBloc>().user);

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 15, end: 8),
      child: Row(
        children: [
          Icon(TablerIcons.map_pin, size: 16, color: c.onSurface),
          const SizedBox(width: 6),
          Text(
            LocaleKeys.home_nearby_venues_section_title.tr(),
            style: TextStyle(
              color: c.onSurface,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          if (location != null) ...[
            const SizedBox(width: 6),
            Text(
              '·',
              style: TextStyle(color: c.onSurfaceMuted, fontSize: 15),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                location,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _profileLocation(UserDto? user) {
    if (user == null) return null;
    final district = user.district?.trim();
    if (district != null && district.isNotEmpty) return district;
    final city = user.city?.trim();
    if (city != null && city.isNotEmpty) return city;
    return null;
  }
}
