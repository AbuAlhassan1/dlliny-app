part of 'auth_bloc.dart';

abstract class AuthEvent {
  const AuthEvent();
}

class AuthStatusChanged extends AuthEvent {
  final AuthenticationStatus status;
  const AuthStatusChanged(this.status);
}

class SendOtp extends AuthEvent {
  final String phoneNumber;
  const SendOtp({required this.phoneNumber});
}

class VerifyOtp extends AuthEvent {
  final String phoneNumber;
  final String otp;
  const VerifyOtp({required this.phoneNumber, required this.otp});
}

class AuthLogoutRequested extends AuthEvent {}

class GoogleSignInRequested extends AuthEvent {}

class AppleSignInRequested extends AuthEvent {}
