import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/post/widgets/report_bottom_sheet.dart';

enum PostActionResult { deleted, reportOpened }

Future<PostActionResult?> showPostActionsSheet(
  BuildContext context, {
  required String postId,
  required bool isMine,

  String? venueId,
}) {
  return showModalBottomSheet<PostActionResult>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      final c = sheetContext.c;
      return SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 8),
            if (isMine)
              ListTile(
                leading: Icon(TablerIcons.trash, color: c.danger),
                title: Text(
                  LocaleKeys.post_actions_delete_title.tr(),
                  style: TextStyle(color: c.danger),
                ),
                onTap: () async {
                  final ok = await _confirmDelete(sheetContext);
                  if (!ok || !sheetContext.mounted) return;
                  final deleted = await _deletePost(
                    sheetContext,
                    postId: postId,
                    venueId: venueId,
                  );
                  if (!deleted || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext, PostActionResult.deleted);
                },
              ),
            ListTile(
              leading:
                  Icon(TablerIcons.flag_2, color: c.onSurfaceSecondary),
              title: Text(
                LocaleKeys.post_actions_report_title.tr(),
                style: TextStyle(color: c.onSurface),
              ),
              onTap: () {
                Navigator.pop(sheetContext, PostActionResult.reportOpened);
                showReportPostSheet(context: context, postId: postId);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<bool> _confirmDelete(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return AlertDialog(
        backgroundColor: c.surfaceElevated,
        title: Text(
          LocaleKeys.post_actions_confirm_delete_title.tr(),
          style: TextStyle(color: c.onSurface),
        ),
        content: Text(
          LocaleKeys.post_actions_confirm_delete_body.tr(),
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
              LocaleKeys.post_actions_confirm_delete_confirm.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

Future<bool> _deletePost(
  BuildContext context, {
  required String postId,
  required String? venueId,
}) async {
  final api = serviceLocator.get<ApiService>();
  try {
    final res = venueId != null
        ? await api.deleteVenuePost(venueId, postId)
        : await api.deletePost(postId);
    if (!res.success) {
      if (context.mounted) appToast.error(res.error ?? LocaleKeys.post_actions_delete_failed_fallback.tr());
      return false;
    }
    return true;
  } on DioException catch (_) {
    if (context.mounted) appToast.error(LocaleKeys.post_actions_delete_failed_fallback.tr());
    return false;
  } catch (_) {
    if (context.mounted) appToast.error(LocaleKeys.post_actions_delete_failed_fallback.tr());
    return false;
  }
}
