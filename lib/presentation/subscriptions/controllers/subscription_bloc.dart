import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/business_response.dart';

part 'subscription_event.dart';
part 'subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<MySubscriptionResponse> _cache = const [];

  SubscriptionBloc() : super(const SubscriptionInitial()) {
    on<LoadMySubscriptions>(_onLoad);
  }

  bool has(String permission) =>
      _cache.any((s) => s.permissions.contains(permission));

  bool get isSubscriber => _cache.isNotEmpty;

  MySubscriptionResponse? get primary {
    if (_cache.isEmpty) return null;
    return _cache.firstWhere(
      (s) => s.primary,
      orElse: () => _cache.first,
    );
  }

  String? get primaryTierName => primary?.tierName;

  List<String> get primaryPermissions =>
      primary?.permissions ?? const <String>[];

  Future<void> _onLoad(
    LoadMySubscriptions event,
    Emitter<SubscriptionState> emit,
  ) async {
    emit(const SubscriptionLoading());
    try {
      final response = await _api.getMySubscriptions();
      if (!response.success || response.data == null) {
        _emitFailure(emit, response.error ?? 'تعذر تحميل الاشتراك');
        return;
      }
      _cache = response.data!;
      emit(SubscriptionLoaded(_cache));
    } on DioException catch (e) {
      _emitFailure(emit, e.message ?? 'تعذر تحميل الاشتراك');
    } catch (e) {
      _emitFailure(emit, 'تعذر تحميل الاشتراك');
    }
  }

  void _emitFailure(Emitter<SubscriptionState> emit, String message) {
    if (_cache.isNotEmpty) {
      emit(SubscriptionStale(subs: _cache, message: message));
    } else {
      emit(SubscriptionError(message));
    }
  }
}
