import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/proximity/controllers/nearby_discovery_bloc.dart';

class NearbyDiscoveryToggleCard extends StatelessWidget {
  const NearbyDiscoveryToggleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NearbyDiscoveryBloc>(
      create: (_) => NearbyDiscoveryBloc()..add(const LoadNearbyDiscovery()),
      child: const _NearbyDiscoveryToggleView(),
    );
  }
}

class _NearbyDiscoveryToggleView extends StatelessWidget {
  const _NearbyDiscoveryToggleView();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<NearbyDiscoveryBloc, NearbyDiscoveryState>(
      listenWhen: (_, curr) =>
          curr is NearbyDiscoveryError ||
          (curr is NearbyDiscoveryReady && curr.justChanged),
      listener: (context, state) {
        if (state is NearbyDiscoveryError) {
          appToast.error(state.message);
          return;
        }
        if (state is NearbyDiscoveryReady) {
          if (state.discoverable) {
            appToast.success(
              LocaleKeys.settings_nearby_discovery_enable_success.tr(),
            );
          } else {
            appToast.success(
              LocaleKeys.settings_nearby_discovery_disable_success.tr(),
              body: LocaleKeys
                  .settings_nearby_discovery_disable_success_detail
                  .tr(),
              autoDismiss: const Duration(seconds: 7),
            );
          }
        }
      },
      builder: (context, state) {
        final discoverable = state.discoverable;
        if (discoverable == null) return const SizedBox.shrink();

        final busy = state is NearbyDiscoveryUpdating;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.radar_2, color: c.onSurfaceSecondary, size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.settings_nearby_discovery_label.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.settings_nearby_discovery_description.tr(),
                      style: TextStyle(
                        fontSize: 12,
                        color: c.onSurfaceSecondary,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: discoverable,
                onChanged: busy
                    ? null
                    : (v) => context
                        .read<NearbyDiscoveryBloc>()
                        .add(ToggleNearbyDiscovery(discoverable: v)),
                activeThumbColor: c.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
