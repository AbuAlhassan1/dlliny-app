import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/open_directions.dart';

Future<void> showVenueDirectionsSheet(
  BuildContext context,
  List<VenueLocationResponse> locations,
) {
  final sorted = [...locations]..sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _VenueDirectionsSheet(locations: sorted),
  );
}

class _VenueDirectionsSheet extends StatelessWidget {
  final List<VenueLocationResponse> locations;
  const _VenueDirectionsSheet({required this.locations});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: c.surfaceElevated,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Center(child: _Handle()),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(TablerIcons.route, color: c.onSurface, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    LocaleKeys.venue_branches_section_title.tr(),
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: locations.length,
                itemBuilder: (context, index) => _BranchRow(
                  branch: locations[index],
                  onTap: () {
                    Navigator.of(context).pop();
                    openDirections(
                      latitude: locations[index].latitude,
                      longitude: locations[index].longitude,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final VenueLocationResponse branch;
  final VoidCallback onTap;
  const _BranchRow({required this.branch, required this.onTap});

  String _title() {
    final label = branch.labelAr;
    if (label != null && label.trim().isNotEmpty) return label;
    return (branch.isPrimary
            ? LocaleKeys.venue_branches_primary_branch
            : LocaleKeys.venue_branches_branch_fallback)
        .tr();
  }

  String _subtitle() {
    final parts = <String>[
      if (branch.addressAr != null && branch.addressAr!.trim().isNotEmpty)
        branch.addressAr!.trim(),
      if (branch.districtNameAr != null) branch.districtNameAr!,
      if (branch.cityNameAr != null) branch.cityNameAr!,
    ];
    return parts.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final subtitle = _subtitle();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(TablerIcons.map_pin, color: c.onSurfaceSecondary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _title(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (branch.isPrimary) ...[
                        const SizedBox(width: 6),
                        Icon(
                          TablerIcons.star_filled,
                          color: c.primary,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              TablerIcons.chevron_left,
              color: c.onSurfaceDisabled,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: context.c.onSurfaceDisabled,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}
