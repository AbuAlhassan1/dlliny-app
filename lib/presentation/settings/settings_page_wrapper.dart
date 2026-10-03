import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/app_page_gradient.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/auth/helpers/confirm_sign_out.dart';
import 'package:hangout/presentation/business/business_page_wrapper.dart';
import 'package:hangout/presentation/influencer/widgets/influencer_toggle_card.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/widgets/user_avatar.dart';
import 'package:hangout/presentation/orders/my_orders_page_wrapper.dart';
import 'package:hangout/presentation/proximity/widgets/nearby_discovery_toggle_card.dart';
import 'package:hangout/presentation/settings/account_type_page_wrapper.dart';
import 'package:hangout/presentation/settings/blocked_users_page_wrapper.dart';
import 'package:hangout/presentation/settings/controllers/convert_to_business_account_controller/convert_to_business_account_bloc.dart';
import 'package:hangout/presentation/settings/widgets/business_account_card.dart';
import 'package:hangout/presentation/theme_controller/theme_bloc.dart';

class SettingsPageWrapper extends StatelessWidget {
  const SettingsPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocProvider(
      create: (context) => ConvertToBusinessAccountBloc(),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          shadowColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          title: Text(
            LocaleKeys.settings_title.tr(),
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24),
          ),
        ),
        body: DecoratedBox(
          position: DecorationPosition.background,
          decoration: BoxDecoration(gradient: appPageGradient(context)),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(left: 15, right: 15, top: 15),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.border, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              UserAvatar(
                                avatarUrl: context
                                    .read<MyProfileBloc>()
                                    .user!
                                    .avatarUrl,
                                size: 70,
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      context
                                              .read<MyProfileBloc>()
                                              .user!
                                              .displayName ??
                                          "",
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '@${context.read<MyProfileBloc>().user!.username}',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: c.onSurfaceSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: c.onSurfaceSecondary,
                                size: 15,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        BlocBuilder<
                          ConvertToBusinessAccountBloc,
                          ConvertToBusinessAccountState
                        >(
                          builder: (context, state) {
                            final approvedBusiness =
                                state is CheckingRequestLoaded &&
                                state.requestResponse != null &&
                                state.requestResponse!.status == 'approved';
                            final access = context
                                .watch<AccessBloc>()
                                .myAccess
                                ?.data;
                            final hasVenueAccess =
                                access != null &&
                                (access.businesses.any(
                                      (b) => b.venues.isNotEmpty,
                                    ) ||
                                    access.orphanVenues.isNotEmpty);
                            if (approvedBusiness || hasVenueAccess) {
                              return InkWell(
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => BusinessPageWrapper(),
                                  ),
                                ),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: c.surface,
                                    border: Border.all(
                                      color: c.border,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        TablerIcons.briefcase,
                                        color: c.onSurfaceSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        LocaleKeys.settings_my_business.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: c.onSurfaceSecondary,
                                        size: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return BusinessAccountCard();
                          },
                        ),

                        const SizedBox(height: 10),

                        Material(
                          color: c.surface,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => MyOrdersPageWrapper.push(context),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                border: Border.all(color: c.border, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    TablerIcons.shopping_bag,
                                    color: c.onSurfaceSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    LocaleKeys.settings_my_orders.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: c.onSurfaceSecondary,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        const InfluencerToggleCard(),

                        const SizedBox(height: 10),

                        const NearbyDiscoveryToggleCard(),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.border, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    TablerIcons.language,
                                    color: c.onSurfaceSecondary,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    LocaleKeys.settings_locale_title.tr(),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  _LocalePill(
                                    label: LocaleKeys.settings_locale_arabic.tr(),
                                    selected: context.locale.languageCode == 'ar',
                                    onTap: () =>
                                        context.setLocale(const Locale('ar')),
                                  ),
                                  const SizedBox(width: 8),
                                  _LocalePill(
                                    label: LocaleKeys.settings_locale_english.tr(),
                                    selected: context.locale.languageCode == 'en',
                                    onTap: () =>
                                        context.setLocale(const Locale('en')),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        BlocBuilder<ThemeBloc, ThemeState>(
                          builder: (context, _) {
                            final current = context.read<ThemeBloc>().themeMode;
                            return Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: c.surface,
                                border: Border.all(color: c.border, width: 1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        TablerIcons.contrast,
                                        color: c.onSurfaceSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        LocaleKeys.settings_appearance_title.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      _ThemePill(
                                        label: LocaleKeys.settings_appearance_light.tr(),
                                        icon: TablerIcons.sun,
                                        selected: current == ThemeMode.light,
                                        onTap: () =>
                                            context.read<ThemeBloc>().add(
                                              ThemeModeChanged(ThemeMode.light),
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      _ThemePill(
                                        label: LocaleKeys.settings_appearance_dark.tr(),
                                        icon: TablerIcons.moon,
                                        selected: current == ThemeMode.dark,
                                        onTap: () =>
                                            context.read<ThemeBloc>().add(
                                              ThemeModeChanged(ThemeMode.dark),
                                            ),
                                      ),
                                      const SizedBox(width: 8),
                                      _ThemePill(
                                        label: LocaleKeys.settings_appearance_system.tr(),
                                        icon: TablerIcons.device_mobile,
                                        selected: current == ThemeMode.system,
                                        onTap: () =>
                                            context.read<ThemeBloc>().add(
                                              ThemeModeChanged(
                                                ThemeMode.system,
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: c.surface,
                            border: Border.all(color: c.border, width: 1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                TablerIcons.lock_square_rounded,
                                color: c.onSurfaceSecondary,
                                size: 20,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                LocaleKeys.settings_privacy_security.tr(),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.arrow_forward_ios,
                                color: c.onSurfaceSecondary,
                                size: 15,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        BlocBuilder<MyProfileBloc, ProfileState>(
                          buildWhen: (_, s) =>
                              s is MyProfileLoaded || s is AccountTypeUpdated,
                          builder: (context, _) {
                            final isPrivate =
                                context.read<MyProfileBloc>().user?.isPrivate ??
                                false;
                            return Material(
                              color: c.surface,
                              borderRadius: BorderRadius.circular(20),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(20),
                                onTap: () {
                                  final bloc = context.read<MyProfileBloc>();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => BlocProvider.value(
                                        value: bloc,
                                        child: const AccountTypePageWrapper(),
                                      ),
                                    ),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: c.border,
                                      width: 1,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        TablerIcons.eye_check,
                                        color: c.onSurfaceSecondary,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 15),
                                      Text(
                                        LocaleKeys.settings_account_type_tile_title.tr(),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        (isPrivate
                                                ? LocaleKeys.settings_account_type_private_short
                                                : LocaleKeys.settings_account_type_public_short)
                                            .tr(),
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: c.onSurfaceSecondary,
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      Icon(
                                        Icons.arrow_forward_ios,
                                        color: c.onSurfaceSecondary,
                                        size: 15,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => BlockedUsersPageWrapper.push(context),
                          child: Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: c.surface,
                              border: Border.all(color: c.border, width: 1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  TablerIcons.forbid_2,
                                  color: c.onSurfaceSecondary,
                                  size: 20,
                                ),
                                const SizedBox(width: 15),
                                Text(
                                  LocaleKeys.settings_blocked_accounts.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                Icon(
                                  Icons.arrow_forward_ios,
                                  color: c.onSurfaceSecondary,
                                  size: 15,
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Material(
                          color: c.danger.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => confirmAndSignOut(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: c.danger.withValues(alpha: 0.43),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    TablerIcons.logout,
                                    color: c.danger,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 15),
                                  Text(
                                    LocaleKeys.settings_sign_out.tr(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: c.danger,
                                    ),
                                  ),
                                  const Spacer(),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    color: c.danger,
                                    size: 15,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LocalePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LocalePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: selected ? c.onPrimary : c.onSurface,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemePill({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? c.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: selected ? c.onPrimary : c.onSurfaceSecondary,
                size: 18,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: selected ? c.onPrimary : c.onSurface,
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
