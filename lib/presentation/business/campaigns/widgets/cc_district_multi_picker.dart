import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class CcDistrictMultiPicker extends StatefulWidget {
  final Set<String> initial;
  const CcDistrictMultiPicker({super.key, required this.initial});

  static Future<Set<String>?> show(
    BuildContext context, {
    required Set<String> initial,
  }) {
    return showModalBottomSheet<Set<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CcDistrictMultiPicker(initial: initial),
    );
  }

  @override
  State<CcDistrictMultiPicker> createState() => _CcDistrictMultiPickerState();
}

class _CcDistrictMultiPickerState extends State<CcDistrictMultiPicker> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<CityWithDistrictsDto>? _cities;
  String _query = '';
  late Set<String> _selected;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selected = {...widget.initial};
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.getCitiesWithDistricts();
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _cities = res.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.error ??
              LocaleKeys.business_campaigns_districts_picker_fetch_failed.tr();
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? LocaleKeys.common_connection_failed.tr();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(22),
            ),
          ),
          child: Column(
            children: [
              _Grabber(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Row(
                  children: [
                    Text(
                      LocaleKeys.business_campaigns_districts_picker_title.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${_selected.length}',
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v.trim()),
                  decoration: InputDecoration(
                    hintText: LocaleKeys.business_campaigns_districts_picker_search_hint.tr(),
                    prefixIcon: Icon(
                      TablerIcons.search,
                      color: c.onSurfaceMuted,
                    ),
                    filled: true,
                    fillColor: c.surfaceMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(child: _buildBody(scrollController)),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(_selected),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.onSurface,
                        foregroundColor: c.background,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _selected.isEmpty
                            ? LocaleKeys.business_campaigns_districts_picker_no_targeting.tr()
                            : LocaleKeys.business_campaigns_districts_picker_selected_count.tr(
                                namedArgs: {'n': '${_selected.length}'},
                              ),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(ScrollController scrollController) {
    final c = context.c;
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      );
    }
    final cities = _cities!;
    final q = _query.toLowerCase();
    final filtered = cities
        .map((city) {
          final cityHit = city.nameAr.toLowerCase().contains(q) ||
              city.nameEn.toLowerCase().contains(q);
          final dists = cityHit
              ? city.districts
              : city.districts
                  .where((d) =>
                      d.nameAr.toLowerCase().contains(q) ||
                      d.nameEn.toLowerCase().contains(q))
                  .toList();
          return MapEntry(city, dists);
        })
        .where((e) => e.value.isNotEmpty)
        .toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          LocaleKeys.common_no_results.tr(),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      );
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      itemCount: filtered.length,
      itemBuilder: (_, i) {
        final entry = filtered[i];
        final city = entry.key;
        final dists = entry.value;
        final cityAllNames = city.districts.map((d) => d.nameEn).toSet();
        final allSelected =
            cityAllNames.isNotEmpty && cityAllNames.every(_selected.contains);
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      city.nameAr,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() {
                        if (allSelected) {
                          _selected.removeAll(cityAllNames);
                        } else {
                          _selected.addAll(cityAllNames);
                        }
                      });
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: c.onSurfaceSecondary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      (allSelected
                              ? LocaleKeys.common_deselect_all
                              : LocaleKeys.common_select_all)
                          .tr(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                ],
              ),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final d in dists)
                    _DistrictChip(
                      label: d.nameAr,
                      selected: _selected.contains(d.nameEn),
                      onTap: () {
                        setState(() {
                          if (_selected.contains(d.nameEn)) {
                            _selected.remove(d.nameEn);
                          } else {
                            _selected.add(d.nameEn);
                          }
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Divider(color: c.divider, height: 1),
            ],
          ),
        );
      },
    );
  }
}

class _Grabber extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 6),
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: c.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

class _DistrictChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _DistrictChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.15) : c.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 4),
                child: Icon(TablerIcons.check, size: 12, color: c.primary),
              ),
            Text(
              label,
              style: TextStyle(
                color: selected ? c.primary : c.onSurface,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
