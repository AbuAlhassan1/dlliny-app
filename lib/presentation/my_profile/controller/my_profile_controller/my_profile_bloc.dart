import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/network/upload_file_to_s3.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/data/local/app_cache_repository.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/complete_profile_request.dart';
import 'package:hangout/domain/dto/request/update_profile_request.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';

part 'my_profile_event.dart';
part 'my_profile_state.dart';

class MyProfileBloc extends Bloc<MyProfileEvent, ProfileState> {
  final ApiService apiService = serviceLocator.get<ApiService>();
  final AppCacheRepository _cache = serviceLocator.get<AppCacheRepository>();

  UserDto? _user;
  UserDto? get user => state.user ?? _user;

  String myAvatarCacheKey = "my_avatar_cache_key";

  Future<UserDto?> _readCachedProfile() async {
    try {
      final raw = await _cache.read(AppCacheKeys.myProfile);
      if (raw is Map) {
        return UserDto.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {
    }
    return null;
  }

  MyProfileBloc() : super(const MyProfileInitial()) {
    on<MyProfileEvent>((event, emit) {});

    on<GetMyProfile>((event, emit) async {
      if (_user == null) {
        final cached = await _readCachedProfile();
        if (cached != null) {
          _user = cached;
          emit(MyProfileLoaded(user: _user));
        }
      }
      if (_user == null) emit(MyProfileLoading(user: _user));

      ApiResponse<UserDto> response;

      try {
        log('Making API call to fetch profile...');
        response = await apiService.getMyProfile();
      } catch (e) {
        log('Error fetching profile: $e');
        if (emit.isDone) return;
        if (_user == null) {
          emit(MyProfileError('Failed to load profile: $e', user: _user));
        }
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        log('Profile fetched successfully: ${response.data}');
        _user = response.data;
        await _cache.write(AppCacheKeys.myProfile, response.data!.toJson());
        emit(MyProfileLoaded(user: _user));
      } else if (_user != null) {
        emit(MyProfileLoaded(user: _user));
      } else {
        log('API error fetching profile: ${response.error}');
        emit(MyProfileError(
          'Failed to load profile: ${response.error}',
          user: _user,
        ));
      }
    });

    on<EditAvatar>((event, emit) async {

      emit(AvatarUploadUrlLoading(user: _user));

      ApiResponse<UploadUrlResponse> response1;

      try {
        response1 = await apiService.getAvatarUploadUrl("image/jpeg");
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(AvatarUploadUrlError('Failed to get upload URL', user: _user));
        return;
      }
      if (emit.isDone) return;

      if (!response1.success || response1.data == null) {
        emit(AvatarUploadUrlError(
          'Failed to get upload URL: ${response1.error}',
          user: _user,
        ));
        return;
      }


      String uploadUrl = response1.data!.uploadUrl;
      String key = response1.data!.key;

      try{
        await uploadToS3(uploadUrl, "image/jpeg", event.file);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(AvatarUploadUrlError('Failed to upload avatar to S3', user: _user));
        return;
      }
      if (emit.isDone) return;

      ApiResponse<void> response2;
      try {
        response2 = await apiService.confirmAvatarUpload(key);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(AvatarUploadUrlError('Failed to confirm avatar upload', user: _user));
        return;
      }
      if (emit.isDone) return;

      if ( response2.success) {
        emit(AvatarUploadUrlLoaded(user: _user));
        myAvatarCacheKey = "my_avatar_cache_key_${DateTime.now().millisecondsSinceEpoch}";
        add(GetMyProfile());
        return;
      } else {
        emit(AvatarUploadUrlError(
          'Failed to confirm avatar upload: ${response2.error}',
          user: _user,
        ));
        return;
      }


    });

    on<CompleteMyProfile>((event, emit) async {

      final username = event.username;
      if (event.displayName.isEmpty) {
        emit(MyProfileUpdateError('الاسم مطلوب', user: _user));
        return;
      }
      if (username != null && (username.isEmpty || username.contains(' '))) {
        emit(MyProfileUpdateError('اسم المستخدم غير صالح', user: _user));
        return;
      }

      emit(MyProfileUpdating(user: _user));

      ApiResponse<void> response;

      try {
        response = await apiService.completeProfile(CompleteProfileRequest(
          displayName: event.displayName,
          username: event.username,
          bio: event.bio,
          city: event.city,
          district: event.district,
          gender: event.gender,
          cityId: event.cityId,
          districtId: event.districtId,
        ));
      } on DioException catch (e) {
        log('CompleteMyProfile: dio failure: ${e.message}');
        if (emit.isDone) return;
        emit(MyProfileUpdateError(_translateProfileError(e), user: _user));
        return;
      } catch (e) {
        log('CompleteMyProfile: unexpected failure: $e');
        if (emit.isDone) return;
        emit(MyProfileUpdateError('تعذر حفظ معلوماتك. حاول مجدداً.', user: _user));
        return;
      }
      if (emit.isDone) return;

      if (response.success) {
        emit(MyProfileUpdated(user: _user));
        add(GetMyProfile());
      } else {
        final msg = (response.error ?? '').trim();
        emit(MyProfileUpdateError(
          msg.isEmpty ? 'تعذر حفظ معلوماتك. حاول مجدداً.' : msg,
          user: _user,
        ));
      }
    });

    on<UpdateMyProfile>((event, emit) async {
      if (event.displayName.trim().isEmpty) {
        emit(MyProfileUpdateError('الاسم الظاهر مطلوب', user: _user));
        return;
      }

      emit(MyProfileUpdating(user: _user));

      ApiResponse<UserDto> response;
      try {
        response = await apiService.updateProfile(
          UpdateProfileRequest(
            displayName: event.displayName.trim(),
            bio: event.bio,
            city: event.city,
            district: event.district,
            cityId: event.cityId,
            districtId: event.districtId,
          ),
        );
      } on DioException catch (e) {
        if (emit.isDone) return;
        emit(MyProfileUpdateError('Failed to update profile: ${e.message}', user: _user));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _user = response.data;
        await _cache.write(AppCacheKeys.myProfile, response.data!.toJson());
        emit(MyProfileUpdated(user: _user));
        emit(MyProfileLoaded(user: _user));
      } else {
        emit(MyProfileUpdateError(
          response.error ?? 'Failed to update profile',
          user: _user,
        ));
      }
    });

    on<UpdateAccountType>((event, emit) async {
      emit(AccountTypeUpdating(user: _user));

      ApiResponse<UserDto> response;
      try {
        response = await apiService.updateProfile(
          UpdateProfileRequest(isPrivate: event.isPrivate),
        );
      } on DioException catch (e) {
        if (emit.isDone) return;
        emit(AccountTypeUpdateError('Failed to update: ${e.message}', user: _user));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _user = response.data;
        await _cache.write(AppCacheKeys.myProfile, response.data!.toJson());
        emit(AccountTypeUpdated(user: _user));
        emit(MyProfileLoaded(user: _user));
      } else {
        emit(AccountTypeUpdateError(
          response.error ?? 'Failed to update account type',
          user: _user,
        ));
      }
    });
  }
}

String _translateProfileError(DioException e) {
  final raw = e.response?.data;
  String? serverError;
  if (raw is Map && raw['error'] is String) {
    serverError = (raw['error'] as String).trim();
  }
  final status = e.response?.statusCode;

  if (serverError != null) {
    final lower = serverError.toLowerCase();
    if (status == 409 ||
        lower.contains('username') &&
            (lower.contains('taken') || lower.contains('already'))) {
      return 'اسم المستخدم محجوز. جرّب اسماً آخر.';
    }
  }

  if (e.type == DioExceptionType.connectionTimeout ||
      e.type == DioExceptionType.receiveTimeout ||
      e.type == DioExceptionType.sendTimeout ||
      e.type == DioExceptionType.connectionError) {
    return 'تعذر الاتصال بالخادم. تحقق من الإنترنت وحاول مجدداً.';
  }
  if (status != null && status >= 500) {
    return 'مشكلة في الخادم. حاول بعد قليل.';
  }
  if (status == 401 || status == 403) {
    return 'انتهت جلستك. الرجاء تسجيل الدخول مجدداً.';
  }

  if (serverError != null && serverError.isNotEmpty) {
    return serverError;
  }
  return 'تعذر حفظ معلوماتك. حاول مجدداً.';
}
