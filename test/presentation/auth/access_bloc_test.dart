import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/auth_test_harness.dart';

void main() {
  late MockApiService api;
  late MockFresh fresh;

  setUpAll(registerAuthFallbacks);

  setUp(() async {
    api = MockApiService();
    fresh = MockFresh();
    await registerAuthMocks(api: api, fresh: fresh);
  });

  tearDown(resetAuthLocator);

  test('starts at AccessInitial', () {
    expect(AccessBloc().state, isA<AccessInitial>());
  });

  group('GetMyAccess', () {
    blocTest<AccessBloc, AccessState>(
      'emits [AccessLoading, AccessLoaded] and caches the response on success',
      setUp: () => when(
        () => api.getMyAccess(),
      ).thenAnswer((_) async => apiOk(buildAccess())),
      build: AccessBloc.new,
      act: (bloc) => bloc.add(GetMyAccess()),
      expect: () => [isA<AccessLoading>(), isA<AccessLoaded>()],
      verify: (bloc) {
        expect(bloc.myAccess, isNotNull);
        expect(bloc.myAccess!.data, isA<UserAccessResponse>());
      },
    );

    blocTest<AccessBloc, AccessState>(
      'emits AccessError when the API reports success=false',
      setUp: () => when(
        () => api.getMyAccess(),
      ).thenAnswer((_) async => apiFail<UserAccessResponse>(error: 'denied')),
      build: AccessBloc.new,
      act: (bloc) => bloc.add(GetMyAccess()),
      expect: () => [isA<AccessLoading>(), isA<AccessError>()],
      verify: (bloc) => expect(bloc.myAccess, isNull),
    );

    blocTest<AccessBloc, AccessState>(
      'emits AccessError when a 200 carries a null payload',
      setUp: () => when(
        () => api.getMyAccess(),
      ).thenAnswer((_) async => apiOk<UserAccessResponse>(null)),
      build: AccessBloc.new,
      act: (bloc) => bloc.add(GetMyAccess()),
      expect: () => [isA<AccessLoading>(), isA<AccessError>()],
    );

    blocTest<AccessBloc, AccessState>(
      'KNOWN GAP: a network failure leaves the bloc stuck on AccessLoading',
      setUp: () =>
          when(() => api.getMyAccess()).thenThrow(dioErrorWithoutBody()),
      build: AccessBloc.new,
      act: (bloc) => bloc.add(GetMyAccess()),
      expect: () => [isA<AccessLoading>()],
    );
  });
}
