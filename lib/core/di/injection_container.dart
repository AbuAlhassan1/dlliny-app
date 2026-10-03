import 'package:get_it/get_it.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/network/dio_factory.dart';
import 'package:hangout/core/realtime/chat_event_source.dart';
import 'package:hangout/core/realtime/stomp_chat_event_source.dart';
import 'package:hangout/core/services/voice_playback_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/data_sources/auth_local_data_source.dart';
import 'package:hangout/data/data_sources/camera_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/data/local/chat_cache_repository.dart';
import 'package:hangout/data/repositories/analytics_repository.dart';
import 'package:hangout/data/repositories/chat_repository.dart';
import 'package:hangout/data/repositories/memory_repository.dart';
import 'package:hangout/data/repositories/memory_upload_repository.dart';
import 'package:hangout/data/repositories/voice_upload_repository.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:hangout/presentation/chat/bloc/chat_inbox/chat_inbox_bloc.dart';
import 'package:hangout/presentation/chat/bloc/message_requests/message_requests_bloc.dart';
import 'package:hangout/presentation/memory/bloc/memory_tray/memory_tray_bloc.dart';
import 'package:hangout/presentation/base/controller/tabs_bloc.dart';
import 'package:hangout/presentation/explore/controller/explore_bloc.dart';
import 'package:hangout/presentation/home/controller/home_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/create_post_controller/create_post_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/shared/controller/video_controller/video_bloc_bloc.dart';
import 'package:hangout/presentation/theme_controller/theme_bloc.dart';

final serviceLocator = GetIt.instance;

Future<void> initModule() async {
  serviceLocator.registerLazySingleton<AuthLocalDataSource>(() => AuthLocalDataSource());

  serviceLocator.registerLazySingleton<Fresh<OAuth2Token>>(() => fresh);

  serviceLocator.registerLazySingleton<ApiService>(() => ApiService(dio));

  serviceLocator.registerLazySingleton(() => ThemeBloc());

  serviceLocator.registerFactory(() => TabsBloc());

  serviceLocator.registerFactory(() => VideoBloc());

  serviceLocator.registerFactory(() => ExploreBloc());

  serviceLocator.registerFactory(() => AuthBloc());

  serviceLocator.registerLazySingleton(() => HomeBloc());

  serviceLocator.registerFactory(() => MyProfileBloc());

  serviceLocator.registerFactory(() => CreatePostBloc());

  serviceLocator.registerFactory(() => CameraService());

  serviceLocator.registerLazySingleton<AppCacheRepository>(
    () => AppCacheRepository(),
  );

  serviceLocator.registerLazySingleton<ChatCacheRepository>(
    () => ChatCacheRepository(),
  );
  serviceLocator.registerLazySingleton<ChatRepository>(
    () => ChatRepository(serviceLocator.get<ApiService>()),
  );
  serviceLocator.registerLazySingleton<VoiceUploadRepository>(
    () => VoiceUploadRepository(serviceLocator.get<ChatRepository>()),
  );
  serviceLocator.registerLazySingleton<VoicePlaybackService>(
    () => VoicePlaybackService(),
  );

  serviceLocator.registerLazySingleton<ChatEventSource>(
    () => StompChatEventSource(),
  );

  serviceLocator.registerLazySingleton<ChatInboxBloc>(
    () => ChatInboxBloc(
      serviceLocator.get<ChatRepository>(),
      serviceLocator.get<ChatEventSource>(),
      serviceLocator.get<ChatCacheRepository>(),
    ),
  );
  serviceLocator.registerLazySingleton<MessageRequestsBloc>(
    () => MessageRequestsBloc(
      serviceLocator.get<ChatRepository>(),
      serviceLocator.get<ChatInboxBloc>(),
      serviceLocator.get<ChatEventSource>(),
    ),
  );

  serviceLocator.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepository(serviceLocator.get<ApiService>()),
  );

  serviceLocator.registerLazySingleton<MemoryRepository>(
    () => MemoryRepository(serviceLocator.get<ApiService>()),
  );
  serviceLocator.registerLazySingleton<MemoryUploadRepository>(
    () => MemoryUploadRepository(serviceLocator.get<MemoryRepository>()),
  );

  serviceLocator.registerLazySingleton<MemoryTrayBloc>(
    () => MemoryTrayBloc(serviceLocator.get<MemoryRepository>()),
  );
}