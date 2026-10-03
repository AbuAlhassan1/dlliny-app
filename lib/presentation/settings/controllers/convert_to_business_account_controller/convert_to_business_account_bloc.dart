import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/submit_business_request.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'convert_to_business_account_event.dart';
part 'convert_to_business_account_state.dart';

class ConvertToBusinessAccountBloc
    extends Bloc<ConvertToBusinessAccountEvent, ConvertToBusinessAccountState> {
  final ApiService apiService = serviceLocator.get<ApiService>();

  ConvertToBusinessAccountBloc() : super(ConvertToBusinessAccountInitial()) {
    on<ConvertToBusinessAccountEvent>((event, emit) {});

    on<CheckingIfUserHasBusinessAccountRequest>((event, emit) async {
      emit(CheckingRequestLoading());

      ApiResponse<BusinessRequestResponse>? response;

      try {
        response = await apiService.getMyBusinessRequest();
      } on DioException catch (error) {
        if (error.response != null && error.response!.statusCode == 404) {
          emit(CheckingRequestLoaded(requestResponse: null));
          return;
        }
        if (error.response != null && error.response?.data['message'] != null) {
          emit(
            CheckingRequestError(
              error.response?.data['message'] ??
                  'حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً',
            ),
          );
        } else {
          emit(
            CheckingRequestError('حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً'),
          );
        }
      }

      if (response != null) {
        if (response.success) {
          log("User's business request: ${response.data!.toJson()}");
          emit(CheckingRequestLoaded(requestResponse: response.data!));
        } else {
          emit(
            CheckingRequestError(
              response.error ?? 'حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً',
            ),
          );
        }
      } else {
        emit(CheckingRequestError('حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً'));
      }
    });

    on<SendConvertToBusinessAccountRequest>((event, emit) async {
      emit(RequestLoading());

      ApiResponse<BusinessRequestResponse>? response;

      try {
        response = await apiService.submitBusinessRequest(
          SubmitBusinessRequest(
            companyName: event.companyName,
            description: event.description,
          ),
        );
      } on DioException catch (error) {
        if (error.response != null && error.response?.data['message'] != null) {
          emit(
            RequestError(
              error.response?.data['message'] ??
                  'حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً',
            ),
          );
        } else {
          emit(RequestError('حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً'));
        }
      }

      if (response != null) {
        if (response.success) {
          response.data;
          emit(RequestSent(response.data!));
        } else {
          emit(
            RequestError(
              response.error ?? 'حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً',
            ),
          );
        }
      } else {
        emit(RequestError('حدث خطأ غير متوقع، الرجاء المحاولة لاحقاً'));
      }
    });
  }
}
