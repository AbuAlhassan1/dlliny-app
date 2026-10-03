import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/domain/dto/response/chat_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/chat/helpers/open_shared_resource.dart';

class ShareMessageContent extends StatelessWidget {
  final SharedResourcePreview preview;
  final String? caption;
  final bool isMine;

  const ShareMessageContent({
    super.key,
    required this.preview,
    required this.isMine,
    this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final available = preview.available;
    final fg = isMine ? c.onPrimary : c.onSurface;

    return Column(
      crossAxisAlignment:
          isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (caption != null && caption!.trim().isNotEmpty) ...[
          Text(
            caption!,
            style: TextStyle(color: fg, fontSize: 15),
          ),
          const SizedBox(height: 8),
        ],
        Opacity(
          opacity: available ? 1 : 0.55,
          child: Material(
            color: fg.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: available
                  ? () => openSharedResource(context, preview)
                  : null,
              child: Container(
                width: 240,
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _Thumbnail(preview: preview),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _resourceKindLabel(preview.type),
                            style: TextStyle(
                              color: fg.withValues(alpha: 0.55),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            preview.title?.trim().isNotEmpty == true
                                ? preview.title!
                                : LocaleKeys.chat_shared_resource_untitled.tr(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: fg,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2,
                            ),
                          ),
                          if (preview.subtitle != null &&
                              preview.subtitle!.trim().isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              preview.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.75),
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (!available) ...[
                            const SizedBox(height: 4),
                            Text(
                              LocaleKeys.chat_shared_resource_unavailable.tr(),
                              style: TextStyle(
                                color: fg.withValues(alpha: 0.6),
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final SharedResourcePreview preview;
  const _Thumbnail({required this.preview});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = preview.imageUrl;
    return Stack(
      children: [
        Container(
          width: 60,
          height: 60,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.mediaSurface.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: (url != null && url.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  memCacheWidth: 180,
                  errorWidget: (_, _, _) => _fallbackIcon(c, preview.type),
                )
              : _fallbackIcon(c, preview.type),
        ),
        Positioned(
          right: 3,
          bottom: 3,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: c.scrim,
              shape: BoxShape.circle,
            ),
            child: Icon(
              _typeIcon(preview.type),
              color: c.onMediaSurface,
              size: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _fallbackIcon(AppColors c, SharedResourceType type) {
    return Center(
      child: Icon(
        _typeIcon(type),
        color: c.onMediaSurface.withValues(alpha: 0.54),
        size: 22,
      ),
    );
  }
}

IconData _typeIcon(SharedResourceType type) {
  switch (type) {
    case SharedResourceType.post:
      return TablerIcons.photo;
    case SharedResourceType.hangout:
      return TablerIcons.confetti;
    case SharedResourceType.venue:
      return TablerIcons.map_pin;
    case SharedResourceType.user:
      return TablerIcons.user;
    case SharedResourceType.memory:
      return TablerIcons.book_2;
  }
}

String _resourceKindLabel(SharedResourceType type) {
  switch (type) {
    case SharedResourceType.post:
      return LocaleKeys.chat_shared_resource_type_post.tr();
    case SharedResourceType.hangout:
      return LocaleKeys.chat_shared_resource_type_hangout.tr();
    case SharedResourceType.venue:
      return LocaleKeys.chat_shared_resource_type_place.tr();
    case SharedResourceType.user:
      return LocaleKeys.chat_shared_resource_type_profile.tr();
    case SharedResourceType.memory:
      return LocaleKeys.chat_shared_resource_type_story.tr();
  }
}
