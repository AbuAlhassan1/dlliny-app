// ignore_for_file: use_build_context_synchronously
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';

class UserAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double? size;
  const UserAvatar({super.key, required this.avatarUrl, this.size});

  @override
  Widget build(BuildContext context) {
    final dim = size ?? 80;
    final hasUrl = avatarUrl != null && avatarUrl!.isNotEmpty;
    return Container(
      width: dim,
      height: dim,
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(shape: BoxShape.circle),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(dim),
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: dim,
                height: dim,
                fit: BoxFit.cover,
                memCacheHeight: 200,
                placeholder: (_, _) => _PersonFallback(size: dim),
                errorWidget: (_, _, _) => _PersonFallback(size: dim),
              )
            : _PersonFallback(size: dim),
      ),
    );
  }
}

class _PersonFallback extends StatelessWidget {
  final double size;
  const _PersonFallback({required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      color: c.surfaceMuted,
      alignment: Alignment.center,
      child: Icon(
        TablerIcons.user,
        size: size * 0.55,
        color: c.onSurfaceSecondary,
      ),
    );
  }
}
