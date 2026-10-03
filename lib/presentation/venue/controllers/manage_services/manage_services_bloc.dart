import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/network/upload_file_to_s3.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/add_venue_service_request.dart';
import 'package:hangout/domain/dto/request/update_venue_service_request.dart';
import 'package:hangout/domain/dto/response/venue_content_response.dart';
import 'package:hangout/domain/dto/response/venue_service_management_response.dart';

part 'manage_services_event.dart';
part 'manage_services_state.dart';

class ManageServicesBloc
    extends Bloc<ManageServicesEvent, ManageServicesState> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final String venueId;

  List<VenueServiceTypeDto>? _serviceTypes;

  final List<VenueServiceResponse> _services = [];

  ManageServicesBloc({required this.venueId})
      : super(const ManageServicesInitial()) {
    on<LoadMyServices>(_onLoad);
    on<AddServiceSubmitted>(_onAdd);
    on<UpdateServiceSubmitted>(_onUpdate);
    on<DeleteServiceRequested>(_onDelete);
    on<ToggleServiceActiveRequested>(_onToggleActive);
  }

  Future<List<VenueServiceTypeDto>> loadServiceTypesOnce() async {
    final cached = _serviceTypes;
    if (cached != null) return cached;
    final res = await _api.getVenueServiceTypes();
    if (!res.success || res.data == null) {
      throw Exception(res.error ?? 'تعذر تحميل أنواع الخدمات');
    }
    return _serviceTypes = res.data!;
  }

  Future<void> _onLoad(
    LoadMyServices event,
    Emitter<ManageServicesState> emit,
  ) async {
    emit(const ManageServicesLoading());
    try {
      final res = await _api.getMyVenueServices(venueId);
      if (!res.success || res.data == null) {
        emit(ManageServicesError(res.error ?? 'تعذر تحميل الخدمات'));
        return;
      }
      _services
        ..clear()
        ..addAll(res.data!);
      emit(ManageServicesLoaded(List.unmodifiable(_services)));
    } on DioException catch (e) {
      emit(ManageServicesError(_dioMessage(e, 'تعذر تحميل الخدمات')));
    }
  }

  Future<void> _onAdd(
    AddServiceSubmitted event,
    Emitter<ManageServicesState> emit,
  ) async {
    emit(ManageServicesMutating(List.unmodifiable(_services)));
    try {
      String? imageUrl;
      if (event.image != null) {
        imageUrl = await _uploadImage(event.image!);
      }
      final res = await _api.addVenueService(
        venueId,
        AddVenueServiceRequest(
          serviceTypeId: event.serviceTypeId,
          price: event.price,
          imageUrl: imageUrl,
        ),
      );
      if (!res.success || res.data == null) {
        emit(ManageServicesActionFailed(
          List.unmodifiable(_services),
          res.error ?? 'تعذر إضافة الخدمة',
        ));
        return;
      }
      _services.insert(0, res.data!);
      emit(ManageServicesActionSucceeded(
        List.unmodifiable(_services),
        'تمت إضافة الخدمة',
      ));
    } on DioException catch (e) {
      emit(ManageServicesActionFailed(
        List.unmodifiable(_services),
        _dioMessage(e, 'تعذر إضافة الخدمة'),
      ));
    } catch (e) {
      emit(ManageServicesActionFailed(
        List.unmodifiable(_services),
        e.toString(),
      ));
    }
  }

  Future<void> _onUpdate(
    UpdateServiceSubmitted event,
    Emitter<ManageServicesState> emit,
  ) async {
    emit(ManageServicesMutating(List.unmodifiable(_services)));
    try {
      String? imageUrl = event.keepExistingImage ? null : event.clearImage ? '' : null;
      if (event.image != null) {
        imageUrl = await _uploadImage(event.image!);
      }
      final res = await _api.updateVenueService(
        venueId,
        event.serviceId,
        UpdateVenueServiceRequest(
          price: event.price,
          imageUrl: imageUrl,
          active: event.active,
        ),
      );
      if (!res.success || res.data == null) {
        emit(ManageServicesActionFailed(
          List.unmodifiable(_services),
          res.error ?? 'تعذر تحديث الخدمة',
        ));
        return;
      }
      final idx = _services.indexWhere((s) => s.id == event.serviceId);
      if (idx >= 0) {
        _services[idx] = res.data!;
      }
      emit(ManageServicesActionSucceeded(
        List.unmodifiable(_services),
        'تم حفظ التعديلات',
      ));
    } on DioException catch (e) {
      emit(ManageServicesActionFailed(
        List.unmodifiable(_services),
        _dioMessage(e, 'تعذر تحديث الخدمة'),
      ));
    } catch (e) {
      emit(ManageServicesActionFailed(
        List.unmodifiable(_services),
        e.toString(),
      ));
    }
  }

  Future<void> _onDelete(
    DeleteServiceRequested event,
    Emitter<ManageServicesState> emit,
  ) async {
    emit(ManageServicesMutating(List.unmodifiable(_services)));
    try {
      final res = await _api.deleteVenueService(venueId, event.serviceId);
      if (!res.success) {
        emit(ManageServicesActionFailed(
          List.unmodifiable(_services),
          res.error ?? 'تعذر حذف الخدمة',
        ));
        return;
      }
      _services.removeWhere((s) => s.id == event.serviceId);
      emit(ManageServicesActionSucceeded(
        List.unmodifiable(_services),
        'تم حذف الخدمة',
      ));
    } on DioException catch (e) {
      emit(ManageServicesActionFailed(
        List.unmodifiable(_services),
        _dioMessage(e, 'تعذر حذف الخدمة'),
      ));
    }
  }

  Future<void> _onToggleActive(
    ToggleServiceActiveRequested event,
    Emitter<ManageServicesState> emit,
  ) async {
    add(UpdateServiceSubmitted(
      serviceId: event.serviceId,
      active: event.nextActive,
    ));
  }

  Future<String> _uploadImage(File file) async {
    final contentType = _contentTypeFor(file.path);
    if (contentType == null) {
      throw Exception('صيغة صورة غير مدعومة');
    }
    final ApiResponse<ServiceImageUploadResponse> presign =
        await _api.getVenueServiceImageUploadUrl(venueId, contentType);
    if (!presign.success || presign.data == null) {
      throw Exception(presign.error ?? 'تعذر الحصول على رابط الرفع');
    }
    await uploadToS3(presign.data!.uploadUrl, contentType, file);
    return presign.data!.key;
  }

  String? _contentTypeFor(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1) return null;
    switch (path.substring(dot).toLowerCase()) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      default:
        return null;
    }
  }

  String _dioMessage(DioException e, String fallback) {
    final data = e.response?.data;
    if (data is Map && data['error'] is String) return data['error'] as String;
    return e.message ?? fallback;
  }
}
