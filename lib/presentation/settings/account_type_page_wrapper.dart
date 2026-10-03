import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class AccountTypePageWrapper extends StatelessWidget {
  const AccountTypePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.settings_account_type_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: BlocConsumer<MyProfileBloc, ProfileState>(
        listenWhen: (_, s) => s is AccountTypeUpdateError,
        listener: (context, state) {
          if (state is AccountTypeUpdateError) {
            appToast.error(state.message);
          }
        },
        builder: (context, state) {
          final bloc = context.read<MyProfileBloc>();
          final isPrivate = bloc.user?.isPrivate ?? false;
          final isUpdating = state is AccountTypeUpdating;
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(15, 16, 15, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ToggleCard(
                  isPrivate: isPrivate,
                  isUpdating: isUpdating,
                  onChanged: (v) => bloc.add(UpdateAccountType(v)),
                ),
                const SizedBox(height: 20),
                _ModeSection(
                  title: LocaleKeys.settings_account_type_public_section_title.tr(),
                  active: !isPrivate,
                  icon: TablerIcons.world,
                  bullets: [
                    LocaleKeys.settings_account_type_public_bullet_1.tr(),
                    LocaleKeys.settings_account_type_public_bullet_2.tr(),
                    LocaleKeys.settings_account_type_public_bullet_3.tr(),
                    LocaleKeys.settings_account_type_public_bullet_4.tr(),
                    LocaleKeys.settings_account_type_public_bullet_5.tr(),
                  ],
                ),
                const SizedBox(height: 16),
                _ModeSection(
                  title: LocaleKeys.settings_account_type_private_section_title.tr(),
                  active: isPrivate,
                  icon: TablerIcons.lock,
                  bullets: [
                    LocaleKeys.settings_account_type_private_bullet_1.tr(),
                    LocaleKeys.settings_account_type_private_bullet_2.tr(),
                    LocaleKeys.settings_account_type_private_bullet_3.tr(),
                    LocaleKeys.settings_account_type_private_bullet_4.tr(),
                    LocaleKeys.settings_account_type_private_bullet_5.tr(),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: c.surface,
                    border: Border.all(color: c.border, width: 1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        TablerIcons.info_circle,
                        color: c.onSurfaceSecondary,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          LocaleKeys.settings_account_type_info_note.tr(),
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final bool isPrivate;
  final bool isUpdating;
  final ValueChanged<bool> onChanged;

  const _ToggleCard({
    required this.isPrivate,
    required this.isUpdating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border, width: 1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            isPrivate ? TablerIcons.lock : TablerIcons.world,
            color: c.onSurface,
            size: 24,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (isPrivate
                          ? LocaleKeys.settings_account_type_private_title
                          : LocaleKeys.settings_account_type_public_title)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (isPrivate
                          ? LocaleKeys.settings_account_type_private_subtitle
                          : LocaleKeys.settings_account_type_public_subtitle)
                      .tr(),
                  style: TextStyle(
                    color: c.onSurfaceSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          isUpdating
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: c.onSurface,
                    strokeWidth: 2,
                  ),
                )
              : Switch.adaptive(
                  value: isPrivate,
                  onChanged: onChanged,
                  activeThumbColor: c.onSurface,
                  activeTrackColor: c.onSurfaceDisabled,
                  inactiveThumbColor: c.onSurfaceSecondary,
                  inactiveTrackColor: c.border,
                ),
        ],
      ),
    );
  }
}

class _ModeSection extends StatelessWidget {
  final String title;
  final bool active;
  final IconData icon;
  final List<String> bullets;

  const _ModeSection({
    required this.title,
    required this.active,
    required this.icon,
    required this.bullets,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(
          color: active ? c.onSurface : c.border,
          width: active ? 1.5 : 1,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: c.onSurface, size: 20),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  color: c.onSurface,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: c.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    LocaleKeys.common_active_badge.tr(),
                    style: TextStyle(
                      color: c.onPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ...bullets.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.fiber_manual_record,
                      color: c.onSurfaceSecondary,
                      size: 6,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      b,
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 13,
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
