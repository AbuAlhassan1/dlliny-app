import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:hangout/data/api/api_service.dart';
import '../../data/data_sources/auth_local_data_source.dart';

final fresh = Fresh.oAuth2(
  tokenStorage: serviceLocator.get<AuthLocalDataSource>(),
  tokenHeader: (token) {
    return {'Authorization': 'Bearer ${token.accessToken}'};
  },
  refreshToken: (token, client) async {
    if (kDebugMode) log("refreshing token...");

    try {
      final response = await serviceLocator
          .get<ApiService>()
          .refreshToken(token!.refreshToken!);
      return OAuth2Token(
        accessToken: response.data!.accessToken,
        refreshToken: response.data!.refreshToken,
      );
    } on DioException catch (e) {
      if (isRefreshRejected(e)) throw RevokeTokenException();
      rethrow;
    }
  },
  shouldRefresh: shouldRefreshToken,
);

@visibleForTesting
bool isRefreshRejected(DioException e) {
  final status = e.response?.statusCode;
  if (status == null) return false;
  if (status == 408 || status == 429) return false;
  return status >= 400 && status < 500;
}

@visibleForTesting
bool shouldRefreshToken(Response? response) {
  final status = response?.statusCode;
  if (status == 401) return true;
  if (status != 403) return false;

  final header = response!.requestOptions.headers.entries
      .firstWhere(
        (e) => e.key.toLowerCase() == 'authorization',
        orElse: () => const MapEntry('', null),
      )
      .value;
  if (header is! String || !header.startsWith('Bearer ')) return false;

  try {
    return JwtDecoder.isExpired(header.substring('Bearer '.length));
  } catch (_) {
    return true;
  }
}

final dio = Dio(
  BaseOptions(followRedirects: false)
)..interceptors.add(fresh)
  ..interceptors.addAll(kDebugMode ? [_SanitizingLogInterceptor()] : const []);

class _SanitizingLogInterceptor extends Interceptor {
  static const _replacement = '�';

  static const _sensitiveHeaders = {
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'proxy-authorization',
  };

  String _scrub(Object? body) {
    final s = body?.toString() ?? '';
    if (!s.contains(_replacement)) return s;
    return s.replaceAll(_replacement, '[?]');
  }

  Map<String, dynamic> _safeHeaders(Map<String, dynamic> headers) {
    return {
      for (final e in headers.entries)
        e.key: _sensitiveHeaders.contains(e.key.toLowerCase())
            ? '[REDACTED]'
            : e.value,
    };
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    log('*** Request *** ${options.method} ${options.uri}');
    if (options.headers.isNotEmpty) {
      log('headers: ${_safeHeaders(options.headers)}');
    }
    if (options.data != null) log('data: ${_scrub(options.data)}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    log('*** Response *** ${response.statusCode} ${response.requestOptions.uri}');
    log('body: ${_scrub(response.data)}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    log('*** Error *** ${err.requestOptions.method} ${err.requestOptions.uri}');
    log('message: ${err.message}');
    if (err.response != null) {
      log('status: ${err.response?.statusCode}');
      log('body: ${_scrub(err.response?.data)}');
    }
    handler.next(err);
  }
}
