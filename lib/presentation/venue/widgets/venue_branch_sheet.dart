import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/venue_hours/venue_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_weekly_hours_table.dart';
import 'package:latlong2/latlong.dart';

Future<void> showVenueBranchSheet(
  BuildContext context,
  VenueLocationResponse branch, {
  VenueOpeningHoursDto? hours,
}) {
  final hoursBloc = maybeVenueHoursBloc(context);
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      final sheet = _VenueBranchSheet(branch: branch, hours: hours);
      if (hoursBloc == null) return sheet;
      return BlocProvider<VenueHoursBloc>.value(
        value: hoursBloc,
        child: sheet,
      );
    },
  );
}

class _VenueBranchSheet extends StatelessWidget {
  final VenueLocationResponse branch;

  final VenueOpeningHoursDto? hours;
  const _VenueBranchSheet({required this.branch, this.hours});

  String _title() {
    final label = branch.labelAr;
    if (label != null && label.trim().isNotEmpty) return label;
    return (branch.isPrimary
            ? LocaleKeys.venue_branches_primary_branch
            : LocaleKeys.venue_branches_branch_fallback)
        .tr();
  }

  String _address() {
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
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 10),
              Center(child: _Handle()),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _title(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (branch.isPrimary)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: c.surfaceAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              TablerIcons.star_filled,
                              color: c.primary,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              LocaleKeys.venue_branches_primary_label.tr(),
                              style: TextStyle(
                                color: c.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              _BranchHours(locationId: branch.id, fallback: hours),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _MapPreview(
                  latitude: branch.latitude,
                  longitude: branch.longitude,
                ),
              ),
              const SizedBox(height: 16),
              if (_address().isNotEmpty)
                _Tile(
                  icon: TablerIcons.map_pin,
                  label: _address(),
                  onTap: () => _copy(
                    context,
                    '${branch.latitude},${branch.longitude}',
                    LocaleKeys.venue_branches_copied_coords.tr(),
                  ),
                ),
              if (branch.phone != null && branch.phone!.trim().isNotEmpty)
                _Tile(
                  icon: TablerIcons.phone,
                  label: branch.phone!,
                  onTap: () => _copy(
                    context,
                    branch.phone!,
                    LocaleKeys.venue_branches_copied_phone.tr(),
                  ),
                ),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Future<void> _copy(BuildContext context, String text, String msg) async {
    await Clipboard.setData(ClipboardData(text: text));
    appToast.success(msg);
  }
}

class _BranchHours extends StatelessWidget {
  final String locationId;
  final VenueOpeningHoursDto? fallback;
  const _BranchHours({required this.locationId, this.fallback});

  @override
  Widget build(BuildContext context) {
    final hoursBloc = maybeVenueHoursBloc(context);
    if (hoursBloc == null) return _build(context, fallback);
    return BlocBuilder<VenueHoursBloc, VenueHoursState>(
      bloc: hoursBloc,
      builder: (context, state) => _build(context, state.dto ?? fallback),
    );
  }

  Widget _build(BuildContext context, VenueOpeningHoursDto? oh) {
    if (oh == null) return const SizedBox.shrink();
    final scope = oh.scopeFor(locationId);
    if (!isStatusVisible(scope.status)) return const SizedBox.shrink();
    final c = context.c;
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(TablerIcons.clock, color: c.onSurface, size: 16),
              const SizedBox(width: 6),
              Text(
                LocaleKeys.venue_hours_title.tr(),
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          VenueOpenStatusLine(status: scope.status),
          if (showsWeeklyHours(scope)) ...[
            const SizedBox(height: 6),
            VenueWeeklyHoursTable(
              scope: scope,
              today: scope.today?.date ?? baghdadToday(oh),
              ramadanWindow: oh.ramadanWindow,
            ),
          ],
        ],
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

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _Tile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: c.onSurfaceSecondary, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: c.onSurface, fontSize: 14),
              ),
            ),
            Icon(
              TablerIcons.copy,
              color: c.onSurfaceDisabled,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _MapPreview extends StatelessWidget {
  final double latitude;
  final double longitude;
  const _MapPreview({required this.latitude, required this.longitude});

  static const String _darkTemplate =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';
  static const String _lightTemplate =
      'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final center = LatLng(latitude, longitude);
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: c.border),
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: center,
            initialZoom: 15,
            interactionOptions: const InteractionOptions(
              flags: InteractiveFlag.none,
            ),
          ),
          children: [
            TileLayer(
              urlTemplate: isDark ? _darkTemplate : _lightTemplate,
              userAgentPackageName: 'com.beestar.dlliny',
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: center,
                  width: 36,
                  height: 36,
                  child: Icon(
                    TablerIcons.map_pin_filled,
                    color: c.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
