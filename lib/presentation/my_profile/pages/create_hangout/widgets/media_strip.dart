import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class MediaStrip extends StatelessWidget {
  final List<File> media;
  final ScrollController? scrollController;

  final VoidCallback onAddTap;

  final ValueChanged<int> onRemove;

  final bool compact;

  const MediaStrip({
    super.key,
    required this.media,
    required this.onAddTap,
    required this.onRemove,
    this.scrollController,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tileSize = compact ? 64.0 : 60.0;
    return SizedBox(
      height: tileSize,
      width: double.infinity,
      child: SingleChildScrollView(
        controller: scrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: <Widget>[
                DottedBorder(
                  options: RoundedRectDottedBorderOptions(
                    radius: const Radius.circular(10),
                    color: c.onSurface,
                  ),
                  child: InkWell(
                    onTap: onAddTap,
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      height: tileSize,
                      width: tileSize,
                      child: Icon(
                        TablerIcons.photo_plus,
                        size: compact ? 18 : 20,
                        color: c.onSurfaceSecondary,
                      ),
                    ),
                  ),
                ),
              ] +
              List<Widget>.generate(
                media.length,
                (index) => _MediaTile(
                  file: media[index],
                  tileSize: tileSize,
                  compact: compact,
                  onRemove: () => onRemove(index),
                ),
              ),
        ),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final File file;
  final double tileSize;
  final bool compact;
  final VoidCallback onRemove;

  const _MediaTile({
    required this.file,
    required this.tileSize,
    required this.compact,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      height: tileSize,
      width: tileSize,
      margin: EdgeInsetsDirectional.only(start: compact ? 8 : 10),
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        border: Border.all(
          color: c.border,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Builder(
                builder: (context) {
                  final isVideo =
                      mediaTypeFromContentType(contentTypeFromFile(file)) ==
                          'video';
                  if (isVideo) {
                    return FutureBuilder<Uint8List?>(
                      future: _videoThumbnail(file.path),
                      builder: (context, snapshot) {
                        final bytes = snapshot.data;
                        if (bytes == null || bytes.isEmpty) {
                          return Container(
                            color: c.surfaceMuted,
                            child: Icon(
                              TablerIcons.video,
                              color: c.onSurfaceSecondary,
                              size: compact ? 20 : 24,
                            ),
                          );
                        }
                        return Image.memory(bytes, fit: BoxFit.cover);
                      },
                    );
                  }
                  return Image.file(file, fit: BoxFit.cover);
                },
              ),
            ),
          ),
          Align(
            alignment: AlignmentDirectional.topEnd,
            child: InkWell(
              onTap: onRemove,
              child: Icon(
                Icons.close,
                color: c.onSurface,
                size: compact ? 18 : 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<Uint8List?> _videoThumbnail(String path) async {
  try {
    return await VideoThumbnail.thumbnailData(
      video: path,
      maxWidth: 128,
      quality: 25,
    );
  } catch (e) {
    log('Error generating thumbnail: $e');
    return null;
  }
}
