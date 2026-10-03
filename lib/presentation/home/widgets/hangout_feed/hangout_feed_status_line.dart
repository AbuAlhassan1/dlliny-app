import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class HangoutFeedStatusLine extends StatelessWidget {
  final String scheduledLabel;
  final String joinPolicy;
  final bool isPast;

  const HangoutFeedStatusLine({
    super.key,
    required this.scheduledLabel,
    required this.joinPolicy,
    required this.isPast,
  });

  @override
  Widget build(BuildContext context) {
    final isOpen = joinPolicy == 'OPEN';
    final policyLabel = (isOpen
            ? LocaleKeys.hangout_policy_open
            : LocaleKeys.hangout_policy_invite_only)
        .tr();
    final policyIcon = isOpen ? TablerIcons.world : TablerIcons.lock;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _StatusChip(
          icon: TablerIcons.clock,
          label: scheduledLabel,
          variant: isPast ? _ChipVariant.muted : _ChipVariant.strong,
        ),
        _StatusChip(
          icon: policyIcon,
          label: policyLabel,
          variant:
              isOpen ? _ChipVariant.subtleAccent : _ChipVariant.subtle,
        ),
        if (isPast)
          _StatusChip(
            icon: TablerIcons.history,
            label: LocaleKeys.hangout_ended_badge.tr(),
            variant: _ChipVariant.muted,
          ),
      ],
    );
  }
}

enum _ChipVariant { strong, subtle, subtleAccent, muted }

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ChipVariant variant;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.variant,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final (bg, fg) = switch (variant) {
      _ChipVariant.strong => (
          c.onSurface.withValues(alpha: 0.07),
          c.onSurface,
        ),
      _ChipVariant.subtle => (
          c.onSurface.withValues(alpha: 0.04),
          c.onSurfaceSecondary,
        ),
      _ChipVariant.subtleAccent => (
          c.primary.withValues(alpha: 0.12),
          c.primary,
        ),
      _ChipVariant.muted => (
          c.onSurfaceMuted.withValues(alpha: 0.12),
          c.onSurfaceMuted,
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: fg, size: 12),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
