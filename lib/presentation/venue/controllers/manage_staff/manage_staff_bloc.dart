import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/assign_staff_request.dart';
import 'package:hangout/domain/dto/response/staff_response.dart';

part 'manage_staff_event.dart';
part 'manage_staff_state.dart';

class ManageStaffBloc extends Bloc<ManageStaffEvent, ManageStaffState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  List<AssignableVenueRole>? _roles;

  final List<VenueStaffResponse> _staff = [];

  ManageStaffBloc({required this.venueId})
      : super(const ManageStaffInitial()) {
    on<LoadStaff>(_onLoad);
    on<AssignStaffSubmitted>(_onAssign);
    on<RevokeStaffRequested>(_onRevoke);
  }

  Future<List<AssignableVenueRole>> rolesOnce() async {
    final cached = _roles;
    if (cached != null) return cached;
    final res = await _api.listVenueRoles();
    if (!res.success || res.data == null) {
      throw Exception(res.error ?? 'تعذر تحميل الأدوار');
    }
    final fresh = res.data!;
    _roles = fresh;
    return fresh;
  }

  Future<void> _onLoad(
    LoadStaff event,
    Emitter<ManageStaffState> emit,
  ) async {
    emit(const ManageStaffLoading());
    try {
      final res = await _api.listVenueStaff(venueId);
      if (!res.success || res.data == null) {
        emit(ManageStaffError(res.error ?? 'تعذر تحميل الفريق'));
        return;
      }
      _staff
        ..clear()
        ..addAll(res.data!);
      emit(ManageStaffLoaded(List.unmodifiable(_staff)));
    } on DioException catch (e) {
      emit(ManageStaffError(_msg(e, 'تعذر تحميل الفريق')));
    }
  }

  Future<void> _onAssign(
    AssignStaffSubmitted event,
    Emitter<ManageStaffState> emit,
  ) async {
    emit(ManageStaffMutating(List.unmodifiable(_staff)));
    try {
      final res = await _api.assignVenueStaff(
        venueId,
        event.userId,
        AssignVenueStaffRequest(roleId: event.roleId),
      );
      if (!res.success || res.data == null) {
        emit(ManageStaffActionFailed(
          List.unmodifiable(_staff),
          res.error ?? 'تعذر إسناد الدور',
        ));
        return;
      }
      final idx = _staff.indexWhere((s) => s.userId == event.userId);
      if (idx >= 0) {
        _staff[idx] = res.data!;
      } else {
        _staff.insert(0, res.data!);
      }
      emit(ManageStaffActionSucceeded(
        List.unmodifiable(_staff),
        idx >= 0 ? 'تم تحديث الدور' : 'تمت إضافة العضو',
      ));
      emit(ManageStaffLoaded(List.unmodifiable(_staff)));
    } on DioException catch (e) {
      emit(ManageStaffActionFailed(
        List.unmodifiable(_staff),
        _msg(e, 'تعذر إسناد الدور'),
      ));
    }
  }

  Future<void> _onRevoke(
    RevokeStaffRequested event,
    Emitter<ManageStaffState> emit,
  ) async {
    emit(ManageStaffMutating(List.unmodifiable(_staff)));
    try {
      final res = await _api.revokeVenueStaff(venueId, event.userId);
      if (!res.success) {
        emit(ManageStaffActionFailed(
          List.unmodifiable(_staff),
          res.error ?? 'تعذر إزالة العضو',
        ));
        return;
      }
      _staff.removeWhere((s) => s.userId == event.userId);
      emit(ManageStaffActionSucceeded(
        List.unmodifiable(_staff),
        'تمت إزالة العضو',
      ));
      emit(ManageStaffLoaded(List.unmodifiable(_staff)));
    } on DioException catch (e) {
      emit(ManageStaffActionFailed(
        List.unmodifiable(_staff),
        _msg(e, 'تعذر إزالة العضو'),
      ));
    }
  }

  String _msg(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
