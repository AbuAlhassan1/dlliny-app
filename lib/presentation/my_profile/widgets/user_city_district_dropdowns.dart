import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class UserCityDropdown extends StatelessWidget {
  final List<CityWithDistrictsDto> cities;
  final bool loading;
  final CityWithDistrictsDto? value;
  final ValueChanged<CityWithDistrictsDto?> onChanged;

  final String? label;

  final bool requiredMark;

  const UserCityDropdown({
    super.key,
    required this.cities,
    required this.loading,
    required this.value,
    required this.onChanged,
    this.label,
    this.requiredMark = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppLabeledField(
      label: label ?? LocaleKeys.profile_city_label.tr(),
      requiredMark: requiredMark,
      child: AppDropdownShell(
        loading: loading && cities.isEmpty,
        child: DropdownButtonFormField<CityWithDistrictsDto>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(color: c.onSurface),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(c),
          hint: Text(
            LocaleKeys.profile_city_hint.tr(),
            style: TextStyle(color: c.onSurfaceMuted),
          ),
          items: [
            for (final city in cities)
              DropdownMenuItem<CityWithDistrictsDto>(
                value: city,
                child: Text(
                  context.pickBilingual(ar: city.nameAr, en: city.nameEn),
                ),
              ),
          ],
          onChanged: cities.isEmpty ? null : onChanged,
          validator: requiredMark
              ? (v) => v == null ? LocaleKeys.common_required_short.tr() : null
              : null,
        ),
      ),
    );
  }
}

class UserDistrictDropdown extends StatelessWidget {
  final CityWithDistrictsDto? city;
  final DistrictDto? value;
  final ValueChanged<DistrictDto?> onChanged;

  final String? label;

  final bool requiredMark;

  const UserDistrictDropdown({
    super.key,
    required this.city,
    required this.value,
    required this.onChanged,
    this.label,
    this.requiredMark = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final districts = city?.districts ?? const <DistrictDto>[];
    final enabled = city != null && districts.isNotEmpty;
    return AppLabeledField(
      label: label ?? LocaleKeys.profile_district_label.tr(),
      requiredMark: requiredMark,
      child: AppDropdownShell(
        loading: false,
        child: DropdownButtonFormField<DistrictDto>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(color: c.onSurface),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(c),
          hint: Text(
            city == null
                ? LocaleKeys.profile_district_pick_city_first.tr()
                : LocaleKeys.profile_district_hint.tr(),
            style: TextStyle(color: c.onSurfaceMuted),
          ),
          items: [
            for (final d in districts)
              DropdownMenuItem<DistrictDto>(
                value: d,
                child: Text(
                  context.pickBilingual(ar: d.nameAr, en: d.nameEn),
                ),
              ),
          ],
          onChanged: enabled ? onChanged : null,
          validator: requiredMark
              ? (v) => v == null ? LocaleKeys.common_required_short.tr() : null
              : null,
        ),
      ),
    );
  }
}
