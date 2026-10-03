import 'dart:developer';

import 'package:animated_toggle_switch/animated_toggle_switch.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venues/widgets/create_venue_textfield.dart';
import 'package:hangout/presentation/venues/widgets/map_location_picker.dart';

class CreateVenueLocationField extends StatefulWidget {
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final TextEditingController addressArController;
  final TextEditingController addressEnController;
  final TextEditingController cityIdController;
  final TextEditingController districtIdController;

  final bool hasLocation;

  final ValueChanged<bool> onHasLocationChanged;

  final bool showToggle;

  const CreateVenueLocationField({
    super.key,
    required this.latitudeController,
    required this.longitudeController,
    required this.addressArController,
    required this.addressEnController,
    required this.cityIdController,
    required this.districtIdController,
    required this.hasLocation,
    required this.onHasLocationChanged,
    this.showToggle = true,
  });

  @override
  State<CreateVenueLocationField> createState() =>
      _CreateVenueLocationFieldState();
}

class _CreateVenueLocationFieldState extends State<CreateVenueLocationField> {
  void _clearLocationFields() {
    widget.latitudeController.text = "";
    widget.longitudeController.text = "";
    widget.addressArController.text = "";
    widget.addressEnController.text = "";
    widget.cityIdController.text = "";
    widget.districtIdController.text = "";
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        if (widget.showToggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                LocaleKeys.create_venue_question_has_location.tr(),
                style: TextStyle(fontSize: 16, color: c.onSurface),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 80,
                child: AnimatedToggleSwitch<bool>.dual(
                  current: widget.hasLocation,
                  first: true,
                  second: false,
                  indicatorSize: const Size(1000, 20),
                  height: 20,
                  borderWidth: 1,
                  style: ToggleStyle(
                    borderColor: c.border,
                    indicatorColor: c.primary,
                  ),
                  onTap: (value) {
                    final next = value.tapped!.value;
                    log(next.toString());
                    if (next == widget.hasLocation) return;
                    if (!next) _clearLocationFields();
                    widget.onHasLocationChanged(next);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                LocaleKeys.create_venue_question_online_only.tr(),
                style: TextStyle(fontSize: 16, color: c.onSurface),
              ),
            ],
          ),

        AnimatedSize(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          alignment: Alignment.topCenter,
          child: widget.hasLocation
              ? Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Column(
                    children: [
                      AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: c.border),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: MapLocationPicker(
                              latitudeController: widget.latitudeController,
                              longitudeController: widget.longitudeController,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      CreateVenueTextField(
                        controller: widget.addressArController,
                        label: LocaleKeys.create_venue_label_address_ar.tr(),
                        hint: LocaleKeys.create_venue_hint_address_ar.tr(),
                      ),

                      const SizedBox(height: 20),

                      CreateVenueTextField(
                        controller: widget.addressEnController,
                        label: LocaleKeys.create_venue_label_address_en.tr(),
                        hint: "Palestine Street, Baghdad",
                      ),
                    ],
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}
