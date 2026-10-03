part of 'auth_bloc.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {}

class AuthLoading extends AuthState {}

class Unauthenticated extends AuthState {}

class Authenticated extends AuthState {}

class ApiCallError extends AuthState {}

class PhoneNumberInvalidFromApi extends AuthState {
  final String message;
  PhoneNumberInvalidFromApi({required this.message});
}

class OtpInvalidFromApi extends AuthState {
  final String message;
  OtpInvalidFromApi({required this.message});
}

class PhoneNumberValidAndSentSuccessfully extends AuthState {}