import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class BranchPickerField extends StatelessWidget {
  final List<VenueLocationResponse> branches;
  final VenueLocationResponse? selected;
  final ValueChanged<VenueLocationResponse> onChanged;

  const BranchPickerField({
    super.key,
    required this.branches,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final picked = selected;
    final label = picked == null
        ? LocaleKeys.hangout_create_branch_placeholder.tr()
        : _branchLabelFor(context, picked);
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: c.borderStrong, width: 1),
        ),
        child: Row(
          children: [
            Icon(TablerIcons.map_pin, size: 18, color: c.onSurfaceSecondary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: picked == null ? c.onSurfaceMuted : c.onSurface,
                ),
              ),
            ),
            Icon(
              TablerIcons.chevron_down,
              size: 16,
              color: c.onSurfaceSecondary,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(BuildContext context) async {
    final picked = await showModalBottomSheet<VenueLocationResponse>(
      context: context,
      backgroundColor: context.c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BranchPickerSheet(
        branches: branches,
        selectedId: selected?.id,
      ),
    );
    if (picked != null) onChanged(picked);
  }
}

class _BranchPickerSheet extends StatelessWidget {
  final List<VenueLocationResponse> branches;
  final String? selectedId;
  const _BranchPickerSheet({required this.branches, this.selectedId});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final sorted = [...branches]..sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      return a.sortOrder.compareTo(b.sortOrder);
    });
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: c.onSurfaceDisabled,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Icon(TablerIcons.building, color: c.onSurface, size: 18),
                const SizedBox(width: 8),
                Text(
                  LocaleKeys.hangout_create_branch_sheet_title.tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(height: 1, color: c.divider),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: c.divider, indent: 16, endIndent: 16),
              itemBuilder: (context, i) {
                final b = sorted[i];
                return _BranchRow(
                  branch: b,
                  selected: b.id == selectedId,
                  onTap: () => Navigator.of(context).pop(b),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _BranchRow extends StatelessWidget {
  final VenueLocationResponse branch;
  final bool selected;
  final VoidCallback onTap;
  const _BranchRow({
    required this.branch,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final label = _branchLabelFor(context, branch);
    final addressAr = branch.addressAr;
    final addressEn = branch.addressEn;
    final address = context.pickBilingual(
      ar: addressAr,
      en: addressEn,
      fallback: addressAr ?? addressEn ?? '',
    );
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                selected
                    ? TablerIcons.circle_check_filled
                    : TablerIcons.circle,
                color: selected ? c.primary : c.onSurfaceDisabled,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: c.onSurface,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      if (branch.isPrimary) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: c.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            LocaleKeys.hangout_create_branch_primary_badge.tr(),
                            style: TextStyle(
                              color: c.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _branchLabelFor(BuildContext context, VenueLocationResponse b) {
  final label = context.pickBilingual(
    ar: b.labelAr,
    en: b.labelEn,
    fallback: '',
  );
  if (label.isNotEmpty) return label;
  final address = context.pickBilingual(
    ar: b.addressAr,
    en: b.addressEn,
    fallback: '',
  );
  if (address.isNotEmpty) return address;
  return LocaleKeys.hangout_create_branch_fallback_label.tr();
}
