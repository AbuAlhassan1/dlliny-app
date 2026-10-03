import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/influencer/controllers/influencer_bloc.dart';

class InfluencerToggleCard extends StatelessWidget {
  const InfluencerToggleCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<InfluencerBloc>(
      create: (_) => InfluencerBloc(),
      child: const _InfluencerToggleView(),
    );
  }
}

class _InfluencerToggleView extends StatelessWidget {
  const _InfluencerToggleView();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocConsumer<InfluencerBloc, InfluencerState>(
      listenWhen: (_, curr) => curr is InfluencerError ||
          (curr is InfluencerReady),
      listener: (context, state) {
        if (state is InfluencerError) {
          appToast.error(LocaleKeys.influencer_toggle_failed.tr());
        } else if (state is InfluencerReady) {
          appToast.success(state.enabled
              ? LocaleKeys.influencer_enable_success.tr()
              : LocaleKeys.influencer_disable_success.tr());
        }
      },
      builder: (context, state) {
        final busy = state is InfluencerUpdating;
        final switchValue = busy ? state.target : state.enabled;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
          decoration: BoxDecoration(
            color: c.surface,
            border: Border.all(color: c.border, width: 1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            children: [
              Icon(TablerIcons.sparkles, color: c.onSurfaceSecondary, size: 20),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.influencer_toggle_label.tr(),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      LocaleKeys.influencer_toggle_description.tr(),
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
                value: switchValue,
                onChanged: busy
                    ? null
                    : (v) => context
                        .read<InfluencerBloc>()
                        .add(ToggleInfluencer(enable: v)),
                activeThumbColor: c.primary,
              ),
            ],
          ),
        );
      },
    );
  }
}
