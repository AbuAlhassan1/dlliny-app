import 'dart:io';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/data_sources/camera_service.dart';
import 'package:hangout/domain/dto/request/confirm_hangout_media_request.dart';
import 'package:hangout/domain/dto/request/invite_request.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:hangout/presentation/hangout/pages/manage_hangout_media_page.dart';
import 'package:hangout/presentation/hangout/share/hangout_share_service.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/invitee_picker_field.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/gallery_picker_sheet.dart';
import 'package:hangout/presentation/shared/utils/file_media_aspect.dart';

enum HangoutActionResult { cancelled, deleted }

Future<HangoutActionResult?> showHangoutActionsSheet(
  BuildContext context, {
  required String hangoutId,
  required bool isMine,
  DateTime? scheduledAt,
  VoidCallback? onMediaUploaded,
}) {
  final showInvite = scheduledAt == null ||
      !scheduledAt.isBefore(DateTime.now().subtract(const Duration(days: 7)));
  return showModalBottomSheet<HangoutActionResult>(
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
            if (isMine) ...[
              ListTile(
                leading:
                    Icon(TablerIcons.brand_instagram, color: c.onSurface),
                title: Text(
                  LocaleKeys.hangout_actions_share_instagram_title.tr(),
                  style: TextStyle(color: c.onSurface),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_share_instagram_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  openHangoutStoryEditor(context, hangoutId);
                },
              ),
              Divider(color: c.divider, height: 1),
              if (showInvite)
                ListTile(
                  leading: Icon(TablerIcons.user_plus, color: c.onSurface),
                  title: Text(
                    LocaleKeys.hangout_actions_invite_more_title.tr(),
                    style: TextStyle(color: c.onSurface),
                  ),
                  subtitle: Text(
                    LocaleKeys.hangout_actions_invite_more_subtitle.tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () async {
                    Navigator.pop(sheetContext);
                    if (!context.mounted) return;
                    await _runInviteMore(context, hangoutId);
                  },
                ),
              ListTile(
                leading: Icon(TablerIcons.photo_plus, color: c.onSurface),
                title: Text(
                  LocaleKeys.hangout_actions_add_media_title.tr(),
                  style: TextStyle(color: c.onSurface),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_add_media_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  await runAddHangoutMedia(
                    context,
                    hangoutId,
                    onUploaded: onMediaUploaded,
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(TablerIcons.photo_minus, color: c.onSurface),
                title: Text(
                  LocaleKeys.hangout_actions_manage_media_title.tr(),
                  style: TextStyle(color: c.onSurface),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_manage_media_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  ManageHangoutMediaPage.push(context, hangoutId);
                },
              ),
              Divider(color: c.divider, height: 1),
              ListTile(
                leading: Icon(TablerIcons.calendar_cancel, color: c.danger),
                title: Text(
                  LocaleKeys.hangout_actions_cancel_title.tr(),
                  style: TextStyle(color: c.danger),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_cancel_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  final ok = await _confirmCancel(sheetContext);
                  if (!ok || !sheetContext.mounted) return;
                  final cancelled = await _runCancel(sheetContext, hangoutId);
                  if (!cancelled || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext, HangoutActionResult.cancelled);
                },
              ),
              ListTile(
                leading: Icon(TablerIcons.trash, color: c.danger),
                title: Text(
                  LocaleKeys.hangout_actions_delete_title.tr(),
                  style: TextStyle(color: c.danger),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_delete_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                  ),
                ),
                onTap: () async {
                  final ok = await _confirmDelete(sheetContext);
                  if (!ok || !sheetContext.mounted) return;
                  final deleted = await _runDelete(sheetContext, hangoutId);
                  if (!deleted || !sheetContext.mounted) return;
                  Navigator.pop(sheetContext, HangoutActionResult.deleted);
                },
              ),
            ] else
              ListTile(
                leading: Icon(
                  TablerIcons.flag_2,
                  color: c.onSurfaceSecondary,
                ),
                title: Text(
                  LocaleKeys.hangout_actions_report_title.tr(),
                  style: TextStyle(color: c.onSurfaceSecondary),
                ),
                subtitle: Text(
                  LocaleKeys.hangout_actions_report_subtitle.tr(),
                  style: TextStyle(
                    color: c.onSurfaceMuted,
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  appToast.info(LocaleKeys.hangout_report_coming_soon.tr());
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<bool> _confirmCancel(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return AlertDialog(
        backgroundColor: c.surfaceElevated,
        title: Text(
          LocaleKeys.hangout_actions_confirm_cancel_title.tr(),
          style: TextStyle(color: c.onSurface),
        ),
        content: Text(
          LocaleKeys.hangout_actions_confirm_cancel_body.tr(),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleKeys.hangout_actions_confirm_cancel_back.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocaleKeys.hangout_actions_confirm_cancel_confirm.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

Future<bool> _runCancel(BuildContext context, String hangoutId) async {
  final api = serviceLocator.get<ApiService>();
  try {
    final res = await api.cancelHangout(hangoutId);
    if (res.success) return true;
    if (context.mounted) appToast.error(res.error ?? LocaleKeys.hangout_actions_cancel_failed_fallback.tr());
    return false;
  } on DioException catch (_) {
    if (context.mounted) appToast.error(LocaleKeys.hangout_actions_cancel_failed_fallback.tr());
    return false;
  }
}

Future<bool> _confirmDelete(BuildContext context) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final c = ctx.c;
      return AlertDialog(
        backgroundColor: c.surfaceElevated,
        title: Text(
          LocaleKeys.hangout_actions_confirm_delete_title.tr(),
          style: TextStyle(color: c.onSurface),
        ),
        content: Text(
          LocaleKeys.hangout_actions_confirm_delete_body.tr(),
          style: TextStyle(color: c.onSurfaceSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleKeys.hangout_actions_confirm_delete_back.tr(),
              style: TextStyle(color: c.onSurfaceSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              LocaleKeys.hangout_actions_confirm_delete_confirm.tr(),
              style: TextStyle(color: c.danger),
            ),
          ),
        ],
      );
    },
  );
  return ok ?? false;
}

Future<bool> _runDelete(BuildContext context, String hangoutId) async {
  final api = serviceLocator.get<ApiService>();
  try {
    final res = await api.softDeleteHangout(hangoutId);
    if (res.success) return true;
    if (context.mounted) {
      appToast.error(
        res.error ?? LocaleKeys.hangout_actions_delete_failed_fallback.tr(),
      );
    }
    return false;
  } on DioException catch (_) {
    if (context.mounted) {
      appToast.error(LocaleKeys.hangout_actions_delete_failed_fallback.tr());
    }
    return false;
  }
}

Future<void> _runInviteMore(BuildContext context, String hangoutId) async {
  final picked = await showModalBottomSheet<List<UserSearchResultDto>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => const InviteePickerSheet(initial: []),
  );
  if (picked == null || picked.isEmpty || !context.mounted) return;
  final api = serviceLocator.get<ApiService>();
  try {
    final res = await api.inviteUsers(
      hangoutId,
      InviteRequest(userIds: picked.map((u) => u.id).toList()),
    );
    if (!context.mounted) return;
    if (res.success) {
      appToast.success(LocaleKeys.hangout_actions_invite_more_success.tr());
    } else {
      appToast.error(
        res.error ?? LocaleKeys.hangout_actions_invite_more_failed.tr(),
      );
    }
  } on DioException catch (_) {
    if (!context.mounted) return;
    appToast.error(LocaleKeys.hangout_actions_invite_more_failed.tr());
  }
}

enum _HangoutMediaSource { gallery, camera }

Future<_HangoutMediaSource?> _pickHangoutMediaSource(BuildContext context) {
  return showModalBottomSheet<_HangoutMediaSource>(
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
            ListTile(
              leading: Icon(TablerIcons.photo, color: c.onSurface),
              title: Text(
                LocaleKeys.profile_avatar_picker_from_gallery.tr(),
                style: TextStyle(color: c.onSurface),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _HangoutMediaSource.gallery),
            ),
            ListTile(
              leading: Icon(TablerIcons.camera, color: c.onSurface),
              title: Text(
                LocaleKeys.profile_avatar_picker_take_photo.tr(),
                style: TextStyle(color: c.onSurface),
              ),
              onTap: () =>
                  Navigator.pop(sheetContext, _HangoutMediaSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    },
  );
}

Future<void> runAddHangoutMedia(
  BuildContext context,
  String hangoutId, {
  VoidCallback? onUploaded,
}) async {
  final source = await _pickHangoutMediaSource(context);
  if (source == null || !context.mounted) return;

  final List<File> files;
  if (source == _HangoutMediaSource.gallery) {
    final picked = await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const GalleryPickerSheet(maxSelection: 10),
    );
    files = picked ?? const <File>[];
  } else {
    final photo = await CameraService().takePhoto();
    files = photo == null ? const <File>[] : [photo];
  }
  if (files.isEmpty || !context.mounted) return;

  final uploaded = await _uploadHangoutMediaFiles(context, hangoutId, files);
  if (uploaded) onUploaded?.call();
}

Future<bool> _uploadHangoutMediaFiles(
  BuildContext context,
  String hangoutId,
  List<File> files,
) async {
  appToast.info(LocaleKeys.hangout_actions_add_media_uploading.tr());

  final api = serviceLocator.get<ApiService>();
  int succeeded = 0;
  for (final file in files) {
    try {
      final contentType = contentTypeFromFile(file);
      final urlRes = await api.getHangoutMediaUploadUrl(hangoutId, contentType);
      if (!urlRes.success || urlRes.data == null) continue;
      final bytes = await file.readAsBytes();
      await Dio().put(
        urlRes.data!.uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': contentType,
            'Content-Length': bytes.length,
          },
        ),
      );
      final mediaType = mediaTypeFromContentType(contentType);
      final aspectRatio = await readFileMediaAspect(file, mediaType);
      final confirmRes = await api.confirmHangoutMedia(
        hangoutId,
        ConfirmHangoutMediaRequest(
          key: urlRes.data!.key,
          mediaType: mediaType,
          sortOrder: succeeded,
          aspectRatio: aspectRatio,
        ),
      );
      if (confirmRes.success) succeeded++;
    } on DioException catch (_) {
      continue;
    }
  }
  if (!context.mounted) return succeeded > 0;
  if (succeeded == files.length) {
    appToast.success(LocaleKeys.hangout_actions_add_media_success.tr());
  } else if (succeeded > 0) {
    appToast.info(LocaleKeys.hangout_actions_add_media_success.tr());
  } else {
    appToast.error(LocaleKeys.hangout_actions_add_media_failed.tr());
  }
  return succeeded > 0;
}
