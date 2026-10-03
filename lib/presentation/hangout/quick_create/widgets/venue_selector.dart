import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_chip.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/venue_picker_sheet.dart';
import 'package:hangout/presentation/home/controllers/nearby_venues/nearby_venues_bloc.dart';

class VenueSelector extends StatefulWidget {
  final String? selectedId;
  final String? selectedName;
  final bool loading;
  final void Function(String id, String name) onSelect;
  final VoidCallback onSearch;

  const VenueSelector({
    super.key,
    required this.selectedId,
    required this.selectedName,
    required this.loading,
    required this.onSelect,
    required this.onSearch,
  });

  @override
  State<VenueSelector> createState() => _VenueSelectorState();
}

class _VenueSelectorState extends State<VenueSelector> {
  static const int _collapsedCount = 6;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NearbyVenuesBloc, NearbyVenuesState>(
      builder: (context, state) {
        final items = state is NearbyVenuesLoaded
            ? state.items
            : const <VenueSummaryResponse>[];
        final selectedId = widget.selectedId;
        final selectedInList = items.any((v) => v.id == selectedId);
        final hasMore = items.length > _collapsedCount;
        final visible = _expanded
            ? items
            : items.take(_collapsedCount).toList();

        final chips = <Widget>[
          if (selectedId != null &&
              !selectedInList &&
              widget.selectedName != null)
            QuickChip(
              icon: TablerIcons.map_pin,
              label: widget.selectedName!,
              active: true,
              loading: widget.loading,
              onTap: widget.onSearch,
            ),
          for (final v in visible)
            QuickChip(
              icon: TablerIcons.map_pin,
              leading: VenueLogoAvatar(url: v.logoUrl, size: 20),
              label: v.nameAr,
              active: v.id == selectedId,
              loading: widget.loading && v.id == selectedId,
              onTap: () => widget.onSelect(v.id, v.nameAr),
            ),
          if (hasMore)
            QuickChip(
              icon: _expanded
                  ? TablerIcons.chevron_up
                  : TablerIcons.chevron_down,
              label: _expanded
                  ? context.pickBilingual(ar: 'أقل', en: 'Less')
                  : context.pickBilingual(
                      ar: 'المزيد',
                      en: '+${items.length - _collapsedCount}',
                    ),
              onTap: () => setState(() => _expanded = !_expanded),
            ),
        ];

        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                QuickChip(
                  icon: TablerIcons.search,
                  label: context.pickBilingual(ar: 'ابحث عن مكان', en: 'search for a place.'),
                  onTap: widget.onSearch,
                ),
              ],
            ),

          ],
        );
      },
    );
  }
}
