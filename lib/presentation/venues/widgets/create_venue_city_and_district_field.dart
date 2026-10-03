import 'dart:developer';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venues/controllers/cities_and_districts/cities_and_districts_bloc.dart';

class CreateVenueCityAndDistrictField extends StatefulWidget {
  final TextEditingController cityController;
  final TextEditingController districtController;
  const CreateVenueCityAndDistrictField({
    super.key,
    required this.cityController,
    required this.districtController,
  });

  @override
  State<CreateVenueCityAndDistrictField> createState() =>
      _CreateVenueCityAndDistrictFieldState();
}

class _CreateVenueCityAndDistrictFieldState
    extends State<CreateVenueCityAndDistrictField> {
  CityWithDistrictsDto? selectedCity;
  DistrictDto? selectedDistrict;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CitiesAndDistrictsBloc()..add(GetCities()),
      child: BlocConsumer<CitiesAndDistrictsBloc, CitiesAndDistrictsState>(
        listenWhen: (prev, curr) =>
            curr is CitiesAndDistrictsLoaded &&
            prev is! CitiesAndDistrictsLoaded,
        listener: (context, state) {
          if (selectedCity != null) return;
          final cityId = int.tryParse(widget.cityController.text);
          if (cityId == null) return;
          final loaded = (state as CitiesAndDistrictsLoaded).response;
          CityWithDistrictsDto? city;
          for (final candidate in loaded) {
            if (candidate.id == cityId) {
              city = candidate;
              break;
            }
          }
          if (city == null) return;
          DistrictDto? district;
          final districtId = int.tryParse(widget.districtController.text);
          if (districtId != null) {
            for (final candidate in city.districts) {
              if (candidate.id == districtId) {
                district = candidate;
                break;
              }
            }
          }
          setState(() {
            selectedCity = city;
            selectedDistrict = district;
          });
        },
        builder: (context, state) {
          final loading =
              state is CitiesAndDistrictsLoading ||
              state is CitiesAndDistrictsInitial;
          final cities = state is CitiesAndDistrictsLoaded
              ? state.response
              : const <CityWithDistrictsDto>[];
          return Column(
            children: [
              _CityDropdown(
                cities: cities,
                loading: loading,
                value: selectedCity,
                onChanged: (value) {
                  log('Selected city: $value');
                  if (value == null) return;
                  widget.cityController.text = value.id.toString();
                  setState(() {
                    selectedCity = value;
                    widget.districtController.text = '';
                    selectedDistrict = null;
                  });
                },
              ),
              const SizedBox(height: 20),
              _DistrictDropdown(
                city: selectedCity,
                value: selectedDistrict,
                onChanged: (value) {
                  log('Selected district: $value');
                  if (value == null) return;
                  widget.districtController.text = value.id.toString();
                  setState(() => selectedDistrict = value);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _CityDropdown extends StatelessWidget {
  final List<CityWithDistrictsDto> cities;
  final bool loading;
  final CityWithDistrictsDto? value;
  final ValueChanged<CityWithDistrictsDto?> onChanged;
  const _CityDropdown({
    required this.cities,
    required this.loading,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppLabeledField(
      label: LocaleKeys.create_venue_label_city.tr(),
      requiredMark: true,
      child: AppDropdownShell(
        loading: loading && cities.isEmpty,
        child: DropdownButtonFormField<CityWithDistrictsDto>(
          key: ValueKey('city-${value?.id ?? 'none'}'),
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(color: c.onSurface, fontFamily: 'IBMPlexSansArabic'),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(c, hint: LocaleKeys.create_venue_hint_select_city.tr()),
          items: [
            for (final city in cities)
              DropdownMenuItem<CityWithDistrictsDto>(
                value: city,
                child: Text(city.nameAr),
              ),
          ],
          onChanged: cities.isEmpty ? null : onChanged,
        ),
      ),
    );
  }
}

class _DistrictDropdown extends StatelessWidget {
  final CityWithDistrictsDto? city;
  final DistrictDto? value;
  final ValueChanged<DistrictDto?> onChanged;
  const _DistrictDropdown({
    required this.city,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final districts = city?.districts ?? const <DistrictDto>[];
    final enabled = city != null && districts.isNotEmpty;
    return AppLabeledField(
      label: LocaleKeys.create_venue_label_district.tr(),
      requiredMark: true,
      child: AppDropdownShell(
        loading: false,
        child: DropdownButtonFormField<DistrictDto>(
          key: ValueKey(
            'district-${city?.id ?? 'none'}-${value?.id ?? 'none'}',
          ),
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(color: c.onSurface, fontFamily: 'IBMPlexSansArabic'),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(
            c,
            hint: city == null
                ? LocaleKeys.create_venue_hint_select_city_first.tr()
                : LocaleKeys.create_venue_hint_select_district.tr(),
          ),
          items: [
            for (final d in districts)
              DropdownMenuItem<DistrictDto>(value: d, child: Text(d.nameAr)),
          ],
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}
