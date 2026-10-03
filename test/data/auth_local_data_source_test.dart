import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fresh_dio/fresh_dio.dart';
import 'package:hangout/data/data_sources/auth_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AuthLocalDataSource storage;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    storage = AuthLocalDataSource();
  });

  test('read returns null when nothing has been stored', () async {
    expect(await storage.read(), isNull);
  });

  test('write then read round-trips both tokens', () async {
    await storage.write(
      const OAuth2Token(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );

    final token = await storage.read();

    expect(token, isNotNull);
    expect(token!.accessToken, 'access-1');
    expect(token.refreshToken, 'refresh-1');
  });

  test('read yields null when the access token is missing', () async {
    FlutterSecureStorage.setMockInitialValues({'refresh': 'orphan-refresh'});

    expect(await AuthLocalDataSource().read(), isNull);
  });

  test('delete clears the session', () async {
    await storage.write(
      const OAuth2Token(accessToken: 'access-1', refreshToken: 'refresh-1'),
    );
    expect(await storage.read(), isNotNull);

    await storage.delete();

    expect(await storage.read(), isNull);
  });

  test('a later write overwrites the previous session', () async {
    await storage.write(
      const OAuth2Token(accessToken: 'old', refreshToken: 'old-r'),
    );
    await storage.write(
      const OAuth2Token(accessToken: 'new', refreshToken: 'new-r'),
    );

    final token = await storage.read();

    expect(token!.accessToken, 'new');
    expect(token.refreshToken, 'new-r');
  });
}
