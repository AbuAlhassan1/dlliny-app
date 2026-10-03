import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/utils/gallery_tags.dart';

class GalleryChip extends StatelessWidget {
  final String label;
  final int? count;
  final bool selected;

  final VoidCallback? onTap;

  final bool enabled;

  final bool onMedia;

  const GalleryChip({
    super.key,
    required this.label,
    this.count,
    this.selected = false,
    this.onTap,
    this.enabled = true,
    this.onMedia = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final Color background;
    final Color foreground;
    if (onMedia) {
      background = Colors.white.withValues(alpha: 0.18);
      foreground = Colors.white;
    } else if (selected) {
      background = c.onSurface;
      foreground = c.surface;
    } else {
      background = c.surfaceMuted;
      foreground = enabled ? c.onSurface : c.onSurfaceDisabled;
    }
    final text = count == null ? label : '$label ($count)';
    return Semantics(
      button: onTap != null,
      selected: selected,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(100),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: enabled ? onTap : null,
          child: Padding(
            padding: const EdgeInsetsDirectional.symmetric(
              horizontal: 12,
              vertical: 7,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected && onTap != null) ...[
                  Icon(TablerIcons.check, size: 14, color: foreground),
                  const SizedBox(width: 4),
                ],
                Text(
                  text,
                  maxLines: 1,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GalleryChipRow extends StatelessWidget {
  final List<Widget> chips;
  final EdgeInsetsGeometry padding;

  const GalleryChipRow({
    super.key,
    required this.chips,
    this.padding = const EdgeInsetsDirectional.symmetric(horizontal: 15),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < chips.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            chips[i],
          ],
        ],
      ),
    );
  }
}

List<VenueLocationResponse> sortedGalleryBranches(
  List<VenueLocationResponse> branches,
) => [...branches]
  ..sort((a, b) {
    if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
    return a.sortOrder.compareTo(b.sortOrder);
  });

String galleryBranchLabel(VenueLocationResponse branch) {
  final label = branch.labelAr?.trim();
  if (label != null && label.isNotEmpty) return label;
  final district = branch.districtNameAr?.trim();
  if (district != null && district.isNotEmpty) return district;
  return (branch.isPrimary
          ? LocaleKeys.venue_branches_primary_branch
          : LocaleKeys.venue_branches_branch_fallback)
      .tr();
}

class GalleryTagSelector extends StatelessWidget {
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  const GalleryTagSelector({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  void _toggle(String tag) {
    final next = [...selected];
    if (!next.remove(tag)) {
      if (next.length >= kGalleryMaxTagsPerPhoto) return;
      next.add(tag);
    }
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final full = selected.length >= kGalleryMaxTagsPerPhoto;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              LocaleKeys.manage_venue_gallery_manager_edit_tags.tr(),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              LocaleKeys.manage_venue_gallery_manager_tags_max.tr(),
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in kGalleryTags)
              GalleryChip(
                label: galleryTagLabel(tag),
                selected: selected.contains(tag),
                enabled: selected.contains(tag) || !full,
                onTap: () => _toggle(tag),
              ),
          ],
        ),
        if (needsPrivacyHint(selected)) ...[
          const SizedBox(height: 10),
          GalleryNotice(
            icon: TablerIcons.shield_lock,
            text: LocaleKeys.manage_venue_gallery_manager_privacy_hint.tr(),
            color: c.warning,
          ),
        ],
      ],
    );
  }
}

class GalleryBranchDropdown extends StatelessWidget {
  final List<VenueLocationResponse> branches;

  final String? value;
  final ValueChanged<String?> onChanged;

  const GalleryBranchDropdown({
    super.key,
    required this.branches,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LocaleKeys.manage_venue_gallery_manager_branch_label.tr(),
          style: TextStyle(
            color: c.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: value,
              isExpanded: true,
              dropdownColor: c.surface,
              icon: Icon(TablerIcons.chevron_down, color: c.onSurfaceSecondary),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: c.onSurface,
                fontSize: 14,
              ),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text(
                    LocaleKeys.manage_venue_gallery_manager_branch_none.tr(),
                  ),
                ),
                for (final b in sortedGalleryBranches(branches))
                  DropdownMenuItem<String?>(
                    value: b.id,
                    child: Text(
                      galleryBranchLabel(b),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class GalleryNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const GalleryNotice({
    super.key,
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: context.c.onSurface,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
