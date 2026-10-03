import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/widgets/hangout_here_button.dart';
import 'package:hangout/presentation/venue/venue_page_wrapper.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_open_status_line.dart';

Future<void> showVenueDetailsSheet({
  required BuildContext context,
  required String venueId,
  String? locationId,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _VenueSheet(venueId: venueId, locationId: locationId),
  );
}

class _VenueSheet extends StatefulWidget {
  final String venueId;
  final String? locationId;
  const _VenueSheet({required this.venueId, this.locationId});

  @override
  State<_VenueSheet> createState() => _VenueSheetState();
}

class _VenueSheetState extends State<_VenueSheet> {
  VenueResponse? _venue;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final response =
          await serviceLocator.get<ApiService>().getVenue(widget.venueId);
      if (!mounted) return;
      if (!response.success || response.data == null) {
        setState(() {
          _loading = false;
          _error = response.error ?? LocaleKeys.map_venue_sheet_load_failed.tr();
        });
        return;
      }
      setState(() {
        _loading = false;
        _venue = response.data;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocaleKeys.map_venue_sheet_load_failed.tr();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocaleKeys.map_venue_sheet_load_failed.tr();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: c.surfaceElevated,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _body(scrollController),
        );
      },
    );
  }

  Widget _body(ScrollController scrollController) {
    if (_loading) {
      return ListView(
        controller: scrollController,
        children: [
          const SizedBox(height: 10),
          Center(child: _Handle()),
          const SizedBox(height: 80),
          Center(
            child: CircularProgressIndicator(
              color: context.c.onSurface,
              strokeWidth: 1.5,
            ),
          ),
        ],
      );
    }
    if (_error != null) {
      return ListView(
        controller: scrollController,
        children: [
          const SizedBox(height: 10),
          Center(child: _Handle()),
          const SizedBox(height: 60),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: context.c.onSurface,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return _Content(
      venue: _venue!,
      scrollController: scrollController,
      locationId: widget.locationId,
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

class _Content extends StatelessWidget {
  final VenueResponse venue;
  final ScrollController scrollController;

  final String? locationId;
  const _Content({
    required this.venue,
    required this.scrollController,
    this.locationId,
  });

  String _address() {
    final district = venue.districtNameAr;
    final city = venue.cityNameAr;
    if (district != null && city != null) return '$district، $city';
    return district ?? city ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isAr = context.locale.languageCode == 'ar';
    final name = isAr ? venue.nameAr : venue.nameEn;
    final address = _address();
    return ListView(
      controller: scrollController,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      children: [
        const SizedBox(height: 10),
        Center(child: _Handle()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: c.surfaceMuted,
                      border: Border.all(color: c.border, width: 1.5),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: venue.logoUrl != null && venue.logoUrl!.isNotEmpty
                        ? ClipRRect(
                          borderRadius: BorderRadius.circular(100),
                          child: CachedNetworkImage(
                              imageUrl: venue.logoUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (_, _, _) => Icon(
                                TablerIcons.map_pin,
                                color: c.onSurface,
                                size: 22,
                              ),
                            ),
                        )
                        : Icon(
                            TablerIcons.map_pin,
                            color: c.onSurface,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                name,
                                style: TextStyle(
                                  color: c.onSurface,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (venue.verified)
                              const Padding(
                                padding: EdgeInsets.only(left: 6),
                                child: Icon(
                                  TablerIcons.rosette_discount_check_filled,
                                  color: Colors.blue,
                                  size: 18,
                                ),
                              ),
                          ],
                        ),
                        if (address.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              address,
                              style: TextStyle(
                                color: c.onSurfaceSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Icon(
                    TablerIcons.star_filled,
                    color: Colors.amber,
                    size: 18,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    venue.avgRating.toStringAsFixed(1),
                    style: TextStyle(
                      color: c.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '(${venue.totalRatings})',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (venue.category != null)
                    _Chip(
                      icon: TablerIcons.category,
                      label: isAr
                          ? venue.category!.nameAr
                          : venue.category!.nameEn,
                    ),
                ],
              ),
              VenueScopeStatusLine(
                openingHours: venue.openingHours,
                locationId: locationId,
                padding: const EdgeInsetsDirectional.only(top: 12),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => VenuePageWrapper(venueId: venue.id),
                          ),
                        );
                      },
                      label: Text(
                        LocaleKeys.map_venue_sheet_view_venue.tr(),
                        style: const TextStyle(fontFamily: "IBMPlexSansArabic"),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: c.primary,
                        foregroundColor: c.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 15),
                  Expanded(
                    child: HangoutHereButton(
                      venueId: venue.id,
                      venueName: name,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.border, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c.onSurfaceSecondary, size: 14),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: c.onSurface, fontSize: 12)),
        ],
      ),
    );
  }
}
