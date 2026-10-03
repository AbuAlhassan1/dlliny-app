import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:fresh_dio/fresh_dio.dart';

class AuthLocalDataSource implements TokenStorage<OAuth2Token> {
  final _storage = const FlutterSecureStorage();

  @override
  Future<void> write(OAuth2Token token) async {
    await _storage.write(key: 'jwt', value: token.accessToken);
    await _storage.write(key: 'refresh', value: token.refreshToken);
  }

  @override
  Future<OAuth2Token?> read() async {
    final access = await _storage.read(key: 'jwt');
    final refresh = await _storage.read(key: 'refresh');
    if (access == null) return null;
    return OAuth2Token(accessToken: access, refreshToken: refresh);
  }

  @override
  Future<void> delete() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'refresh');
  }
}