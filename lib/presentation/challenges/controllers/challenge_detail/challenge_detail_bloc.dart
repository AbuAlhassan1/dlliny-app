import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/challenge_detail_response.dart';

part 'challenge_detail_event.dart';
part 'challenge_detail_state.dart';

class ChallengeDetailBloc extends Bloc<ChallengeDetailEvent, ChallengeDetailState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  ChallengeDetailResponse? _detail;
  String? _challengeId;

  ChallengeDetailBloc() : super(const ChallengeDetailInitial()) {
    on<ChallengeDetailEvent>((event, emit) {});

    on<LoadChallengeDetail>((event, emit) async {
      _challengeId = event.challengeId;
      emit(ChallengeDetailLoading(detail: _detail));
      await _fetch(emit);
    });

    on<RefreshChallengeDetail>((event, emit) async {
      if (_challengeId == null) return;
      await _fetch(emit);
    });

    on<JoinCurrentChallenge>((event, emit) async {
      final id = _challengeId;
      if (id == null) return;
      emit(ChallengeJoining(detail: _detail));

      ApiResponse<ChallengeDetailResponse> response;
      try {
        response = await apiService.joinChallenge(id);
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(ChallengeJoinError('Failed to join', detail: _detail));
        return;
      }
      if (emit.isDone) return;

      if (response.success && response.data != null) {
        _detail = response.data;
        emit(ChallengeJoined(detail: _detail));
        emit(ChallengeDetailLoaded(detail: _detail));
      } else {
        emit(ChallengeJoinError(
          response.error ?? 'Failed to join',
          detail: _detail,
        ));
      }
    });
  }

  Future<void> _fetch(Emitter<ChallengeDetailState> emit) async {
    final id = _challengeId;
    if (id == null) return;

    ApiResponse<ChallengeDetailResponse> response;
    try {
      response = await apiService.getChallengeDetail(id);
    } on DioException catch (_) {
      if (emit.isDone) return;
      emit(ChallengeDetailError('Failed to load', detail: _detail));
      return;
    }
    if (emit.isDone) return;

    if (response.success && response.data != null) {
      _detail = response.data;
      emit(ChallengeDetailLoaded(detail: _detail));
    } else {
      emit(ChallengeDetailError(
        response.error ?? 'Failed to load',
        detail: _detail,
      ));
    }
  }
}
