import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';

Future<void> confirmAndSignOut(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return AlertDialog(
        backgroundColor: c.surfaceElevated,
        title: Text(
          LocaleKeys.settings_sign_out_dialog_title.tr(),
          style: TextStyle(color: c.onSurface),
        ),
        content: Text(
          LocaleKeys.settings_sign_out_dialog_body.tr(),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleKeys.common_cancel.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocaleKeys.settings_sign_out_dialog_confirm.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      );
    },
  );
  if (confirmed != true) return;
  serviceLocator.get<AuthBloc>().add(AuthLogoutRequested());
}
