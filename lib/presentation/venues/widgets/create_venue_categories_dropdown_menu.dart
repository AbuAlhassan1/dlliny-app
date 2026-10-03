import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venues/controllers/venues_categories/venues_categories_bloc.dart';

class VenueCategoriesDropDownMenu extends StatefulWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isRequired;
  const VenueCategoriesDropDownMenu({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.isRequired = false,
  });

  @override
  State<VenueCategoriesDropDownMenu> createState() =>
      _VenueCategoriesDropDownMenuState();
}

class _VenueCategoriesDropDownMenuState
    extends State<VenueCategoriesDropDownMenu> {
  @override
  void initState() {
    context.read<VenuesCategoriesBloc>().add(GetVenuesCategories());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<VenuesCategoriesBloc, VenuesCategoriesState>(
      builder: (context, state) {
        final loading = state is VenuesCategoriesLoading ||
            state is VenuesCategoriesInitial;
        final seededId = int.tryParse(widget.controller.text);
        final field = DropdownButtonFormField<int>(
          key: ValueKey('category-${seededId ?? 'none'}'),
          initialValue: seededId,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(
            color: c.onSurface,
            fontFamily: "IBMPlexSansArabic",
          ),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(
            c,
            hint: widget.hint ?? LocaleKeys.create_venue_hint_select_category.tr(),
          ),
          items: state is VenuesCategoriesLoaded
              ? state.response
                  .map(
                    (category) => DropdownMenuItem<int>(
                      value: category.id,
                      child: Text(category.nameAr),
                    ),
                  )
                  .toList()
              : const [],
          onChanged: (value) {
            log('Selected value: $value');
            if (value != null) widget.controller.text = value.toString();
          },
        );
        final shelled = AppDropdownShell(loading: loading, child: field);
        if (widget.label == null) return shelled;
        return AppLabeledField(
          label: widget.label!,
          requiredMark: widget.isRequired,
          child: shelled,
        );
      },
    );
  }
}
