import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class CcCategoryMultiPicker extends StatefulWidget {
  final Set<int> initial;
  const CcCategoryMultiPicker({super.key, required this.initial});

  static Future<Set<int>?> show(
    BuildContext context, {
    required Set<int> initial,
  }) {
    return showModalBottomSheet<Set<int>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CcCategoryMultiPicker(initial: initial),
    );
  }

  @override
  State<CcCategoryMultiPicker> createState() => _CcCategoryMultiPickerState();
}

class _CcCategoryMultiPickerState extends State<CcCategoryMultiPicker> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<VenueCategoryDto>? _categories;
  late Set<int> _selected;
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
      final res = await _api.getVenueCategories();
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _categories = res.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.error ??
              LocaleKeys.business_campaigns_categories_picker_fetch_failed.tr();
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
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
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
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      LocaleKeys.business_campaigns_categories_picker_title.tr(),
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
                            ? LocaleKeys.business_campaigns_categories_picker_no_targeting.tr()
                            : LocaleKeys.business_campaigns_categories_picker_selected_count.tr(
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
    final cats = _categories!;
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: cats.length,
      separatorBuilder: (_, _) => Divider(color: c.divider, height: 1),
      itemBuilder: (_, i) {
        final cat = cats[i];
        final selected = _selected.contains(cat.id);
        return InkWell(
          onTap: () {
            setState(() {
              if (selected) {
                _selected.remove(cat.id);
              } else {
                _selected.add(cat.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    cat.icon == null || cat.icon!.isEmpty ? '·' : cat.icon!,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 16,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    cat.nameAr,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.bold : FontWeight.normal,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
                Icon(
                  selected ? TablerIcons.check : null,
                  color: c.primary,
                  size: 20,
                ),
              ],
            ),
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
