part of 'search_bloc.dart';

sealed class SearchEvent {}

class Search extends SearchEvent {
  final String query;
  Search(this.query);
}

class ClearSearch extends SearchEvent {}
