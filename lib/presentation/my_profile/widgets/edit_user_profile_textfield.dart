import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

class EditUserProfileTextfield extends StatelessWidget {
  final String? Function(String?) validator;
  final Function(String)? onChanged;
  final TextEditingController controller;
  final GlobalKey? fieldKey;
  const EditUserProfileTextfield({super.key, required this.controller, required this.validator, this.onChanged, this.fieldKey});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextFormField(
      key: fieldKey,
      controller: controller,
      scrollPadding: EdgeInsets.zero,
      validator: validator,
      onChanged: (String value) {
        onChanged?.call(value);
      },
      decoration: InputDecoration(
        contentPadding: EdgeInsets.zero,
        fillColor: c.surfaceMuted,
        border: InputBorder.none,
        errorBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        errorStyle: TextStyle(
          height: -1,
          color: c.danger,
        ),
      ),
      style: TextStyle(color: c.onSurface),
    );
  }
}