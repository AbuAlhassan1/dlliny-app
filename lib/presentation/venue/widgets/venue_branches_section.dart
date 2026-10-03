import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';
import 'package:hangout/presentation/venue/widgets/venue_branch_sheet.dart';

class VenueBranchesSection extends StatelessWidget {
  const VenueBranchesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VenueBloc, VenueState>(
      builder: (context, state) {
        if (state is! GetVenueDetailsLoaded) return const SizedBox.shrink();
        if (state.venue.onlineOnly) return const SizedBox.shrink();
        final branches = state.venue.locations;
        if (branches.length <= 1) return const SizedBox.shrink();

        final sorted = [...branches]..sort((a, b) {
            if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
            return a.sortOrder.compareTo(b.sortOrder);
          });

        final fallback = state.venue.openingHours;
        final hoursBloc = maybeVenueHoursBloc(context);
        if (hoursBloc == null) {
          return _Section(branches: sorted, hours: fallback);
        }
        return BlocBuilder<VenueHoursBloc, VenueHoursState>(
          bloc: hoursBloc,
          builder: (context, hoursState) => _Section(
            branches: sorted,
            hours: hoursState.dto ?? fallback,
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final List<VenueLocationResponse> branches;

  final VenueOpeningHoursDto? hours;
  const _Section({required this.branches, this.hours});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.background,
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              children: [
                Icon(TablerIcons.building, color: c.onSurface, size: 18),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.venue_branches_section_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '· ${branches.length}',
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              itemCount: branches.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final branch = branches[index];
                return _BranchPill(
                  branch: branch,
                  status: hours?.branch(branch.id)?.status,
                  onTap: () =>
                      showVenueBranchSheet(context, branch, hours: hours),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchPill extends StatelessWidget {
  final VenueLocationResponse branch;

  final OpenStatusDto? status;
  final VoidCallback onTap;
  const _BranchPill({required this.branch, this.status, required this.onTap});

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
      if (branch.districtNameAr != null) branch.districtNameAr!,
      if (branch.cityNameAr != null) branch.cityNameAr!,
    ];
    return parts.join('، ');
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 200,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Icon(
                    TablerIcons.map_pin,
                    color: c.onSurfaceSecondary,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      _title(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (isStatusVisible(status)) ...[
                    const SizedBox(width: 6),
                    VenueOpenStatusDot(status: status),
                  ],
                  if (branch.isPrimary) ...[
                    const SizedBox(width: 4),
                    Icon(
                      TablerIcons.star_filled,
                      color: c.primary,
                      size: 12,
                    ),
                  ],
                ],
              ),
              if (_subtitle().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  _subtitle(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
