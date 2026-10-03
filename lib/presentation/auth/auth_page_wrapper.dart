import 'dart:io' show Platform;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';

class AuthPageWrapper extends StatelessWidget {
  const AuthPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (prev, curr) =>
            curr is ApiCallError ||
            curr is OtpInvalidFromApi ||
            curr is PhoneNumberInvalidFromApi,
        listener: (context, state) {
          if (state is OtpInvalidFromApi) {
            appToast.error(state.message);
          } else if (state is PhoneNumberInvalidFromApi) {
            appToast.error(state.message);
          } else {
            appToast.error(LocaleKeys.common_error_generic.tr());
          }
        },
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Expanded(child: _Hero()),
                const _GoogleSignInButton(),
                if (Platform.isIOS) ...[
                  const SizedBox(height: 10),
                  const _AppleSignInButton(),
                ],
                const SizedBox(height: 14),
                const _LegalMicrocopy(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          height: 96,
          child: Image.asset(
            'assets/images/logo.png',
            fit: BoxFit.contain,
          ),
        )
            .animate()
            .fadeIn(duration: const Duration(milliseconds: 600))
            .moveY(
              begin: -8,
              end: 0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
        const SizedBox(height: 28),
        Text(
          LocaleKeys.auth_welcome_hero.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.onSurface,
            fontSize: 34,
            fontWeight: FontWeight.bold,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ).animate(delay: const Duration(milliseconds: 150)).fadeIn(
              duration: const Duration(milliseconds: 600),
            ),
        const SizedBox(height: 12),
        Text(
          LocaleKeys.auth_welcome_subtitle.tr(),
          textAlign: TextAlign.center,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 14,
            height: 1.6,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ).animate(delay: const Duration(milliseconds: 300)).fadeIn(
              duration: const Duration(milliseconds: 600),
            ),
      ],
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          (prev is AuthLoading) != (curr is AuthLoading),
      builder: (context, state) {
        final busy = state is AuthLoading;
        return Material(
          color: c.primary,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: busy
                ? null
                : () =>
                    context.read<AuthBloc>().add(GoogleSignInRequested()),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: busy
                    ? [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: c.onPrimary.withValues(alpha: 0.7),
                          ),
                        ),
                      ]
                    : [
                        Icon(
                          TablerIcons.brand_google_filled,
                          color: c.onPrimary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          LocaleKeys.auth_continue_with_google.tr(),
                          style: TextStyle(
                            color: c.onPrimary,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
              ),
            ),
          ),
        );
      },
    ).animate(delay: const Duration(milliseconds: 450)).fadeIn(
          duration: const Duration(milliseconds: 600),
        );
  }
}

class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      buildWhen: (prev, curr) =>
          (prev is AuthLoading) != (curr is AuthLoading),
      builder: (context, state) {
        final busy = state is AuthLoading;
        return Material(
          color: Colors.black,
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            onTap: busy
                ? null
                : () =>
                    context.read<AuthBloc>().add(AppleSignInRequested()),
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: busy
                    ? [
                        const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white70,
                          ),
                        ),
                      ]
                    : [
                        const Icon(
                          TablerIcons.brand_apple_filled,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          LocaleKeys.auth_continue_with_apple.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'IBMPlexSansArabic',
                          ),
                        ),
                      ],
              ),
            ),
          ),
        );
      },
    ).animate(delay: const Duration(milliseconds: 500)).fadeIn(
          duration: const Duration(milliseconds: 600),
        );
  }
}

class _LegalMicrocopy extends StatelessWidget {
  const _LegalMicrocopy();

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      LocaleKeys.auth_legal_microcopy.tr(),
      textAlign: TextAlign.center,
      style: TextStyle(
        color: c.onSurfaceMuted,
        fontSize: 11,
        height: 1.6,
        fontFamily: 'IBMPlexSansArabic',
      ),
    ).animate(delay: const Duration(milliseconds: 600)).fadeIn(
          duration: const Duration(milliseconds: 600),
        );
  }
}
