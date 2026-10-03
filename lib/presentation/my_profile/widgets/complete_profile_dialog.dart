import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar_picker_header.dart';
import 'package:hangout/presentation/my_profile/widgets/user_city_district_dropdowns.dart';
import 'package:hangout/presentation/my_profile/widgets/username_field.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venues/controllers/cities_and_districts/cities_and_districts_bloc.dart';

class CompleteProfileDialog extends StatelessWidget {
  const CompleteProfileDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => CitiesAndDistrictsBloc()..add(GetCities()),
      child: const _CompleteProfileSurface(),
    );
  }
}

class _CompleteProfileSurface extends StatefulWidget {
  const _CompleteProfileSurface();

  @override
  State<_CompleteProfileSurface> createState() =>
      _CompleteProfileSurfaceState();
}

class _CompleteProfileSurfaceState extends State<_CompleteProfileSurface> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _username = TextEditingController();
  final _bio = TextEditingController();
  late String _originalUsername = '';
  CityWithDistrictsDto? _city;
  DistrictDto? _district;
  String? _gender;
  bool _seeded = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<MyProfileBloc>().user;
    if (user != null) {
      _displayName.text = user.displayName ?? '';
      _username.text = user.username ?? '';
      _originalUsername = user.username ?? '';
      _bio.text = user.bio ?? '';
      _gender = (user.gender ?? '').isEmpty ? null : user.gender;
    }
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
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
    final formOk = _formKey.currentState?.validate() ?? false;
    if (!formOk) {
      appToast.error(LocaleKeys.profile_complete_incomplete_toast.tr());
      return;
    }
    if (_city == null || _district == null) {
      appToast.error(
        LocaleKeys.profile_complete_missing_city_district_toast.tr(),
      );
      return;
    }
    if (_gender == null || _gender!.isEmpty) {
      appToast.error(LocaleKeys.profile_complete_missing_gender_toast.tr());
      return;
    }

    final typed = _username.text.trim();
    final username = typed == _originalUsername.trim() ? null : typed;
    context.read<MyProfileBloc>().add(
          CompleteMyProfile(
            displayName: _displayName.text.trim(),
            username: username,
            bio: _bio.text.trim(),
            city: _city?.nameAr ?? '',
            district: _district?.nameAr ?? '',
            gender: _gender ?? '',
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
        automaticallyImplyLeading: false,
        title: Text(
          LocaleKeys.profile_complete_page_title.tr(),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [_SaveAction(onTap: _submit)],
      ),
      body: BlocListener<MyProfileBloc, ProfileState>(
        listenWhen: (prev, curr) =>
            curr is MyProfileUpdated || curr is MyProfileUpdateError,
        listener: (context, state) {
          if (state is MyProfileUpdated) {
            Navigator.of(context).maybePop(true);
            return;
          }
          if (state is MyProfileUpdateError) {
            appToast.error(state.message);
          }
        },
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
                  const UserAvatarPickerHeader(size: 96),
                  const SizedBox(height: 16),
                  _Intro(),
                  const SizedBox(height: 20),
                  AppLabeledField(
                    label: LocaleKeys.profile_complete_name_label.tr(),
                    requiredMark: true,
                    child: TextFormField(
                      controller: _displayName,
                      style: TextStyle(color: c.onSurface),
                      textInputAction: TextInputAction.next,
                      maxLength: 50,
                      decoration: appInputDecoration(c).copyWith(
                        counterText: '',
                      ),
                      validator: (v) {
                        final t = v?.trim() ?? '';
                        if (t.isEmpty) {
                          return LocaleKeys.profile_complete_name_required.tr();
                        }
                        if (t.length < 2) {
                          return LocaleKeys.profile_complete_name_too_short.tr();
                        }
                        if (t.length > 50) {
                          return LocaleKeys.profile_complete_name_too_long.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    label: LocaleKeys.profile_complete_username_label.tr(),
                    requiredMark: true,
                    child: UsernameField(
                      usernameController: _username,
                      seededUsername: _originalUsername,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppLabeledField(
                    label: LocaleKeys.profile_complete_bio_label.tr(),
                    child: TextFormField(
                      controller: _bio,
                      style: TextStyle(color: c.onSurface),
                      maxLines: 3,
                      minLines: 1,
                      maxLength: 200,
                      decoration: appInputDecoration(
                        c,
                        hint: LocaleKeys.profile_complete_bio_hint.tr(),
                      ),
                      validator: (v) {
                        if (v == null) return null;
                        if (v.length > 200) {
                          return LocaleKeys.profile_complete_bio_too_long.tr();
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GenderDropdown(
                    value: _gender,
                    onChanged: (next) => setState(() => _gender = next),
                  ),
                  const SizedBox(height: 12),
                  UserCityDropdown(
                    cities: cities,
                    loading: locState is CitiesAndDistrictsLoading,
                    value: _city,
                    requiredMark: true,
                    onChanged: (next) => setState(() {
                      _city = next;
                      _district = null;
                    }),
                  ),
                  const SizedBox(height: 12),
                  UserDistrictDropdown(
                    city: _city,
                    value: _district,
                    requiredMark: true,
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

class _Intro extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(TablerIcons.user_circle, color: c.onSurface, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              LocaleKeys.profile_complete_intro.tr(),
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _GenderDropdown extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  const _GenderDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return AppLabeledField(
      label: LocaleKeys.profile_complete_gender_label.tr(),
      requiredMark: true,
      child: AppDropdownShell(
        loading: false,
        child: DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          dropdownColor: c.surfaceMuted,
          style: TextStyle(color: c.onSurface),
          icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
          decoration: appInputDecoration(c),
          hint: Text(
            LocaleKeys.profile_complete_gender_hint.tr(),
            style: TextStyle(color: c.onSurfaceMuted),
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'MALE',
              child: Text(LocaleKeys.profile_complete_gender_male.tr()),
            ),
            DropdownMenuItem<String>(
              value: 'FEMALE',
              child: Text(LocaleKeys.profile_complete_gender_female.tr()),
            ),
          ],
          onChanged: onChanged,
          validator: (v) =>
              v == null ? LocaleKeys.common_required_short.tr() : null,
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
                    LocaleKeys.profile_complete_save_action.tr(),
                    style: TextStyle(
                      color: c.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
        );
      },
    );
  }
}

Future<bool?> showCompleteProfileDialog(BuildContext context) async {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    useSafeArea: false,
    builder: (_) => const Dialog.fullscreen(
      child: CompleteProfileDialog(),
    ),
  );
}
