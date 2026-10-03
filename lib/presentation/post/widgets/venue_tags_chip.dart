import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/domain/dto/response/post_response.dart';

class VenueTagsChip extends StatelessWidget {
  final List<VenueMention> venueMentions;
  final void Function(VenueMention)? onVenueTap;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const VenueTagsChip({
    super.key,
    required this.venueMentions,
    this.onVenueTap,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (venueMentions.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final bg = backgroundColor ?? theme.colorScheme.surfaceContainerHighest;
    final fg = foregroundColor ?? theme.colorScheme.onSurface;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final v in venueMentions)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: _Chip(
                label: v.nameAr ?? v.nameEn ?? '',
                backgroundColor: bg,
                foregroundColor: fg,
                onTap: onVenueTap == null ? null : () => onVenueTap!(v),
              ),
            ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback? onTap;

  const _Chip({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.map_pin, size: 14, color: foregroundColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: foregroundColor,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return content;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: content,
    );
  }
}
