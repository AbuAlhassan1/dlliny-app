part of 'my_businesses_bloc.dart';

sealed class MyBusinessesState {}

final class MyBusinessesInitial extends MyBusinessesState {}

final class GetMyBusinessesLoading extends MyBusinessesState {}
final class GetMyBusinessesLoaded extends MyBusinessesState {
  final List<BusinessAccountResponse> response;
  GetMyBusinessesLoaded(this.response);
}
final class GetMyBusinessesError extends MyBusinessesState {
  final String message;
  GetMyBusinessesError(this.message);
}