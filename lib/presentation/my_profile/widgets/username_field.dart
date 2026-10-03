import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

final _kUsernameAllowedChars = RegExp(r'^[a-zA-Z0-9_-]+$');

class UsernameField extends StatefulWidget {
  final TextEditingController usernameController;

  final String seededUsername;

  const UsernameField({
    super.key,
    required this.usernameController,
    this.seededUsername = '',
  });

  @override
  State<UsernameField> createState() => _UsernameFieldState();
}

class _UsernameFieldState extends State<UsernameField> {
  final GlobalKey<FormFieldState<String>> fieldKey =
      GlobalKey<FormFieldState<String>>();

  Timer? _debounce;

  bool? isAvailable;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  bool _isSeeded(String value) =>
      widget.seededUsername.isNotEmpty &&
      value.trim() == widget.seededUsername.trim();

  void onUsernameChanged(String value) {
    _debounce?.cancel();
    if (_isSeeded(value)) {
      if (mounted) setState(() => isAvailable = true);
      fieldKey.currentState?.validate();
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      final res =
          await serviceLocator.get<ApiService>().checkUsernameAvailable(value);
      if (!mounted) return;
      setState(() => isAvailable = res.data);
      fieldKey.currentState?.validate();
    });
  }

  String? _validate(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return LocaleKeys.profile_username_field_required.tr();
    if (v.length < 3) {
      return LocaleKeys.profile_username_field_too_short.tr();
    }
    if (v.length > 30) {
      return LocaleKeys.profile_username_field_too_long.tr();
    }
    if (!_kUsernameAllowedChars.hasMatch(v)) {
      return LocaleKeys.profile_username_field_invalid_chars.tr();
    }
    if (_isSeeded(v)) return null;
    if (isAvailable == false) {
      return LocaleKeys.profile_username_field_unavailable.tr();
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextFormField(
      key: fieldKey,
      controller: widget.usernameController,
      onChanged: onUsernameChanged,
      validator: _validate,
      style: TextStyle(color: c.onSurface),
      decoration: appInputDecoration(
        c,
        hint: LocaleKeys.profile_username_field_hint.tr(),
      ),
    );
  }
}
