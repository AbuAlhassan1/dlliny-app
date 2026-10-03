import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hangout/core/di/injection_container.dart' as di;
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/core/notifications/fcm_service.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/core/realtime/stomp_chat_event_source.dart';
import 'package:hangout/core/router/routes.dart';
import 'package:hangout/core/services/proximity_reporter.dart';
import 'package:hangout/core/services/permissions_catalog.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:hangout/data/data_sources/auth_local_data_source.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/data/local/chat_cache_repository.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/bloc/message_requests/message_requests_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/firebase_options.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/posts/my_posts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/notifications/controllers/notifications_bloc.dart';
import 'package:hangout/presentation/points/controllers/user_points_bloc.dart';
import 'package:hangout/presentation/points/widgets/level_up_toast_listener.dart';
import 'package:hangout/presentation/notifications/widgets/notification_banner_host.dart';
import 'package:hangout/core/deep_links/deep_link_listener.dart';
import 'package:hangout/presentation/notifications/widgets/tap_notification_router.dart';
import 'package:hangout/presentation/shared/widgets/app_toast_host.dart';
import 'package:hangout/presentation/post/controllers/post_interactions_bloc.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/presentation/subscriptions/controllers/subscription_bloc.dart';
import 'package:hangout/presentation/theme_controller/theme_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

Future<void> _hydratePermissionsCatalog() async {
  try {
    final api = di.serviceLocator.get<ApiService>();
    final response = await api.getPermissionsCatalog();
    if (response.success && response.data != null) {
      PermissionsCatalog.hydrate(response.data!);
    }
  } catch (_) {}
}

Future<void> setup () async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  await dotenv.load(fileName: ".env");
  await di.initModule();
  await EasyLocalization.ensureInitialized();
}

void main() async {

  await setup();

  runApp(EasyLocalization(
    startLocale: Locale('ar'),
    supportedLocales: [Locale('en'), Locale('ar')],
    path: 'assets/translations',
    fallbackLocale: Locale('ar'),
    saveLocale: true,
    assetLoader: const CodegenLoader(),
    child: const MainApp()
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeBloc>.value(value: di.serviceLocator.get<ThemeBloc>()),
        BlocProvider<TabsBloc>(create: (context) => di.serviceLocator.get<TabsBloc>()),
        BlocProvider<VideoBloc>(create: (context) => di.serviceLocator.get<VideoBloc>()),
        BlocProvider<AuthBloc>(create: (context) => di.serviceLocator.get<AuthBloc>()),
        BlocProvider<AccessBloc>(create: (context) => AccessBloc()),
        BlocProvider<MyProfileBloc>(create: (context) => MyProfileBloc()),
        BlocProvider<MyPostsBloc>(create: (context) => MyPostsBloc()),
        BlocProvider<MyHangoutsBloc>(create: (context) => MyHangoutsBloc()),
        BlocProvider<NotificationsBloc>(create: (context) => NotificationsBloc()),
        BlocProvider<UserPointsBloc>(create: (context) => UserPointsBloc()),
        BlocProvider<PostInteractionsBloc>(create: (context) => PostInteractionsBloc()),
        BlocProvider<SubscriptionBloc>(create: (context) => SubscriptionBloc()),
      ],
      child: Builder(
        builder: (context) => MultiBlocListener(
          listeners: [
            BlocListener<AuthBloc, AuthState>(
              listenWhen: (prev, curr) =>
                  prev.runtimeType != curr.runtimeType,
              listener: (context, state) {
                if (state is Authenticated) {
                  FcmService.instance.start();
                  context.read<NotificationsBloc>().add(GetUnreadCount());
                  context.read<MyProfileBloc>().add(GetMyProfile());
                  context.read<UserPointsBloc>().add(LoadUserPoints());
                  di.serviceLocator.get<ChatInboxBloc>().add(InboxRequested());
                  di.serviceLocator
                      .get<MessageRequestsBloc>()
                      .add(MessageRequestsRequested());
                  di.serviceLocator.get<MemoryTrayBloc>().add(TrayRequested());
                  context.read<AccessBloc>().add(GetMyAccess());
                  context.read<SubscriptionBloc>().add(LoadMySubscriptions());
                  ProximityReporter.instance.start();
                  _hydratePermissionsCatalog();
                } else if (state is Unauthenticated) {
                  FcmService.instance.stop();
                  ProximityReporter.instance.stop();
                  context.read<NotificationsBloc>().add(ClearNotifications());
                  context.read<UserPointsBloc>().add(ClearUserPoints());
                  context.read<MyPostsBloc>().add(ResetMyPosts());
                  context.read<MyHangoutsBloc>().add(ResetMyHangouts());
                  final source = di.serviceLocator.get<ChatEventSource>();
                  if (source is StompChatEventSource) source.disconnect();
                  di.serviceLocator.get<ChatCacheRepository>().clear();
                  di.serviceLocator.get<AppCacheRepository>().clear();
                }
              },
            ),
            BlocListener<MyProfileBloc, ProfileState>(
              listenWhen: (prev, curr) =>
                  curr is MyProfileLoaded || curr is MyProfileUpdated,
              listener: (context, state) async {
                final userId = context.read<MyProfileBloc>().user?.id;
                if (userId == null) return;
                final token = await di.serviceLocator
                    .get<AuthLocalDataSource>()
                    .read();
                final jwt = token?.accessToken;
                if (jwt == null) return;
                final source = di.serviceLocator.get<ChatEventSource>();
                if (source is StompChatEventSource) {
                  await source.setSession(jwt: jwt, userId: userId);
                }
              },
            ),
          ],
          child: BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) => MaterialApp.router(
            debugShowCheckedModeBanner: false,
            routerConfig: router,
            theme: Themes.lightTheme,
            darkTheme: Themes.darkTheme,
            themeMode: context.read<ThemeBloc>().themeMode,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
            locale: context.locale,
            builder: (context, child) => DeepLinkListener(
              child: TapNotificationRouter(
              child: NotificationBannerHost(
                child: AppToastHost(
                  child: LevelUpToastListener(
                    child: ResponsiveBreakpoints.builder(
                      child: child!,
                      breakpoints: [
                        const Breakpoint(start: 0, end: 450, name: MOBILE),
                        const Breakpoint(start: 451, end: 800, name: TABLET),
                        const Breakpoint(start: 801, end: 1920, name: DESKTOP),
                        const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ),
      ),
    );
  }
}
