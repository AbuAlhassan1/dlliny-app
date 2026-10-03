import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/dto.dart';

part 'venue_event.dart';
part 'venue_state.dart';

class VenueBloc extends Bloc<VenueEvent, VenueState> {

  ApiService apiService = serviceLocator.get<ApiService>();

  VenueBloc() : super(VenueInitial()) {
    on<VenueEvent>((event, emit) {});
    on<GetVenueDetails>((event, emit) async {
      if (state is! GetVenueDetailsLoaded) emit(GetVenueDetailsLoading());

      void fail(String message) {
        if (state is GetVenueDetailsLoaded) return;
        emit(GetVenueDetailsError(message));
      }

      try {
        final response = await apiService.getVenue(event.id);
        final venue = response.data;
        if (venue != null) {
          emit(GetVenueDetailsLoaded(venue));
        } else {
          fail(response.error ?? 'Failed to load venue details. Please try again later.');
        }
      } on DioException catch (error) {
        final data = error.response?.data;
        fail(
          data is Map && data['error'] is String
              ? data['error'] as String
              : 'An error occurred while fetching venue details.',
        );
      } catch (error, stackTrace) {
        log('GetVenueDetails(${event.id}) failed: $error', stackTrace: stackTrace);
        fail('Failed to load venue details. Please try again later.');
      }
    });
  }
}
