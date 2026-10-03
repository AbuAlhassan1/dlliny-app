import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/edit_profile/edit_profile_page_wrapper.dart';

class UserProfileCardButtons extends StatelessWidget {
  const UserProfileCardButtons({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CardButton(
            label: LocaleKeys.common_edit.tr(),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const EditProfilePageWrapper(),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CardButton(
            label: LocaleKeys.common_share.tr(),
            onTap: null,
          ),
        ),
      ],
    );
  }
}

class _CardButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _CardButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.primary,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: c.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
