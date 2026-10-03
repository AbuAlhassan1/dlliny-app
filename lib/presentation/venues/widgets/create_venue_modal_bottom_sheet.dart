import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/request/create_business_venue_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/presentation/venue/widgets/venue_handle_field.dart';
import 'package:hangout/presentation/venues/controllers/create_venue_controller/create_venue_bloc.dart';
import 'package:hangout/presentation/venues/controllers/venues_categories/venues_categories_bloc.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_categories_dropdown_menu.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_city_and_district_field.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_location_field.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_textfield.dart';

class CreateVneueModalBottomSheet extends StatefulWidget {
  final String businessId;
  const CreateVneueModalBottomSheet({super.key, required this.businessId});

  @override
  State<CreateVneueModalBottomSheet> createState() =>
      _CreateVneueModalBottomSheetState();
}

class _CreateVneueModalBottomSheetState
    extends State<CreateVneueModalBottomSheet> {
  final TextEditingController nameArController = TextEditingController();
  final TextEditingController nameEnController = TextEditingController();
  final TextEditingController handleController = TextEditingController();
  final VenueHandleFieldController handleStatus = VenueHandleFieldController();
  final TextEditingController descriptionArController = TextEditingController();
  final TextEditingController categoryIdController = TextEditingController();
  final TextEditingController latitudeController = TextEditingController();
  final TextEditingController longitudeController = TextEditingController();
  final TextEditingController addressArController = TextEditingController();
  final TextEditingController addressEnController = TextEditingController();
  final TextEditingController cityIdController = TextEditingController();
  final TextEditingController districtIdController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController websiteController = TextEditingController();
  final TextEditingController styleController = TextEditingController();

  bool _hasLocation = true;

  @override
  void dispose() {
    nameArController.dispose();
    nameEnController.dispose();
    handleController.dispose();
    handleStatus.dispose();
    descriptionArController.dispose();
    categoryIdController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    addressArController.dispose();
    addressEnController.dispose();
    cityIdController.dispose();
    districtIdController.dispose();
    phoneController.dispose();
    websiteController.dispose();
    styleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) =>
              VenuesCategoriesBloc()..add(GetVenuesCategories()),
        ),
        BlocProvider(create: (context) => CreateVenueBloc()),
      ],
      child: ColoredBox(
        color: c.background,
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 5,
                      width: 60,
                      decoration: BoxDecoration(
                        color: c.onSurfaceDisabled,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 15, right: 15, bottom: 50),
                  child: GestureDetector(
                    onTap: () => FocusScope.of(context).unfocus(),
                    child: Column(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                LocaleKeys.create_venue_title.tr(),
                                style: TextStyle(
                                  color: c.onSurface,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                LocaleKeys.create_venue_subtitle.tr(),
                                style: TextStyle(
                                  color: c.onSurfaceSecondary,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 30),

                        _SectionDivider(label: LocaleKeys.create_venue_section_basic_info.tr()),

                      SizedBox(height: 20),

                      VenueHandleField(
                        controller: handleController,
                        status: handleStatus,
                      ),

                      SizedBox(height: 20),

                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CreateVenueTextField(
                              controller: nameArController,
                              isRequired: true,
                              label: LocaleKeys.create_venue_label_name_ar.tr(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: CreateVenueTextField(
                              controller: nameEnController,
                              isRequired: true,
                              label: LocaleKeys.create_venue_label_name_en.tr(),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      AppTextField(
                        controller: descriptionArController,
                        label: LocaleKeys.create_venue_label_description.tr(),
                        hint: LocaleKeys.create_venue_hint_description.tr(),
                        maxLines: 3,
                        minLines: 1,
                      ),

                      SizedBox(height: 20),

                      _SectionDivider(label: LocaleKeys.create_venue_section_category.tr()),

                      const SizedBox(height: 20),

                      VenueCategoriesDropDownMenu(
                        controller: categoryIdController,
                        isRequired: true,
                      ),

                      const SizedBox(height: 20),

                      _SectionDivider(label: LocaleKeys.create_venue_section_location.tr()),

                      SizedBox(height: 20),

                      CreateVenueLocationField(
                        latitudeController: latitudeController,
                        longitudeController: longitudeController,
                        addressArController: addressArController,
                        addressEnController: addressEnController,
                        cityIdController: cityIdController,
                        districtIdController: districtIdController,
                        hasLocation: _hasLocation,
                        onHasLocationChanged: (next) =>
                            setState(() => _hasLocation = next),
                      ),

                      SizedBox(height: 20),

                      if (_hasLocation)
                        CreateVenueCityAndDistrictField(
                          cityController: cityIdController,
                          districtController: districtIdController,
                        ),

                      SizedBox(height: 20),

                      _SectionDivider(label: LocaleKeys.create_venue_section_contact_info.tr()),

                      SizedBox(height: 20),

                      CreateVenueTextField(
                        controller: phoneController,
                        isRequired: false,
                        label: LocaleKeys.create_venue_label_phone.tr(),
                      ),

                      SizedBox(height: 20),

                      CreateVenueTextField(
                        controller: websiteController,
                        isRequired: false,
                        label: LocaleKeys.create_venue_label_website.tr(),
                      ),

                      SizedBox(height: 20),

                      Row(
                        children: [
                          Expanded(
                            child: Material(
                              color: c.primary,
                              borderRadius: BorderRadius.circular(10),
                              child: BlocConsumer<CreateVenueBloc, CreateVenueState>(
                                listener: (context, state) {
                                  if (state is CreateVenueSuccess) {
                                    Navigator.pop(context);
                                  }
                                },
                                builder: (context, state) {
                                  return InkWell(
                                    onTap: () {
                                      if (state is CreateVenueLoading) return;
                                      final onlineOnly = !_hasLocation;
                                      final lat = double.tryParse(
                                        latitudeController.text.trim(),
                                      );
                                      final lng = double.tryParse(
                                        longitudeController.text.trim(),
                                      );
                                      if (!onlineOnly &&
                                          (lat == null || lng == null)) {
                                        appToast.error(
                                          LocaleKeys.create_venue_error_location_required.tr(),
                                        );
                                        return;
                                      }
                                      context.read<CreateVenueBloc>().add(
                                        CreateVenue(
                                          widget.businessId,
                                          CreateBusinessVenueRequest(
                                            nameAr: nameArController.text,
                                            nameEn: nameEnController.text,
                                            descriptionAr:
                                                descriptionArController.text,
                                            categoryId:
                                                categoryIdController.text == ""
                                                ? null
                                                : int.parse(
                                                    categoryIdController.text,
                                                  ),
                                            latitude: onlineOnly
                                                ? null
                                                : (latitudeController.text == ""
                                                    ? null
                                                    : double.tryParse(
                                                        latitudeController.text,
                                                      )),
                                            longitude: onlineOnly
                                                ? null
                                                : (longitudeController.text == ""
                                                    ? null
                                                    : double.tryParse(
                                                        longitudeController
                                                            .text,
                                                      )),
                                            addressAr: onlineOnly
                                                ? null
                                                : addressArController.text,
                                            addressEn: onlineOnly
                                                ? null
                                                : addressEnController.text,
                                            cityId: onlineOnly ||
                                                    cityIdController.text == ""
                                                ? null
                                                : int.parse(
                                                    cityIdController.text,
                                                  ),
                                            districtId: onlineOnly ||
                                                    districtIdController.text ==
                                                        ""
                                                ? null
                                                : int.parse(
                                                    districtIdController.text,
                                                  ),
                                            phone: phoneController.text,
                                            website: websiteController.text,
                                            style: styleController.text,
                                            onlineOnly: onlineOnly,
                                            handle:
                                                handleStatus.normalizedHandle,
                                          ),
                                        ),
                                      );
                                    },
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                        vertical: 10,
                                      ),
                                      child: Center(
                                        child: state is CreateVenueLoading
                                            ? SizedBox(
                                                height: 20,
                                                width: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      color: c.onPrimary,
                                                      strokeWidth: 1,
                                                    ),
                                              )
                                            : Text(
                                                LocaleKeys.create_venue_button_submit.tr(),
                                                style: TextStyle(
                                                  color: c.onPrimary,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  final String label;
  const _SectionDivider({required this.label});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Expanded(child: Divider(color: c.divider)),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        const SizedBox(width: 10),
        Expanded(child: Divider(color: c.divider)),
      ],
    );
  }
}

