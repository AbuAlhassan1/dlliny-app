import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class AuthorPreviewPopup extends StatelessWidget {
  final String? imageUrl;

  final String name;

  final String? subtitle;

  final String? rolePill;

  final bool isVenue;

  final VoidCallback onOpenProfile;

  const AuthorPreviewPopup({
    super.key,
    required this.imageUrl,
    required this.name,
    required this.onOpenProfile,
    this.subtitle,
    this.rolePill,
    this.isVenue = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: c.background,
          elevation: 12,
          borderRadius: BorderRadius.circular(20),
          clipBehavior: Clip.antiAlias,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _Avatar(
                    url: imageUrl,
                    isVenue: isVenue,
                  ),
                  const SizedBox(height: 14),
                  if (rolePill != null && rolePill!.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isVenue
                            ? c.primary
                            : c.onSurface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        rolePill!,
                        style: TextStyle(
                          color: isVenue ? c.onPrimary : c.surfaceMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          fontFamily: "IBMPlexSansArabic",
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: "IBMPlexSansArabic",
                    ),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 12,
                        fontFamily: "IBMPlexSansArabic",
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        Navigator.of(context).maybePop();
                        onOpenProfile();
                      },
                      icon: const Icon(TablerIcons.user, size: 18),
                      label: Text(
                        isVenue ? 'فتح صفحة المكان' : 'فتح الصفحة الشخصية',
                        style: const TextStyle(
                          fontFamily: "IBMPlexSansArabic",
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: c.onSurface,
                        foregroundColor: c.background,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  final bool isVenue;
  const _Avatar({required this.url, required this.isVenue});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final hasUrl = url != null && url!.isNotEmpty;
    final fallback = Icon(
      isVenue ? TablerIcons.building_store : TablerIcons.user,
      color: c.onSurfaceSecondary,
      size: 36,
    );
    final shape = isVenue ? BoxShape.rectangle : BoxShape.circle;
    final radius = isVenue ? BorderRadius.circular(18) : null;
    return Container(
      width: 90,
      height: 90,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        shape: shape,
        borderRadius: radius,
        border: Border.all(color: c.border, width: 1),
      ),
      child: hasUrl
          ? CachedNetworkImage(
              imageUrl: url!,
              fit: BoxFit.cover,
              memCacheWidth: 270,
              errorWidget: (_, _, _) => fallback,
            )
          : fallback,
    );
  }
}

Future<void> showAuthorPreviewPopup(
  BuildContext context, {
  required String? imageUrl,
  required String name,
  required VoidCallback onOpenProfile,
  String? subtitle,
  String? rolePill,
  bool isVenue = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'إغلاق المعاينة',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 180),
    pageBuilder: (_, _, _) => AuthorPreviewPopup(
      imageUrl: imageUrl,
      name: name,
      subtitle: subtitle,
      rolePill: rolePill,
      isVenue: isVenue,
      onOpenProfile: onOpenProfile,
    ),
    transitionBuilder: (_, anim, _, child) => FadeTransition(
      opacity: anim,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
  );
}
