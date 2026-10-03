import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/submit_button.dart';

class StepFooter extends StatelessWidget {
  final int currentStep;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final VoidCallback onSubmit;

  const StepFooter({
    super.key,
    required this.currentStep,
    required this.onNext,
    required this.onBack,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (currentStep == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 45,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: c.primary,
              foregroundColor: c.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: onNext,
            child: Text(
              LocaleKeys.common_next.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          SizedBox(
            height: 45,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: c.onSurface,
                side: BorderSide(color: c.borderStrong),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: onBack,
              icon: const Icon(TablerIcons.chevron_right, size: 18),
              label: Text(
                LocaleKeys.hangout_create_step_back.tr(),
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: SubmitButton(onTap: onSubmit)),
        ],
      ),
    );
  }
}
