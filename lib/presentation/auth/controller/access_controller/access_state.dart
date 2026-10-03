part of 'access_bloc.dart';

sealed class AccessState {}

final class AccessInitial extends AccessState {}
final class AccessLoading extends AccessState {}
final class AccessLoaded extends AccessState {
  final UserAccessResponse response;
  AccessLoaded({required this.response});
}
final class AccessError extends AccessState {
  final String message;
  AccessError({required this.message});
}
