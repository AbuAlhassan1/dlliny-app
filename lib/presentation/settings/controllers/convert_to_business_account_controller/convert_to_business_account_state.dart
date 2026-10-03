part of 'convert_to_business_account_bloc.dart';

sealed class ConvertToBusinessAccountState {}

final class ConvertToBusinessAccountInitial extends ConvertToBusinessAccountState {}
final class RequestLoading extends ConvertToBusinessAccountState {}
final class RequestSent extends ConvertToBusinessAccountState {
  final BusinessRequestResponse requestResponse;
  RequestSent(this.requestResponse);
}
final class RequestError extends ConvertToBusinessAccountState {
  final String message;
  RequestError(this.message);
}

final class CheckingRequestLoading extends ConvertToBusinessAccountState {}
final class CheckingRequestLoaded extends ConvertToBusinessAccountState {
  final BusinessRequestResponse? requestResponse;
  CheckingRequestLoaded({this.requestResponse});
}
final class CheckingRequestError extends ConvertToBusinessAccountState {
  final String message;
  CheckingRequestError(this.message);
}
