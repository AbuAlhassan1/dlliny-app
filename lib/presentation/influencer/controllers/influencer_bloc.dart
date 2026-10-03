import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';

part 'influencer_event.dart';
part 'influencer_state.dart';

class InfluencerBloc extends Bloc<InfluencerEvent, InfluencerState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  bool _enabled = false;

  InfluencerBloc() : super(const InfluencerReady(enabled: false)) {
    on<InfluencerEvent>((event, emit) {});

    on<ToggleInfluencer>((event, emit) async {
      final target = event.enable;
      if (target == _enabled) return;
      emit(InfluencerUpdating(enabled: _enabled, target: target));

      ApiResponse<UserDto> response;
      try {
        response = target
            ? await apiService.enableInfluencer()
            : await apiService.disableInfluencer();
      } on DioException catch (_) {
        if (emit.isDone) return;
        emit(InfluencerError('Failed to update', enabled: _enabled));
        return;
      }
      if (emit.isDone) return;

      if (response.success) {
        _enabled = target;
        emit(InfluencerReady(enabled: _enabled));
      } else {
        emit(InfluencerError(
          response.error ?? 'Failed to update',
          enabled: _enabled,
        ));
      }
    });
  }
}
