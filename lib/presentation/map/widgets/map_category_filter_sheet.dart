import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/map/controller/map_bloc.dart';

class MapCategoryFilterSheet extends StatelessWidget {
  const MapCategoryFilterSheet({super.key});

  static Future<void> show(BuildContext context) {
    final bloc = context.read<MapBloc>();
    bloc.add(LoadMapCategories());
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: bloc,
        child: const MapCategoryFilterSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Grabber(),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                child: Row(
                  children: [
                    Text(
                      LocaleKeys.map_category_filter_title.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: "IBMPlexSansArabic",
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BlocBuilder<MapBloc, MapState>(
                  buildWhen: (_, s) =>
                      s is MapCategoriesLoading ||
                      s is MapCategoriesLoaded ||
                      s is MapCategoryFilterChanged,
                  builder: (context, state) {
                    final bloc = context.read<MapBloc>();
                    if (state is MapCategoriesLoading &&
                        bloc.categories.isEmpty) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: c.onSurface,
                          strokeWidth: 1.5,
                        ),
                      );
                    }
                    return _CategoryList(
                      scrollController: scrollController,
                      categories: bloc.categories,
                      selectedId: bloc.selectedCategoryId,
                    );
                  },
                ),
              ),
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
        margin: const EdgeInsets.only(top: 10, bottom: 8),
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

class _CategoryList extends StatelessWidget {
  final ScrollController scrollController;
  final List<VenueCategoryDto> categories;
  final int? selectedId;

  const _CategoryList({
    required this.scrollController,
    required this.categories,
    required this.selectedId,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: categories.length + 1,
      separatorBuilder: (_, _) => Divider(height: 1, color: c.divider),
      itemBuilder: (context, index) {
        if (index == 0) {
          return _CategoryRow(
            label: LocaleKeys.map_category_filter_all.tr(),
            iconChar: null,
            selected: selectedId == null,
            onTap: () {
              context.read<MapBloc>().add(SetMapCategoryFilter(null));
              Navigator.of(context).pop();
            },
          );
        }
        final cat = categories[index - 1];
        return _CategoryRow(
          label: context.pickBilingual(ar: cat.nameAr, en: cat.nameEn),
          iconChar: cat.icon,
          selected: selectedId == cat.id,
          onTap: () {
            context.read<MapBloc>().add(SetMapCategoryFilter(cat.id));
            Navigator.of(context).pop();
          },
        );
      },
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final String label;
  final String? iconChar;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRow({
    required this.label,
    required this.iconChar,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                iconChar == null || iconChar!.isEmpty ? '·' : iconChar!,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 16,
                  fontFamily: "IBMPlexSansArabic",
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 15,
                  fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  fontFamily: "IBMPlexSansArabic",
                ),
              ),
            ),
            if (selected)
              Icon(TablerIcons.check, color: c.primary, size: 20),
          ],
        ),
      ),
    );
  }
}
