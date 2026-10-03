import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class StepIndicator extends StatelessWidget {
  final int current;
  const StepIndicator({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Row(
        children: [
          _Pill(label: LocaleKeys.hangout_create_step_indicator_media.tr(), active: current == 0),
          const SizedBox(width: 8),
          _Pill(label: LocaleKeys.hangout_create_step_indicator_details.tr(), active: current == 1),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final bool active;
  const _Pill({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        height: 32,
        decoration: BoxDecoration(
          color: active ? c.primary : Colors.transparent,
          border: Border.all(
            color: active ? c.primary : c.border,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: active ? c.onPrimary : c.onSurface,
            fontSize: 12,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }
}
