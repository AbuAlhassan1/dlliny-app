import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';

InputDecoration appInputDecoration(
  AppColors c, {
  String? hint,
  Widget? prefixIcon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: c.onSurfaceMuted),
    prefixIcon: prefixIcon,
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: c.surfaceMuted,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
  );
}

class AppLabeledField extends StatelessWidget {
  final String label;
  final Widget child;
  final bool requiredMark;
  const AppLabeledField({
    super.key,
    required this.label,
    required this.child,
    this.requiredMark = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(text: label),
                if (requiredMark)
                  TextSpan(
                    text: ' *',
                    style: TextStyle(color: c.danger),
                  ),
              ],
            ),
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
          ),
        ),
        child,
      ],
    );
  }
}

class AppDropdownShell extends StatelessWidget {
  final Widget child;
  final bool loading;
  const AppDropdownShell({
    super.key,
    required this.child,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (!loading) return child;
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: c.onSurfaceSecondary,
          ),
        ),
      ),
    );
  }
}

class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final bool requiredMark;
  final int? maxLines;
  final int? minLines;
  final bool obscureText;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool enabled;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.requiredMark = false,
    this.maxLines = 1,
    this.minLines,
    this.obscureText = false,
    this.keyboardType,
    this.onChanged,
    this.focusNode,
    this.enabled = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final field = TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      cursorColor: c.onSurface,
      style: TextStyle(color: c.onSurface),
      maxLines: maxLines,
      minLines: minLines,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: appInputDecoration(
        c,
        hint: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
      ),
    );
    if (label == null) return field;
    return AppLabeledField(
      label: label!,
      requiredMark: requiredMark,
      child: field,
    );
  }
}
