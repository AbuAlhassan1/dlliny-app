import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_venue_location_request.dart';
import 'package:hangout/domain/dto/request/update_venue_location_request.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';

part 'venue_branches_event.dart';
part 'venue_branches_state.dart';

class VenueBranchesBloc
    extends Bloc<VenueBranchesEvent, VenueBranchesState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  List<VenueLocationResponse> branches = [];

  VenueBranchesBloc({required this.venueId})
      : super(const VenueBranchesInitial()) {
    on<LoadVenueBranches>(_onLoad);
    on<CreateVenueBranch>(_onCreate);
    on<UpdateVenueBranch>(_onUpdate);
    on<DeleteVenueBranch>(_onDelete);
  }

  Future<void> _onLoad(
    LoadVenueBranches event,
    Emitter<VenueBranchesState> emit,
  ) async {
    emit(const VenueBranchesLoading());
    try {
      final response = await _api.getBusinessVenueLocations(venueId);
      if (!response.success || response.data == null) {
        emit(VenueBranchesError(response.error ?? 'تعذر تحميل الفروع'));
        return;
      }
      branches = response.data!;
      emit(const VenueBranchesLoaded());
    } on DioException catch (e) {
      emit(VenueBranchesError(_dioMessage(e, 'تعذر تحميل الفروع')));
    } catch (_) {
      emit(const VenueBranchesError('تعذر تحميل الفروع'));
    }
  }

  Future<void> _onCreate(
    CreateVenueBranch event,
    Emitter<VenueBranchesState> emit,
  ) async {
    emit(const VenueBranchOperating());
    try {
      final response = await _api.addVenueLocation(venueId, event.request);
      if (!response.success) {
        emit(VenueBranchOperationError(
          response.error ?? 'تعذر إضافة الفرع',
        ));
        return;
      }
      await _refresh();
      emit(const VenueBranchOperated());
      emit(const VenueBranchesLoaded());
    } on DioException catch (e) {
      emit(VenueBranchOperationError(_dioMessage(e, 'تعذر إضافة الفرع')));
    } catch (_) {
      emit(const VenueBranchOperationError('تعذر إضافة الفرع'));
    }
  }

  Future<void> _onUpdate(
    UpdateVenueBranch event,
    Emitter<VenueBranchesState> emit,
  ) async {
    emit(const VenueBranchOperating());
    try {
      final response = await _api.updateVenueLocation(
        venueId,
        event.locationId,
        event.request,
      );
      if (!response.success) {
        emit(VenueBranchOperationError(
          response.error ?? 'تعذر تحديث الفرع',
        ));
        return;
      }
      await _refresh();
      emit(const VenueBranchOperated());
      emit(const VenueBranchesLoaded());
    } on DioException catch (e) {
      emit(VenueBranchOperationError(_dioMessage(e, 'تعذر تحديث الفرع')));
    } catch (_) {
      emit(const VenueBranchOperationError('تعذر تحديث الفرع'));
    }
  }

  Future<void> _onDelete(
    DeleteVenueBranch event,
    Emitter<VenueBranchesState> emit,
  ) async {
    emit(const VenueBranchOperating());
    try {
      final response =
          await _api.deleteVenueLocation(venueId, event.locationId);
      if (!response.success) {
        emit(VenueBranchOperationError(
          response.error ?? 'تعذر حذف الفرع',
        ));
        return;
      }
      branches = branches
          .where((b) => b.id != event.locationId)
          .toList(growable: false);
      emit(const VenueBranchesLoaded());
      await _refresh();
      emit(const VenueBranchOperated());
      emit(const VenueBranchesLoaded());
    } on DioException catch (e) {
      emit(VenueBranchOperationError(_dioMessage(e, 'تعذر حذف الفرع')));
    } catch (_) {
      emit(const VenueBranchOperationError('تعذر حذف الفرع'));
    }
  }

  Future<void> _refresh() async {
    final response = await _api.getBusinessVenueLocations(venueId);
    if (response.success && response.data != null) {
      branches = response.data!;
    }
  }

  String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return fallback;
  }
}
