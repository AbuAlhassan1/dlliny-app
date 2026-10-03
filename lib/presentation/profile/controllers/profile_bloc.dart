import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/domain/dto/response/follow_action_response.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  UserDto? _user;
  FollowStatus? _followStatus;
  UserDto? get user => state.user ?? _user;
  FollowStatus? get followStatus => state.followStatus ?? _followStatus;

  bool get isFollowing => followStatus == FollowStatus.accepted;
  bool get isPending => followStatus == FollowStatus.pending;

  ProfileBloc() : super(const ProfileInitial()) {
    on<ProfileEvent>((event, emit) {});

    on<GetUserProfile>((event, emit) async {
      emit(ProfileLoading(user: _user, followStatus: _followStatus));

      ApiResponse<UserDto> response;
      try {
        response = await apiService.getUserProfile(event.username);
      } on DioException catch (e) {
        if (emit.isDone) return;
        emit(ProfileError(
          'Failed to load profile: $e',
          user: _user,
          followStatus: _followStatus,
        ));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _user = response.data;
        _followStatus = response.data!.followStatus ??
            (response.data!.isFollowing ? FollowStatus.accepted : null);
        emit(ProfileLoaded(user: _user, followStatus: _followStatus));
      } else {
        emit(ProfileError(
          response.error ?? 'Failed to load profile',
          user: _user,
          followStatus: _followStatus,
        ));
      }
    });

    on<FollowUser>((event, emit) async {
      if (_user == null) return;
      emit(FollowUserLoading(user: _user, followStatus: _followStatus));

      ApiResponse<FollowActionResponse> response;
      try {
        response = await apiService.followUser(_user!.id);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(FollowUserError(
          'Failed to follow user',
          user: _user,
          followStatus: _followStatus,
        ));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _followStatus = response.data!.status;
        emit(FollowUserUpdated(user: _user, followStatus: _followStatus));
      } else {
        emit(FollowUserError(
          response.error ?? 'Failed to follow user',
          user: _user,
          followStatus: _followStatus,
        ));
      }
    });

    on<UnfollowUser>((event, emit) async {
      if (_user == null) return;
      emit(UnfollowUserLoading(user: _user, followStatus: _followStatus));

      ApiResponse<dynamic> response;
      try {
        response = await apiService.unfollowUser(_user!.id);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(UnfollowUserError(
          'Failed to unfollow user',
          user: _user,
          followStatus: _followStatus,
        ));
        return;
      }
      if (emit.isDone) return;

      if (response.success) {
        _followStatus = null;
        emit(UnfollowUserUpdated(user: _user, followStatus: _followStatus));
      } else {
        emit(UnfollowUserError(
          response.error ?? 'Failed to unfollow user',
          user: _user,
          followStatus: _followStatus,
        ));
      }
    });
  }
}
