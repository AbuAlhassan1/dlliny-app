import 'package:flutter/material.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class CreateVenueTextField extends StatelessWidget {
  final TextEditingController controller;
  final String? label;
  final String? hint;
  final bool isRequired;
  const CreateVenueTextField({
    super.key,
    required this.controller,
    this.label,
    this.hint,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      label: label,
      hint: hint,
      requiredMark: isRequired,
    );
  }
}
