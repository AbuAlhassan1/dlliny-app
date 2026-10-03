import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_analytics_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/analytics/widgets/analytics_tile.dart';

class TopMemoriesStrip extends StatelessWidget {
  final TopMemoriesResponse data;
  const TopMemoriesStrip({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasAny = data.own.isNotEmpty || data.mentioned.isNotEmpty;
    return AnalyticsTile(
      title: LocaleKeys.business_analytics_top_memories_title.tr(),
      subtitle: LocaleKeys.business_analytics_top_memories_subtitle_24h.tr(),
      child: hasAny
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (data.own.isNotEmpty) ...[
                  _SectionHeader(
                    label: LocaleKeys.business_analytics_top_memories_section_own.tr(),
                    count: data.own.length,
                  ),
                  const SizedBox(height: 6),
                  _Strip(memories: data.own),
                  const SizedBox(height: 12),
                ],
                if (data.mentioned.isNotEmpty) ...[
                  _SectionHeader(
                    label: LocaleKeys.business_analytics_top_memories_section_mentions.tr(),
                    count: data.mentioned.length,
                  ),
                  const SizedBox(height: 6),
                  _Strip(memories: data.mentioned),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      TablerIcons.info_circle,
                      color: c.onSurfaceMuted,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        LocaleKeys.business_analytics_top_memories_expiry_note.tr(),
                        style: TextStyle(
                          color: c.onSurfaceMuted,
                          fontSize: 10,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : AnalyticsTileEmpty(
              icon: TablerIcons.photo,
              message: LocaleKeys.business_analytics_top_memories_empty.tr(),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final int count;
  const _SectionHeader({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _Strip extends StatelessWidget {
  final List<TopMemory> memories;
  const _Strip({required this.memories});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: memories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => _MemoryCard(memory: memories[i]),
      ),
    );
  }
}

class _MemoryCard extends StatelessWidget {
  final TopMemory memory;
  const _MemoryCard({required this.memory});

  bool get _isText => memory.contentType == 'TEXT';
  bool get _isVideo => memory.contentType == 'VIDEO';

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      width: 76,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: c.border),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Expanded(
            child: _isText
                ? _TextThumb(content: memory.textContent ?? '')
                : _ImageThumb(
                    url: _isVideo
                        ? memory.mediaThumbnailUrl
                        : memory.mediaThumbnailUrl ?? memory.mediaUrl,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(TablerIcons.eye, color: c.onSurfaceSecondary, size: 11),
                const SizedBox(width: 3),
                Text(
                  '${memory.viewCount}',
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ImageThumb extends StatelessWidget {
  final String? url;
  const _ImageThumb({required this.url});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (url == null || url!.isEmpty) {
      return ColoredBox(
        color: c.surface,
        child: Center(
          child: Icon(TablerIcons.photo, color: c.onSurfaceDisabled, size: 22),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      errorWidget: (_, _, _) => ColoredBox(
        color: c.surface,
        child: Icon(TablerIcons.photo, color: c.onSurfaceDisabled, size: 22),
      ),
    );
  }
}

class _TextThumb extends StatelessWidget {
  final String content;
  const _TextThumb({required this.content});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.mediaSurface,
      padding: const EdgeInsets.all(6),
      alignment: Alignment.center,
      child: Text(
        content,
        textAlign: TextAlign.center,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: c.onMediaSurface,
          fontSize: 9,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}
