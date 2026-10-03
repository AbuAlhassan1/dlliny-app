import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:intl/intl.dart';

class ReelApiService {
  final ApiService _api = serviceLocator.get<ApiService>();

  Future<void> like(String postId) => _api.likePost(postId);

  Future<void> unlike(String postId) => _api.unlikePost(postId);
}

class ReelFormatter {
  final NumberFormat _impl = NumberFormat.compact();
  String compact(int n) => _impl.format(n);
}
