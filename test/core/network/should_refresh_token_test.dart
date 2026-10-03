import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/network/dio_factory.dart';

String _jwt({required Duration expiresIn}) {
  String part(Map<String, dynamic> json) =>
      base64Url.encode(utf8.encode(jsonEncode(json))).replaceAll('=', '');
  final exp = DateTime.now().add(expiresIn).millisecondsSinceEpoch ~/ 1000;
  return '${part({'alg': 'RS256', 'typ': 'JWT'})}.${part({'sub': 'u1', 'exp': exp})}.sig';
}

Response _response(int status, {String? bearer}) => Response(
      statusCode: status,
      requestOptions: RequestOptions(
        path: '/api/v1/users/me',
        headers: {if (bearer != null) 'Authorization': 'Bearer $bearer'},
      ),
    );

void main() {
  final valid = _jwt(expiresIn: const Duration(minutes: 10));
  final expired = _jwt(expiresIn: const Duration(minutes: -10));

  test('refreshes on 401', () {
    expect(shouldRefreshToken(_response(401, bearer: valid)), isTrue);
  });

  test('does not refresh on 403 when the sent token is still valid', () {
    expect(shouldRefreshToken(_response(403, bearer: valid)), isFalse);
  });

  test('refreshes on 403 when the sent token has expired', () {
    expect(shouldRefreshToken(_response(403, bearer: expired)), isTrue);
  });

  test('refreshes on 403 when the sent token is unparseable', () {
    expect(shouldRefreshToken(_response(403, bearer: 'garbage')), isTrue);
  });

  test('does not refresh on 403 for unauthenticated requests', () {
    expect(shouldRefreshToken(_response(403)), isFalse);
  });

  test('does not refresh on other statuses or missing responses', () {
    expect(shouldRefreshToken(_response(500, bearer: expired)), isFalse);
    expect(shouldRefreshToken(null), isFalse);
  });

  group('isRefreshRejected', () {
    DioException failure({int? status}) => DioException(
          requestOptions: RequestOptions(path: '/api/v1/auth/token/refresh'),
          response: status == null
              ? null
              : Response(
                  statusCode: status,
                  requestOptions:
                      RequestOptions(path: '/api/v1/auth/token/refresh'),
                ),
          type: status == null
              ? DioExceptionType.connectionError
              : DioExceptionType.badResponse,
        );

    test('client errors end the session (dead token, banned account)', () {
      for (final status in [400, 401, 403, 404]) {
        expect(isRefreshRejected(failure(status: status)), isTrue,
            reason: 'HTTP $status');
      }
    });

    test('transient failures keep the session', () {
      for (final status in [408, 429, 500, 502, 503]) {
        expect(isRefreshRejected(failure(status: status)), isFalse,
            reason: 'HTTP $status');
      }
      expect(isRefreshRejected(failure()), isFalse, reason: 'no response');
    });
  });
}
