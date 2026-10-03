part of 'search_bloc.dart';

sealed class SearchState {}

final class SearchInitial extends SearchState {}
final class SearchLoading extends SearchState {}
final class SearchLoaded extends SearchState {
  final ApiResponse<SearchResultResponse> response;
  SearchLoaded(this.response);
}
final class SearchError extends SearchState {
  final String message;
  SearchError(this.message);
}
