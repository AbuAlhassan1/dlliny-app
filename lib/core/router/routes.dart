import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/router/go_router_refresh_stream.dart';
import 'package:hangout/core/router/router.dart';
import 'package:hangout/presentation/auth/auth_page_wrapper.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:hangout/presentation/base/base_page_wrapper.dart';
import 'package:hangout/presentation/my_profile/my_profile_page_wrapper.dart';

FutureOr<String?> redirect(BuildContext context, GoRouterState state) async {
  context.read<AccessBloc>().add(GetMyAccess());
  try {
    final authState = context.read<AuthBloc>().state;
    final bool isLoggingIn = state.matchedLocation == AppRouter.login;
    await Future.delayed(const Duration(milliseconds: 500));
    if (authState is Unauthenticated) {
      return AppRouter.login;
    }
    if (authState is Authenticated && isLoggingIn) {
      return AppRouter.home;
    }
  } catch (e) {
    return null;
  }
  return null;
}

final GlobalKey<NavigatorState> appNavigatorKey =
    GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  initialLocation: AppRouter.login,
  navigatorKey: appNavigatorKey,
  refreshListenable: GoRouterRefreshStream(
    serviceLocator.get<AuthBloc>().stream,
  ),
  redirect: redirect,
  routes: [
    GoRoute(
      path: AppRouter.login,
      builder: (context, state) => const AuthPageWrapper(),
    ),
    GoRoute(
      path: AppRouter.home,
      builder: (context, state) => const BasePageWrapper(),
      routes: [
        GoRoute(
          path: AppRouter.profile,
          builder: (context, state) => const MyProfilePageWrapper(),
        ),
      ],
    ),
  ],
);
