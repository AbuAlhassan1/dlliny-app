import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar_picker_header.dart';
import 'package:hangout/presentation/my_profile/widgets/user_city_district_dropdowns.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venues/controllers/cities_and_districts/cities_and_districts_bloc.dart';

class EditProfilePageWrapper extends StatelessWidget {
  const EditProfilePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: context.read<MyProfileBloc>()),
        BlocProvider(
          create: (_) => CitiesAndDistrictsBloc()..add(GetCities()),
        ),
      ],
      child: const _EditProfileSurface(),
    );
  }
}

class _EditProfileSurface extends StatefulWidget {
  const _EditProfileSurface();

  @override
  State<_EditProfileSurface> createState() => _EditProfileSurfaceState();
}

class _EditProfileSurfaceState extends State<_EditProfileSurface> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _bio = TextEditingController();

  CityWithDistrictsDto? _city;
  DistrictDto? _district;

  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<MyProfileBloc>().user;
    if (user != null) {
      _displayName.text = user.displayName ?? '';
      _bio.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _bio.dispose();
    super.dispose();
  }

  void _seedSelectionsFromUser(List<CityWithDistrictsDto> cities) {
    if (_seeded) return;
    _seeded = true;
    final user = context.read<MyProfileBloc>().user;
    if (user == null) return;
    final cityName = user.city?.trim();
    final districtName = user.district?.trim();
    if (cityName == null || cityName.isEmpty) return;
    final matchedCity = cities.firstWhere(
      (c) => c.nameAr == cityName || c.nameEn == cityName,
      orElse: () => const CityWithDistrictsDto(
        id: -1,
        nameAr: '',
        nameEn: '',
        districts: [],
      ),
    );
    if (matchedCity.id == -1) return;
    _city = matchedCity;
    if (districtName != null && districtName.isNotEmpty) {
      _district = matchedCity.districts.firstWhere(
        (d) => d.nameAr == districtName || d.nameEn == districtName,
        orElse: () => const DistrictDto(
          id: -1,
          nameAr: '',
          nameEn: '',
          cityId: -1,
        ),
      );
      if (_district!.id == -1) _district = null;
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MyProfileBloc>().add(
          UpdateMyProfile(
            displayName: _displayName.text.trim(),
            bio: _bio.text.trim(),
            city: _city?.nameAr ?? '',
            district: _district?.nameAr ?? '',
            cityId: _city?.id,
            districtId: (_district?.id == -1) ? null : _district?.id,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        centerTitle: false,
        title: Text(
          LocaleKeys.profile_edit_page_title.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          _SaveAction(onTap: _submit),
        ],
      ),
      body: MultiBlocListener(
        listeners: [
          BlocListener<MyProfileBloc, ProfileState>(
            listenWhen: (prev, curr) =>
                curr is MyProfileUpdated ||
                curr is MyProfileUpdateError ||
                curr is AvatarUploadUrlError,
            listener: (context, state) {
              if (state is MyProfileUpdated) {
                appToast.success(LocaleKeys.profile_edit_saved_toast.tr());
                Navigator.of(context).maybePop(true);
              } else if (state is MyProfileUpdateError) {
                appToast.error(state.message);
              } else if (state is AvatarUploadUrlError) {
                appToast.error(state.message);
              }
            },
          ),
        ],
        child: BlocBuilder<CitiesAndDistrictsBloc, CitiesAndDistrictsState>(
          builder: (context, locState) {
            final cities = locState is CitiesAndDistrictsLoaded
                ? locState.response
                : const <CityWithDistrictsDto>[];
            if (cities.isNotEmpty) _seedSelectionsFromUser(cities);
            return Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const UserAvatarPickerHeader(),
                  const SizedBox(height: 24),
                  AppLabeledField(
                    label: LocaleKeys.profile_edit_name_label.tr(),
                    child: TextFormField(
                      controller: _displayName,
                      style: TextStyle(color: c.onSurface),
                      decoration: appInputDecoration(c),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? LocaleKeys.common_required_short.tr()
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    label: LocaleKeys.profile_edit_bio_label.tr(),
                    child: TextFormField(
                      controller: _bio,
                      style: TextStyle(color: c.onSurface),
                      maxLines: 3,
                      minLines: 1,
                      decoration: appInputDecoration(
                        c,
                        hint: LocaleKeys.profile_edit_bio_hint.tr(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  UserCityDropdown(
                    cities: cities,
                    loading: locState is CitiesAndDistrictsLoading,
                    value: _city,
                    onChanged: (next) => setState(() {
                      _city = next;
                      _district = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  UserDistrictDropdown(
                    city: _city,
                    value: _district,
                    onChanged: (next) => setState(() => _district = next),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SaveAction extends StatelessWidget {
  final VoidCallback onTap;
  const _SaveAction({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<MyProfileBloc, ProfileState>(
      buildWhen: (prev, curr) =>
          prev is MyProfileUpdating != curr is MyProfileUpdating,
      builder: (context, state) {
        final busy = state is MyProfileUpdating;
        return Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: busy
              ? Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: c.onSurface,
                    ),
                  ),
                )
              : TextButton(
                  onPressed: onTap,
                  child: Text(
                    LocaleKeys.profile_edit_save_action.tr(),
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

