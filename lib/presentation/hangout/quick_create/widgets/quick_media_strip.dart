import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class QuickMediaItem {
  final File file;
  final bool isVideo;
  const QuickMediaItem(this.file, this.isVideo);
}

class QuickMediaStrip extends StatelessWidget {
  final List<QuickMediaItem> media;
  final void Function(int index) onRemove;

  const QuickMediaStrip({
    super.key,
    required this.media,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 55,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        physics: const BouncingScrollPhysics(),
        itemCount: media.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final item = media[i];
          return SizedBox(
            width: 50,
            height: 50,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child: item.isVideo
                        ? Container(
                            color: Colors.black,
                            alignment: Alignment.center,
                            child: const Icon(TablerIcons.player_play_filled,
                                color: Colors.white, size: 22),
                          )
                        : Image.file(item.file, fit: BoxFit.cover),
                  ),
                ),
                PositionedDirectional(
                  top: -6,
                  end: -6,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onRemove(i),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4)),
                      ),
                      child: const Icon(Icons.close, size: 13, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
