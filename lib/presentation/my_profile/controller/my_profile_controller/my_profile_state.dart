part of 'my_profile_bloc.dart';

sealed class ProfileState {
  final UserDto? user;
  const ProfileState({this.user});
}

final class MyProfileInitial extends ProfileState {
  const MyProfileInitial({super.user});
}
final class MyProfileLoading extends ProfileState {
  const MyProfileLoading({super.user});
}
final class MyProfileLoaded extends ProfileState {
  const MyProfileLoaded({super.user});
}
final class MyProfileError extends ProfileState {
  final String message;
  const MyProfileError(this.message, {super.user});
}
final class AvatarUploadUrlLoading extends ProfileState {
  const AvatarUploadUrlLoading({super.user});
}
final class AvatarUploadUrlLoaded extends ProfileState {
  const AvatarUploadUrlLoaded({super.user});
}
final class AvatarUploadUrlError extends ProfileState {
  final String message;
  const AvatarUploadUrlError(this.message, {super.user});
}
final class MyProfileUpdating extends ProfileState {
  const MyProfileUpdating({super.user});
}
final class MyProfileUpdated extends ProfileState {
  const MyProfileUpdated({super.user});
}
final class MyProfileUpdateError extends ProfileState {
  final String message;
  const MyProfileUpdateError(this.message, {super.user});
}

final class MyProfilePostsLoading extends ProfileState {
  const MyProfilePostsLoading({super.user});
}
final class MyProfilePostsLoaded extends ProfileState {
  const MyProfilePostsLoaded({super.user});
}
final class MyProfilePostsError extends ProfileState {
  final String message;
  const MyProfilePostsError(this.message, {super.user});
}

final class MyProfileMorePostsLoading extends ProfileState {
  const MyProfileMorePostsLoading({super.user});
}
final class MyProfileMorePostsLoaded extends ProfileState {
  const MyProfileMorePostsLoaded({super.user});
}
final class MyProfileMorePostsError extends ProfileState {
  final String message;
  const MyProfileMorePostsError(this.message, {super.user});
}

final class AccountTypeUpdating extends ProfileState {
  const AccountTypeUpdating({super.user});
}
final class AccountTypeUpdated extends ProfileState {
  const AccountTypeUpdated({super.user});
}
final class AccountTypeUpdateError extends ProfileState {
  final String message;
  const AccountTypeUpdateError(this.message, {super.user});
}
