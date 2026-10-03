import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_business_venue_request.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'create_venue_event.dart';
part 'create_venue_state.dart';

class CreateVenueBloc extends Bloc<CreateVenueEvent, CreateVenueState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  CreateVenueBloc() : super(CreateVenueInitial()) {
    on<CreateVenueEvent>((event, emit) {});

    on<CreateVenue>((event, emit) async {
      emit(CreateVenueLoading());

      try {
        final response = await apiService.createBusinessVenue(
          event.businessId,
          event.request,
        );
        if (response.data != null) {
          emit(CreateVenueSuccess(response.data!));
        } else {
          emit(CreateVenueError(
            response.error ??
                'فشل إنشاء الفرع. الرجاء المحاولة مرة أخرى لاحقًا.',
          ));
        }
      } on DioException catch (error) {
        emit(CreateVenueError(_mapError(error, event.request.handle)));
      }
    });
  }

  String _mapError(DioException e, String? attemptedHandle) {
    final data = e.response?.data;
    final serverMsg = (data is Map && data['error'] is String)
        ? data['error'] as String
        : null;
    final status = e.response?.statusCode;
    final triedHandle = attemptedHandle != null && attemptedHandle.isNotEmpty;
    final translated = _translateKnownServerMessage(serverMsg);
    if (translated != null) return translated;
    switch (status) {
      case 409:
        return serverMsg ??
            (triedHandle
                ? 'هذا المعرّف غير متاح'
                : 'حدث تعارض. الرجاء المحاولة مرة أخرى لاحقًا.');
      case 400:
        return serverMsg ?? 'بعض الحقول غير صالحة';
      default:
        return serverMsg ??
            'حدث خطأ أثناء إنشاء الفرع. الرجاء المحاولة مرة أخرى لاحقًا.';
    }
  }

  String? _translateKnownServerMessage(String? msg) {
    if (msg == null || msg.isEmpty) return null;
    final m = msg.toLowerCase();
    if (m.contains('latitude') && m.contains('longitude') &&
        m.contains('physical')) {
      return 'اختر موقع المكان على الخريطة قبل المتابعة';
    }
    return null;
  }
}
