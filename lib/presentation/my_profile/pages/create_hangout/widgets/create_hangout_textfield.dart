import 'package:flutter/material.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class CreateHangoutTextfield extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String? label;
  final int? maxLines;
  final TextInputType? keyboardType;

  const CreateHangoutTextfield({
    super.key,
    required this.controller,
    required this.hint,
    this.label,
    this.maxLines = 1,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      controller: controller,
      hint: hint,
      label: label,
      maxLines: maxLines,
      keyboardType: keyboardType,
    );
  }
}
