import 'package:animate_gradient/animate_gradient.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:dismissible_page/dismissible_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/memory_enums.dart';
import 'package:hangout/domain/dto/response/memory_response.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/memory/memory_page.dart';

class MemoryCard extends StatelessWidget {
  final MemoryTrayBucket bucket;
  const MemoryCard({super.key, required this.bucket});

  MemoryResponse get _cover => bucket.memories.first;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsetsDirectional.only(end: 15),
      width: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Positioned.fill(child: _CoverContent(memory: _cover)),

            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    bucket.owner.displayName ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: ClipPath(
                  clipper: const _RingClipper(
                    strokeWidth: 2,
                    cornerRadius: 15,
                  ),
                  child: bucket.hasUnwatched
                      ? AnimateGradient(
                          duration: const Duration(seconds: 1),
                          curve: Curves.easeInOutCubic,
                          primaryColors: const [
                            AppColors.purple,
                            Colors.red,
                            Colors.orange,
                          ],
                          secondaryColors: const [
                            Colors.red,
                            Colors.orange,
                            AppColors.purple,
                          ],
                        )
                      : const ColoredBox(color: Colors.white60),
                ),
              ),
            ),

            Positioned.fill(
              child: Material(
                type: MaterialType.transparency,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _openViewer(context),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    final tray = context.read<MemoryTrayBloc>();
    final buckets = tray.state.buckets;
    final index = buckets.indexWhere(
      (b) =>
          b.owner.type == bucket.owner.type && b.owner.id == bucket.owner.id,
    );
    if (index < 0) return;
    context.pushTransparentRoute(
      MemoryPage(buckets: buckets, initialBucketIndex: index),
    );
  }
}

class _CoverContent extends StatelessWidget {
  final MemoryResponse memory;
  const _CoverContent({required this.memory});

  @override
  Widget build(BuildContext context) {
    switch (memory.contentType) {
      case MemoryContentType.photo:
        final url = memory.mediaThumbnailUrl ?? memory.mediaUrl;
        if (url == null || url.isEmpty) return const _BlankCover();
        return CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 260,
          errorWidget: (_, _, _) => const _BlankCover(),
        );
      case MemoryContentType.video:
        final poster = memory.mediaThumbnailUrl;
        if (poster == null || poster.isEmpty) return const _BlankCover();
        return CachedNetworkImage(
          imageUrl: poster,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: 260,
          errorWidget: (_, _, _) => const _BlankCover(),
        );
      case MemoryContentType.text:
        return _TextCardCover(memory: memory);
    }
  }
}

class _TextCardCover extends StatelessWidget {
  final MemoryResponse memory;
  const _TextCardCover({required this.memory});

  Color _parseHex(String? hex, Color fallback) {
    if (hex == null) return fallback;
    final cleaned = hex.replaceFirst('#', '');
    final value = int.tryParse(cleaned, radix: 16);
    if (value == null) return fallback;
    return Color(cleaned.length == 6 ? (0xFF000000 | value) : value);
  }

  @override
  Widget build(BuildContext context) {
    final bg = _parseHex(memory.backgroundColor, Colors.black);
    final fg = _parseHex(memory.textColor, Colors.white);
    return Container(
      color: bg,
      alignment: Alignment.center,
      padding: const EdgeInsets.all(8),
      child: Text(
        memory.textContent ?? '',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: fg,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          height: 1.2,
        ),
      ),
    );
  }
}

class _BlankCover extends StatelessWidget {
  const _BlankCover();

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.white12);
  }
}

class _RingClipper extends CustomClipper<Path> {
  final double strokeWidth;
  final double cornerRadius;

  const _RingClipper({required this.strokeWidth, required this.cornerRadius});

  @override
  Path getClip(Size size) {
    final outer = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(cornerRadius),
        ),
      );
    final inner = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            strokeWidth,
            strokeWidth,
            size.width - strokeWidth * 2,
            size.height - strokeWidth * 2,
          ),
          Radius.circular(cornerRadius - strokeWidth),
        ),
      );
    return Path.combine(PathOperation.difference, outer, inner);
  }

  @override
  bool shouldReclip(_RingClipper oldClipper) =>
      oldClipper.strokeWidth != strokeWidth ||
      oldClipper.cornerRadius != cornerRadius;
}
