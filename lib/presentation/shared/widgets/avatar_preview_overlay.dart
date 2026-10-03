import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

class AvatarPreviewOverlay extends StatelessWidget {
  final String imageUrl;
  final bool circular;

  const AvatarPreviewOverlay({
    super.key,
    required this.imageUrl,
    this.circular = true,
  });

  @override
  Widget build(BuildContext context) {
    final shortest = MediaQuery.of(context).size.shortestSide;
    final dim = shortest * 0.78;
    return Material(
      color: Colors.black.withValues(alpha: 0.86),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => Navigator.of(context).maybePop(),
        child: Center(
          child: Hero(
            tag: 'avatar-preview:$imageUrl',
            child: Container(
              width: dim,
              height: dim,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                shape: circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: circular ? null : BorderRadius.circular(24),
                color: Colors.white.withValues(alpha: 0.08),
              ),
              child: imageUrl.isEmpty
                  ? const Icon(
                      TablerIcons.user,
                      color: Colors.white54,
                      size: 80,
                    )
                  : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: (dim * 3).round(),
                      placeholder: (_, _) => const Center(
                        child: SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 1.5,
                          ),
                        ),
                      ),
                      errorWidget: (_, _, _) => const Icon(
                        TablerIcons.photo_x,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

Future<void> showAvatarPreviewOverlay(
  BuildContext context, {
  required String imageUrl,
  bool circular = true,
}) {
  return Navigator.of(context).push(
    PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: true,
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 140),
      pageBuilder: (_, _, _) => AvatarPreviewOverlay(
        imageUrl: imageUrl,
        circular: circular,
      ),
      transitionsBuilder: (_, anim, _, child) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.85, end: 1.0).animate(
            CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
          ),
          child: child,
        ),
      ),
    ),
  );
}
