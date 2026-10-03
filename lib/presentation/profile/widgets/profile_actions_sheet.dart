import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';

Future<void> showProfileActionsSheet(
  BuildContext context, {
  required String userId,
  required String username,
}) async {
  final c = context.c;
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: c.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 8, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(TablerIcons.ban, color: c.danger),
                title: Text(
                  context.pickBilingual(
                    ar: 'حظر @$username',
                    en: 'Block @$username',
                  ),
                  style: TextStyle(
                    color: c.danger,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                subtitle: Text(
                  context.pickBilingual(
                    ar: 'لن يتمكن من متابعتك أو رؤية محتواك',
                    en: "They won't be able to follow you or see your content",
                  ),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 12,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (!context.mounted) return;
                  final confirmed = await _confirmBlock(context, username);
                  if (!confirmed || !context.mounted) return;
                  await _block(context, userId: userId, username: username);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<bool> _confirmBlock(BuildContext context, String username) async {
  final c = context.c;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final dc = dialogContext.c;
      return AlertDialog(
        backgroundColor: dc.surfaceElevated,
        title: Text(
          context.pickBilingual(ar: 'حظر @$username؟', en: 'Block @$username?'),
          style: TextStyle(
            color: dc.onSurface,
            fontWeight: FontWeight.w800,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        content: Text(
          context.pickBilingual(
            ar: 'ما راح يشوف حسابك أو محتواك، وما راح يقدر يتابعك أو يراسلك. تقدر تلغي الحظر لاحقاً من الإعدادات.',
            en: "They won't see your profile or content, and can't follow or message you. You can unblock them later from Settings.",
          ),
          style: TextStyle(
            color: dc.onSurfaceSecondary,
            fontSize: 13,
            height: 1.4,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(
              context.pickBilingual(ar: 'إلغاء', en: 'Cancel'),
              style: TextStyle(
                color: dc.onSurfaceSecondary,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              context.pickBilingual(ar: 'حظر', en: 'Block'),
              style: TextStyle(
                color: c.danger,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      );
    },
  );
  return result ?? false;
}

Future<void> _block(
  BuildContext context, {
  required String userId,
  required String username,
}) async {
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  final navigator = Navigator.of(context);
  try {
    final res = await serviceLocator.get<ApiService>().blockUser(userId);
    if (res.success) {
      appToast.success(isArabic ? 'تم حظر @$username' : 'Blocked @$username');
      navigator.maybePop();
    } else {
      appToast.error(isArabic ? 'تعذّر الحظر، حاول مرة أخرى' : "Couldn't block, try again");
    }
  } on DioException catch (_) {
    appToast.error(isArabic ? 'تعذّر الحظر، حاول مرة أخرى' : "Couldn't block, try again");
  } catch (_) {
    appToast.error(isArabic ? 'تعذّر الحظر، حاول مرة أخرى' : "Couldn't block, try again");
  }
}
