import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/update_business_venue_request.dart';
import 'package:hangout/domain/dto/response/venue_conversion_impact_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/edit_venue_controller/edit_venue_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venues/controllers/venues_categories/venues_categories_bloc.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_categories_dropdown_menu.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_city_and_district_field.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_location_field.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_textfield.dart';

class EditVenuePageWrapper extends StatefulWidget {
  final VenueResponse venue;
  const EditVenuePageWrapper({super.key, required this.venue});

  static Future<void> push(BuildContext context, VenueResponse venue) {
    final venueBloc = context.read<VenueBloc>();
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: venueBloc),
            BlocProvider(create: (_) => EditVenueBloc()),
            BlocProvider(
              create: (_) => VenuesCategoriesBloc()..add(GetVenuesCategories()),
            ),
          ],
          child: EditVenuePageWrapper(venue: venue),
        ),
      ),
    );
  }

  @override
  State<EditVenuePageWrapper> createState() => _EditVenuePageWrapperState();
}

class _EditVenuePageWrapperState extends State<EditVenuePageWrapper> {
  late final TextEditingController nameArController;
  late final TextEditingController nameEnController;
  late final TextEditingController descriptionArController;
  late final TextEditingController descriptionEnController;
  late final TextEditingController categoryIdController;
  late final TextEditingController latitudeController;
  late final TextEditingController longitudeController;
  late final TextEditingController addressArController;
  late final TextEditingController addressEnController;
  late final TextEditingController cityIdController;
  late final TextEditingController districtIdController;
  late final TextEditingController phoneController;
  late final TextEditingController websiteController;

  late bool _onlineOnly;

  bool _impactInFlight = false;

  final ApiService _api = serviceLocator.get<ApiService>();

  @override
  void initState() {
    super.initState();
    final v = widget.venue;
    _onlineOnly = v.onlineOnly;
    nameArController = TextEditingController(text: v.nameAr);
    nameEnController = TextEditingController(text: v.rawNameEn ?? '');
    descriptionArController = TextEditingController(text: v.descriptionAr ?? '');
    descriptionEnController = TextEditingController(text: v.descriptionEn ?? '');
    categoryIdController =
        TextEditingController(text: v.category?.id.toString() ?? '');
    latitudeController =
        TextEditingController(text: v.latitude?.toString() ?? '');
    longitudeController =
        TextEditingController(text: v.longitude?.toString() ?? '');
    addressArController = TextEditingController(text: v.addressAr ?? '');
    addressEnController = TextEditingController(text: v.addressEn ?? '');
    cityIdController = TextEditingController(text: v.cityId?.toString() ?? '');
    districtIdController =
        TextEditingController(text: v.districtId?.toString() ?? '');
    phoneController = TextEditingController(text: v.phone ?? '');
    websiteController = TextEditingController(text: v.website ?? '');
  }

  @override
  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    descriptionArController.dispose();
    descriptionEnController.dispose();
    categoryIdController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    addressArController.dispose();
    addressEnController.dispose();
    cityIdController.dispose();
    districtIdController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    super.dispose();
  }

  int? _parseInt(String s) => s.isEmpty ? null : int.tryParse(s);
  double? _parseDouble(String s) => s.isEmpty ? null : double.tryParse(s);

  Future<void> _submit() async {
    final wasOnline = widget.venue.onlineOnly;
    final nowOnline = _onlineOnly;
    final converting = wasOnline != nowOnline;

    if (!nowOnline) {
      final lat = _parseDouble(latitudeController.text);
      final lng = _parseDouble(longitudeController.text);
      if (lat == null || lng == null) {
        appToast.error(LocaleKeys.manage_venue_info_error_location_required.tr());
        return;
      }
    }

    bool force = false;
    if (converting && nowOnline) {
      final outcome = await _resolveImpactAndConfirm();
      if (!outcome.proceed) return;
      force = outcome.needsForce;
    }

    _dispatchUpdate(
      onlineOnlyField: converting ? nowOnline : null,
      force: force,
    );
  }

  Future<({bool proceed, bool needsForce})>
      _resolveImpactAndConfirm() async {
    setState(() => _impactInFlight = true);
    VenueConversionImpactResponse? impact;
    try {
      final res = await _api.getBusinessVenueConversionImpact(widget.venue.id);
      if (res.success && res.data != null) impact = res.data;
    } on DioException catch (_) {
    } finally {
      if (mounted) setState(() => _impactInFlight = false);
    }

    if (!mounted) return (proceed: false, needsForce: false);

    if (impact != null && impact.safeToConvertOffline) {
      return (proceed: true, needsForce: false);
    }

    final confirmed = await _showImpactDialog(impact);
    return (proceed: confirmed == true, needsForce: true);
  }

  Future<bool?> _showImpactDialog(VenueConversionImpactResponse? impact) {
    final c = context.c;
    final warnings = impact?.warningsAr ?? const <String>[];
    return showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: c.background,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(TablerIcons.alert_triangle, color: c.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                LocaleKeys.manage_venue_info_confirm_online_title.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                LocaleKeys.manage_venue_info_confirm_online_body.tr(),
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontSize: 13,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              const SizedBox(height: 10),
              if (warnings.isEmpty)
                Text(
                  LocaleKeys.manage_venue_info_confirm_online_note.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    height: 1.5,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                )
              else
                for (final w in warnings) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsetsDirectional.only(top: 6),
                        child: Icon(
                          TablerIcons.point_filled,
                          color: c.primary,
                          size: 10,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          w,
                          style: TextStyle(
                            color: c.onSurface,
                            fontSize: 13,
                            height: 1.5,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(
                LocaleKeys.common_cancel.tr(),
                style: TextStyle(
                  color: c.onSurfaceSecondary,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: c.primary,
                foregroundColor: c.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                LocaleKeys.manage_venue_info_confirm_online_confirm.tr(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _dispatchUpdate({
    required bool? onlineOnlyField,
    required bool force,
  }) {
    final stripLocation = onlineOnlyField == true || _onlineOnly;

    final body = UpdateBusinessVenueRequest(
      nameAr: nameArController.text.isEmpty ? null : nameArController.text,
      nameEn: nameEnController.text.isEmpty ? null : nameEnController.text,
      descriptionAr: descriptionArController.text.isEmpty
          ? null
          : descriptionArController.text,
      descriptionEn: descriptionEnController.text.isEmpty
          ? null
          : descriptionEnController.text,
      categoryId: _parseInt(categoryIdController.text),
      latitude: stripLocation ? null : _parseDouble(latitudeController.text),
      longitude: stripLocation ? null : _parseDouble(longitudeController.text),
      addressAr: stripLocation || addressArController.text.isEmpty
          ? null
          : addressArController.text,
      addressEn: stripLocation || addressEnController.text.isEmpty
          ? null
          : addressEnController.text,
      cityId: stripLocation ? null : _parseInt(cityIdController.text),
      districtId: stripLocation ? null : _parseInt(districtIdController.text),
      phone: phoneController.text.isEmpty ? null : phoneController.text,
      website: websiteController.text.isEmpty ? null : websiteController.text,
      onlineOnly: onlineOnlyField,
      force: force ? true : null,
    );

    context.read<EditVenueBloc>().add(
          EditVenue(venueId: widget.venue.id, request: body),
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
        elevation: 0,
        title: Text(
          LocaleKeys.manage_venue_info_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: BlocConsumer<EditVenueBloc, EditVenueState>(
          listener: (context, state) {
            if (state is EditVenueSuccess) {
              context
                  .read<VenueBloc>()
                  .add(GetVenueDetails(widget.venue.id));
              Navigator.of(context).pop();
            }
          },
          builder: (context, state) {
            final saving = state is EditVenueLoading;
            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionLabel(text: LocaleKeys.manage_venue_info_section_basic_info.tr()),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: nameArController,
                          isRequired: true,
                          label: LocaleKeys.manage_venue_info_label_name_ar.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: nameEnController,
                          isRequired: true,
                          label: LocaleKeys.manage_venue_info_label_name_en.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: descriptionArController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_info_label_description_ar.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: descriptionEnController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_info_label_description_en.tr(),
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(text: LocaleKeys.manage_venue_info_section_category.tr()),
                        const SizedBox(height: 16),
                        VenueCategoriesDropDownMenu(
                          controller: categoryIdController,
                          isRequired: false,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel(text: LocaleKeys.manage_venue_info_section_venue_type.tr()),
                        const SizedBox(height: 12),
                        _OnlineOnlyToggle(
                          value: _onlineOnly,
                          onChanged: (next) {
                            setState(() => _onlineOnly = next);
                          },
                        ),
                        if (!_onlineOnly) ...[
                          const SizedBox(height: 24),
                          _SectionLabel(text: LocaleKeys.manage_venue_info_section_location.tr()),
                          const SizedBox(height: 16),
                          CreateVenueLocationField(
                            latitudeController: latitudeController,
                            longitudeController: longitudeController,
                            addressArController: addressArController,
                            addressEnController: addressEnController,
                            cityIdController: cityIdController,
                            districtIdController: districtIdController,
                            hasLocation: true,
                            showToggle: false,
                            onHasLocationChanged: (_) {},
                          ),
                          const SizedBox(height: 16),
                          CreateVenueCityAndDistrictField(
                            cityController: cityIdController,
                            districtController: districtIdController,
                          ),
                        ],
                        const SizedBox(height: 24),
                        _SectionLabel(text: LocaleKeys.manage_venue_info_section_contact_info.tr()),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: phoneController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_info_label_phone.tr(),
                        ),
                        const SizedBox(height: 16),
                        CreateVenueTextField(
                          controller: websiteController,
                          isRequired: false,
                          label: LocaleKeys.manage_venue_info_label_website.tr(),
                        ),
                      ],
                    ),
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(15, 8, 15, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (saving || _impactInFlight)
                            ? null
                            : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: c.primary,
                          foregroundColor: c.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        child: (saving || _impactInFlight)
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: c.onPrimary,
                                ),
                              )
                            : Text(LocaleKeys.manage_venue_info_button_save_changes.tr()),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}


class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(child: Divider(color: c.divider)),
        const SizedBox(width: 10),
        Text(
          text,
          style: TextStyle(color: c.onSurface, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.divider)),
      ],
    );
  }
}

class _OnlineOnlyToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _OnlineOnlyToggle({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      decoration: BoxDecoration(
        color: c.surfaceElevated,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
      child: Row(
        children: [
          Icon(
            value
                ? TablerIcons.world
                : TablerIcons.building_store,
            color: c.onSurface,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  LocaleKeys.manage_venue_info_online_only_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  (value
                          ? LocaleKeys.manage_venue_info_online_only_on_subtitle
                          : LocaleKeys.manage_venue_info_online_only_off_subtitle)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    height: 1.4,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeThumbColor: c.primary,
          ),
        ],
      ),
    );
  }
}

