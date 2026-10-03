import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';
import 'package:hangout/presentation/map/controller/venue_branch_hit.dart';
import 'package:hangout/presentation/map/widgets/map_category_filter_sheet.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:latlong2/latlong.dart';

class VenueSearchBar extends StatefulWidget {
  const VenueSearchBar({super.key});

  @override
  State<VenueSearchBar> createState() => _VenueSearchBarState();
}

class _VenueSearchBarState extends State<VenueSearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    final query = value.trim();
    if (query.length < 2) {
      context.read<MapBloc>().add(ClearVenueSearch());
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      context.read<MapBloc>().add(SearchVenues(query));
    });
  }

  void _onResultTap(VenueBranchHit hit) {
    final bloc = context.read<MapBloc>();
    _controller.clear();
    _focusNode.unfocus();
    bloc.add(ClearVenueSearch());
    bloc.animatedMapController?.animateTo(
      dest: LatLng(hit.latitude, hit.longitude),
      zoom: 18,
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _SearchField(
                controller: _controller,
                focusNode: _focusNode,
                onChanged: _onChanged,
                onClear: () {
                  _controller.clear();
                  context.read<MapBloc>().add(ClearVenueSearch());
                },
              ),
            ),
            const SizedBox(width: 8),
            _FilterButton(
              onTap: () => MapCategoryFilterSheet.show(context),
            ),
          ],
        ),
        BlocBuilder<MapBloc, MapState>(
          buildWhen: (_, s) =>
              s is VenueSearchLoading ||
              s is VenueSearchLoaded ||
              s is VenueSearchError ||
              s is VenueSearchCleared,
          builder: (context, state) {
            if (state is VenueSearchCleared || state is MapInitial) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _ResultsCard(state: state),
            );
          },
        ),
      ],
    );
  }
}

class _FilterButton extends StatelessWidget {
  final VoidCallback onTap;
  const _FilterButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MapBloc, MapState>(
      buildWhen: (_, s) => s is MapCategoryFilterChanged,
      builder: (context, _) {
        final active = context.read<MapBloc>().selectedCategoryId != null;
        return Material(
          color: c.surfaceElevated,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: c.border),
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    TablerIcons.adjustments_horizontal,
                    color: c.onSurface,
                    size: 22,
                  ),
                  if (active)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      style: TextStyle(color: c.onSurface),
      cursorColor: c.onSurface,
      decoration: appInputDecoration(
        c,
        hint: LocaleKeys.map_search_hint.tr(),
        prefixIcon: Icon(TablerIcons.search, color: c.onSurface),
        suffixIcon: ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) {
            if (value.text.isEmpty) return const SizedBox.shrink();
            return IconButton(
              icon: Icon(TablerIcons.x, color: c.onSurfaceMuted),
              onPressed: onClear,
            );
          },
        ),
      ),
    );
  }
}

class _ResultsCard extends StatelessWidget {
  final MapState state;
  const _ResultsCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      constraints: const BoxConstraints(maxHeight: 320),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final c = context.c;
    if (state is VenueSearchLoading) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: c.onSurface,
              strokeWidth: 1.5,
            ),
          ),
        ),
      );
    }
    if (state is VenueSearchError) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          (state as VenueSearchError).message,
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
      );
    }

    final bloc = context.read<MapBloc>();
    final results = bloc.searchResults;
    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          LocaleKeys.common_no_results.tr(),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      padding: EdgeInsets.zero,
      itemCount: results.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        color: c.divider,
      ),
      itemBuilder: (context, i) {
        return _ResultTile(
          hit: results[i],
          onTap: () =>
              (context.findAncestorStateOfType<_VenueSearchBarState>())
                  ?._onResultTap(results[i]),
        );
      },
    );
  }
}

class _ResultTile extends StatelessWidget {
  final VenueBranchHit hit;
  final VoidCallback onTap;

  const _ResultTile({required this.hit, required this.onTap});

  String _address() {
    final district = hit.districtNameAr;
    final city = hit.cityNameAr;
    if (district != null && city != null) return '$district، $city';
    return district ?? city ?? '';
  }

  String _title(bool isAr) {
    final venueName = isAr ? hit.venueNameAr : hit.venueNameEn;
    final label = isAr ? hit.labelAr : hit.labelEn;
    if (label != null && label.trim().isNotEmpty) {
      return '$venueName · $label';
    }
    return venueName;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isAr = context.locale.languageCode == 'ar';
    final title = _title(isAr);
    final address = _address();
    final logoUrl = hit.venueLogoUrl;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.surfaceMuted,
              ),
              clipBehavior: Clip.antiAlias,
              child: logoUrl != null && logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Icon(
                        TablerIcons.map_pin,
                        color: c.onSurface,
                        size: 18,
                      ),
                    )
                  : Icon(
                      TablerIcons.map_pin,
                      color: c.onSurface,
                      size: 18,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (hit.isPrimary) ...[
                        const SizedBox(width: 6),
                        Icon(
                          TablerIcons.star_filled,
                          color: c.primary,
                          size: 12,
                        ),
                      ],
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address,
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
          ],
        ),
      ),
    );
  }
}
