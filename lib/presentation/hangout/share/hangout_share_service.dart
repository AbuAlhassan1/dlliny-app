import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/config/social_config.dart';
import 'package:hangout/core/deep_links/deep_link_handler.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/presentation/hangout/share/hangout_story_card.dart';
import 'package:hangout/presentation/hangout/share/hangout_story_editor.dart';
import 'package:hangout/presentation/hangout/share/hangout_story_preview_page.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:social_share/social_share.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

const String _kTransparentPngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==';

Future<void> showHangoutShareSheet(
  BuildContext context,
  HangoutResponse hangout, {
  VoidCallback? onShareInApp,
}) async {
  final token = hangout.inviteLink;
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
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ShareTile(
                icon: TablerIcons.brand_instagram,
                label: context.pickBilingual(
                  ar: 'مشاركة إلى ستوري انستاغرام',
                  en: 'Share to Instagram Story',
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  openHangoutStoryEditor(context, hangout.id);
                },
              ),
              _ShareTile(
                icon: TablerIcons.send,
                label: context.pickBilingual(
                  ar: 'مشاركة الرابط',
                  en: 'Share link',
                ),
                enabled: token != null && token.isNotEmpty,
                onTap: () {
                  Navigator.pop(sheetContext);
                  if (token != null && token.isNotEmpty) {
                    shareHangoutInvite(token);
                  }
                },
              ),
              _ShareTile(
                icon: TablerIcons.copy,
                label: context.pickBilingual(
                  ar: 'نسخ الرابط',
                  en: 'Copy link',
                ),
                enabled: token != null && token.isNotEmpty,
                onTap: () async {
                  Navigator.pop(sheetContext);
                  if (token == null || token.isEmpty) return;
                  final url = buildHangoutInviteUrl(token);
                  final copiedMsg = context.pickBilingual(
                    ar: 'تم نسخ الرابط',
                    en: 'Link copied',
                  );
                  await Clipboard.setData(ClipboardData(text: url));
                  appToast.success(copiedMsg);
                },
              ),
              if (onShareInApp != null)
                _ShareTile(
                  icon: TablerIcons.message_circle,
                  label: context.pickBilingual(
                    ar: 'مشاركة داخل دلّيني',
                    en: 'Share in Dlliny',
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onShareInApp();
                  },
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> shareHangoutToInstagramStory(
  BuildContext context,
  HangoutResponse hangout,
) async {
  final isArabic = context.locale.languageCode == 'ar';
  final localeName = context.locale.toString();
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  _showStoryLoader(context);
  await _renderStoryAndShare(hangout, rootNavigator, isArabic, localeName);
}

Future<void> shareHangoutToInstagramStoryById(
  BuildContext context,
  String hangoutId,
) async {
  final isArabic = context.locale.languageCode == 'ar';
  final localeName = context.locale.toString();
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  _showStoryLoader(context);
  try {
    final res = await serviceLocator.get<ApiService>().getHangout(hangoutId);
    if (!res.success || res.data == null) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      appToast.error(isArabic
          ? 'تعذّر تحميل الطلعة'
          : 'Couldn\'t load the hangout');
      return;
    }
    await _renderStoryAndShare(res.data!, rootNavigator, isArabic, localeName);
  } catch (_) {
    if (rootNavigator.canPop()) rootNavigator.pop();
    appToast.error(isArabic
        ? 'تعذّرت المشاركة، حاول مرة أخرى'
        : 'Couldn\'t share, please try again');
  }
}

void _showStoryLoader(BuildContext context) {
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const Center(
      child: CircularProgressIndicator(color: Colors.white),
    ),
  );
}

Future<void> _renderStoryAndShare(
  HangoutResponse hangout,
  NavigatorState rootNavigator,
  bool isArabic,
  String localeName,
) async {
  try {
    final built = await buildHangoutStoryCard(hangout, isArabic, localeName);
    if (built == null) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      appToast.error(isArabic
          ? 'لا يوجد رابط دعوة لهذه الطلعة'
          : 'This hangout has no invite link');
      return;
    }
    final (card, inviteUrl) = built;

    final png = await ScreenshotController().captureFromWidget(
      card,
      pixelRatio: 1,
      targetSize: const Size(HangoutStoryCard.kWidth, HangoutStoryCard.kHeight),
      delay: const Duration(milliseconds: 400),
    );

    final dir = await getTemporaryDirectory();
    final bg = File('${dir.path}/hangout_story_${hangout.id}.png');
    await bg.writeAsBytes(png, flush: true);
    final sticker = File('${dir.path}/ig_sticker_transparent.png');
    await sticker.writeAsBytes(base64Decode(_kTransparentPngBase64), flush: true);

    if (rootNavigator.canPop()) rootNavigator.pop();

    final result = await SocialShare.shareInstagramStory(
      appId: kFacebookAppId,
      imagePath: sticker.path,
      backgroundResourcePath: bg.path,
      attributionURL: inviteUrl,
    );

    final ok = result != null &&
        result.toLowerCase() != 'error' &&
        result.toLowerCase() != 'false';
    if (!ok) {
      await _fallbackShare(bg.path, inviteUrl);
    }
  } catch (_) {
    if (rootNavigator.canPop()) rootNavigator.pop();
    appToast.error(isArabic
        ? 'تعذّرت المشاركة، حاول مرة أخرى'
        : 'Couldn\'t share, please try again');
  }
}

Future<(HangoutStoryCard, String)?> buildHangoutStoryCard(
  HangoutResponse hangout,
  bool isArabic,
  String localeName,
) async {
  final token = hangout.inviteLink;
  if (token == null || token.isEmpty) return null;
  final inviteUrl = buildHangoutInviteUrl(token);
  final venueName = isArabic ? hangout.venueNameAr : hangout.venueNameEn;
  final description = hangout.description?.trim() ?? '';
  final caption = [
    if (venueName.isNotEmpty) venueName,
    if (description.isNotEmpty) description,
  ].join('\n');
  final dt = DateTime.tryParse(hangout.scheduledAt)?.toLocal();
  final dateLabel = dt == null
      ? null
      : DateFormat('EEEE d MMM • h:mm a', localeName).format(dt);

  final coverBytes = await _resolveCoverBytes(hangout);
  ui.Image? coverImage;
  if (coverBytes != null) {
    try {
      coverImage = await decodeImageFromList(coverBytes);
    } catch (_) {
      coverImage = null;
    }
  }
  final authorAvatarBytes = await _fetchBytes(hangout.organizerAvatarUrl);
  final attendeeAvatars = await Future.wait(
    hangout.acceptedInvitees
        .take(5)
        .map((a) => _fetchBytes(a.avatarUrl)),
  );

  final card = HangoutStoryCard(
    coverImage: coverImage,
    authorAvatarBytes: authorAvatarBytes,
    attendeeAvatars: attendeeAvatars,
    authorName: hangout.organizerUsername,
    authorHandle: '@${hangout.organizerUsername}',
    likesCount: hangout.likesCount,
    commentsCount: hangout.commentsCount,
    attendeesCount: hangout.attendeeCount,
    caption: caption,
    dateLabel: dateLabel,
    inviteUrl: inviteUrl,
    isArabic: isArabic,
  );
  return (card, inviteUrl);
}

Future<void> openHangoutStoryPreview(
  BuildContext context,
  String hangoutId,
) async {
  final isArabic = context.locale.languageCode == 'ar';
  final localeName = context.locale.toString();
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  _showStoryLoader(context);
  try {
    final res = await serviceLocator.get<ApiService>().getHangout(hangoutId);
    if (!res.success || res.data == null) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      appToast.error(isArabic ? 'تعذّر تحميل الطلعة' : 'Couldn\'t load the hangout');
      return;
    }
    final built = await buildHangoutStoryCard(res.data!, isArabic, localeName);
    if (rootNavigator.canPop()) rootNavigator.pop();
    if (built == null) {
      appToast.error(isArabic
          ? 'لا يوجد رابط دعوة لهذه الطلعة'
          : 'This hangout has no invite link');
      return;
    }
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutStoryPreviewPage(card: built.$1),
      ),
    );
  } catch (_) {
    if (rootNavigator.canPop()) rootNavigator.pop();
    appToast.error(isArabic
        ? 'تعذّرت المعاينة، حاول مرة أخرى'
        : 'Couldn\'t preview, please try again');
  }
}

Future<void> openHangoutStoryEditor(
  BuildContext context,
  String hangoutId,
) async {
  final isArabic = context.locale.languageCode == 'ar';
  final localeName = context.locale.toString();
  final rootNavigator = Navigator.of(context, rootNavigator: true);
  _showStoryLoader(context);
  try {
    final api = serviceLocator.get<ApiService>();
    final res = await api.getHangout(hangoutId);
    if (!res.success || res.data == null) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      appToast.error(isArabic ? 'تعذّر تحميل الطلعة' : 'Couldn\'t load the hangout');
      return;
    }
    final hangout = res.data!;
    final token = hangout.inviteLink;
    if (token == null || token.isEmpty) {
      if (rootNavigator.canPop()) rootNavigator.pop();
      appToast.error(isArabic
          ? 'لا يوجد رابط دعوة لهذه الطلعة'
          : 'This hangout has no invite link');
      return;
    }
    final inviteUrl = buildHangoutInviteUrl(token);

    List<HangoutMediaResponse> media = const [];
    try {
      final mres = await api.getHangoutMedia(hangoutId);
      if (mres.success && mres.data != null) {
        media = [...mres.data!]
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      }
    } catch (_) {
    }
    final take = media.take(1 + _kMaxStoryPhotos).toList();
    final decoded = await Future.wait(take.map(_decodeMediaImage));
    final cover = decoded.isNotEmpty ? decoded.first : null;
    final photos = decoded.length > 1 ? decoded.sublist(1) : <ui.Image?>[];

    final authorAvatar = await _fetchBytes(hangout.organizerAvatarUrl);
    final attendeeAvatars = await Future.wait(
      hangout.acceptedInvitees.take(5).map((a) => _fetchBytes(a.avatarUrl)),
    );

    final venueName = isArabic ? hangout.venueNameAr : hangout.venueNameEn;
    final description = hangout.description?.trim() ?? '';
    final caption = [
      if (venueName.isNotEmpty) venueName,
      if (description.isNotEmpty) description,
    ].join('\n');
    final dt = DateTime.tryParse(hangout.scheduledAt)?.toLocal();
    final dateLabel = dt == null
        ? null
        : DateFormat('EEEE d MMM • h:mm a', localeName).format(dt);

    final images = StoryImages(
      cover: cover,
      photos: photos,
      authorAvatar: authorAvatar,
      attendeeAvatars: attendeeAvatars,
    );
    final card = StoryCardData(
      authorName: hangout.organizerUsername,
      authorHandle: '@${hangout.organizerUsername}',
      likesCount: hangout.likesCount,
      commentsCount: hangout.commentsCount,
      attendeesCount: hangout.attendeeCount,
      caption: caption,
      dateLabel: dateLabel,
      isArabic: isArabic,
    );

    if (rootNavigator.canPop()) rootNavigator.pop();
    if (!context.mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HangoutStoryEditorPage(
          images: images,
          card: card,
          inviteUrl: inviteUrl,
          seed: hangoutId.hashCode,
        ),
      ),
    );
  } catch (_) {
    if (rootNavigator.canPop()) rootNavigator.pop();
    appToast.error(isArabic
        ? 'تعذّر فتح المحرّر، حاول مرة أخرى'
        : 'Couldn\'t open the editor, try again');
  }
}

const int _kMaxStoryPhotos = 5;

Future<void> shareStoryImageBytes(Uint8List png, String inviteUrl) async {
  final dir = await getTemporaryDirectory();
  final bg = File('${dir.path}/hangout_story_composed.png');
  await bg.writeAsBytes(png, flush: true);
  final sticker = File('${dir.path}/ig_sticker_transparent.png');
  await sticker.writeAsBytes(base64Decode(_kTransparentPngBase64), flush: true);
  try {
    final result = await SocialShare.shareInstagramStory(
      appId: kFacebookAppId,
      imagePath: sticker.path,
      backgroundResourcePath: bg.path,
      attributionURL: inviteUrl,
    );
    final ok = result != null &&
        result.toLowerCase() != 'error' &&
        result.toLowerCase() != 'false';
    if (!ok) await _fallbackShare(bg.path, inviteUrl);
  } catch (_) {
    await _fallbackShare(bg.path, inviteUrl);
  }
}

Future<ui.Image?> _decodeMediaImage(HangoutMediaResponse m) async {
  final bytes = await _mediaBytes(m);
  if (bytes == null) return null;
  try {
    return await decodeImageFromList(bytes);
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _mediaBytes(HangoutMediaResponse m) async {
  if (m.mediaType == 'video') {
    final poster = m.thumbnailUrl;
    if (poster != null && poster.isNotEmpty) {
      final b = await _fetchBytes(poster);
      if (b != null) return b;
    }
    return _videoFrameBytes(m);
  }
  return _fetchBytes(m.url);
}

Future<void> _fallbackShare(String imagePath, String inviteUrl) async {
  await Share.shareXFiles([XFile(imagePath)], text: inviteUrl);
}

Future<Uint8List?> _resolveCoverBytes(HangoutResponse hangout) async {
  try {
    final res = await serviceLocator.get<ApiService>().getHangoutMedia(hangout.id);
    final media = res.data;
    if (res.success && media != null && media.isNotEmpty) {
      final ordered = [...media]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final first = ordered.first;
      if (first.mediaType == 'video') {
        final poster = first.thumbnailUrl;
        if (poster != null && poster.isNotEmpty) {
          final bytes = await _fetchBytes(poster);
          if (bytes != null) return bytes;
        }
        return await _videoFrameBytes(first);
      }
      return await _fetchBytes(first.url);
    }
  } catch (_) {
  }
  return _fetchBytes(hangout.thumbnailUrl);
}

Future<Uint8List?> _videoFrameBytes(HangoutMediaResponse video) async {
  final videoUrl = video.url;
  if (videoUrl.isEmpty) return null;
  try {
    return await VideoThumbnail.thumbnailData(
      video: videoUrl,
      imageFormat: ImageFormat.JPEG,
      maxWidth: 1080,
      quality: 90,
    );
  } catch (_) {
    return null;
  }
}

Future<Uint8List?> _fetchBytes(String? url) async {
  if (url == null || url.isEmpty) return null;
  try {
    final res = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final data = res.data;
    return data == null ? null : Uint8List.fromList(data);
  } catch (_) {
    return null;
  }
}

class _ShareTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool enabled;

  const _ShareTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      enabled: enabled,
      onTap: enabled ? onTap : null,
      leading: Container(
        width: 44,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: c.onSurface, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: enabled ? c.onSurface : c.onSurfaceMuted,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
    );
  }
}
