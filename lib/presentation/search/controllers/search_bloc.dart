import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/search_response.dart';

part 'search_event.dart';
part 'search_state.dart';

class SearchBloc extends Bloc<SearchEvent, SearchState> {

  final ApiService apiService = serviceLocator.get<ApiService>();

  SearchBloc() : super(SearchInitial()) {
    on<Search>((event, emit) async {
      emit(SearchLoading());

      final ApiResponse<SearchResultResponse> response;

      try {
        response = await apiService.search(event.query);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(SearchError("حدث خطأ أثناء البحث. الرجاء المحاولة مرة أخرى."));
        return;
      }
      if (emit.isDone) return;

      if (!response.success || response.data == null) {
        emit(SearchError(response.error ?? "حدث خطأ غير معروف أثناء البحث."));
        return;
      }

      emit(SearchLoaded(response));
    });

    on<ClearSearch>((event, emit) => emit(SearchInitial()));
  }
}
