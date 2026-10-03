import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';

part 'recent_attended_event.dart';
part 'recent_attended_state.dart';

class RecentAttendedBloc
    extends Bloc<RecentAttendedEvent, RecentAttendedState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  RecentAttendedBloc() : super(const RecentAttendedInitial()) {
    on<LoadRecentAttended>(_onLoad);
  }

  Future<void> _onLoad(
    LoadRecentAttended event,
    Emitter<RecentAttendedState> emit,
  ) async {
    emit(const RecentAttendedLoading());
    try {
      final response = await _api.getMyRecentAttendedHangouts();
      if (!response.success || response.data == null) {
        emit(const RecentAttendedError());
        return;
      }
      final items = response.data!;
      if (items.isEmpty) {
        emit(const RecentAttendedEmpty());
      } else {
        emit(RecentAttendedLoaded(items));
      }
    } on DioException catch (_) {
      emit(const RecentAttendedError());
    } catch (_) {
      emit(const RecentAttendedError());
    }
  }
}
