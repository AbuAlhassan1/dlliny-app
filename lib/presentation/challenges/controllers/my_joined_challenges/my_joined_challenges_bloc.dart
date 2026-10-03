import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/challenge_list_item_response.dart';

part 'my_joined_challenges_event.dart';
part 'my_joined_challenges_state.dart';

class MyJoinedChallengesBloc
    extends Bloc<MyJoinedChallengesEvent, MyJoinedChallengesState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  List<ChallengeListItemResponse> _items = const [];

  MyJoinedChallengesBloc() : super(const MyJoinedChallengesInitial()) {
    on<MyJoinedChallengesEvent>((event, emit) {});

    on<LoadMyJoinedChallenges>((event, emit) async {
      emit(MyJoinedChallengesLoading(items: _items));

      ApiResponse<List<ChallengeListItemResponse>> response;
      try {
        response = await apiService.getMyJoinedChallenges();
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(MyJoinedChallengesError('Failed to load', items: _items));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _items = response.data!;
        emit(MyJoinedChallengesLoaded(items: _items));
      } else {
        emit(MyJoinedChallengesError(
          response.error ?? 'Failed to load',
          items: _items,
        ));
      }
    });
  }
}
