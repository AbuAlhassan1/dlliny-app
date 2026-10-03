import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

void main() {
  late MockApiService api;

  setUp(() async {
    api = MockApiService();
    await resetLocator();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  group('GetMyHangouts', () {
    blocTest<MyHangoutsBloc, MyHangoutsState>(
      'emits [Loading, Loaded] and exposes the list for the grid',
      setUp: () => when(() => api.getMyHangouts()).thenAnswer(
        (_) async => apiOk([buildHangout(id: 'h1'), buildHangout(id: 'h2')]),
      ),
      build: MyHangoutsBloc.new,
      act: (bloc) => bloc.add(GetMyHangouts()),
      expect: () => [isA<MyHangoutsLoading>(), isA<MyHangoutsLoaded>()],
      verify: (bloc) {
        expect(bloc.myHangouts.map((h) => h.id), ['h1', 'h2']);
      },
    );

    blocTest<MyHangoutsBloc, MyHangoutsState>(
      'emits an error on network failure',
      setUp: () =>
          when(() => api.getMyHangouts()).thenThrow(dioErrorWithoutBody()),
      build: MyHangoutsBloc.new,
      act: (bloc) => bloc.add(GetMyHangouts()),
      expect: () => [isA<MyHangoutsLoading>(), isA<MyHangoutsError>()],
      verify: (bloc) => expect(bloc.myHangouts, isEmpty),
    );

    blocTest<MyHangoutsBloc, MyHangoutsState>(
      'emits an error when the API reports success=false',
      setUp: () => when(() => api.getMyHangouts()).thenAnswer(
        (_) async => apiFail<List<HangoutResponse>>(error: 'boom'),
      ),
      build: MyHangoutsBloc.new,
      act: (bloc) => bloc.add(GetMyHangouts()),
      expect: () => [
        isA<MyHangoutsLoading>(),
        isA<MyHangoutsError>().having(
          (s) => s.message,
          'message',
          contains('boom'),
        ),
      ],
    );
  });

  blocTest<MyHangoutsBloc, MyHangoutsState>(
    'GetMoreHangouts is a no-op — the endpoint returns everything at once',
    build: MyHangoutsBloc.new,
    act: (bloc) => bloc.add(GetMoreHangouts()),
    expect: () => <MyHangoutsState>[],
    verify: (_) => verifyNever(() => api.getMyHangouts()),
  );

  blocTest<MyHangoutsBloc, MyHangoutsState>(
    'ResetMyHangouts clears the list (used on sign-out)',
    setUp: () => when(
      () => api.getMyHangouts(),
    ).thenAnswer((_) async => apiOk([buildHangout()])),
    build: MyHangoutsBloc.new,
    act: (bloc) async {
      bloc.add(GetMyHangouts());
      await Future<void>.delayed(Duration.zero);
      bloc.add(ResetMyHangouts());
    },
    expect: () => [
      isA<MyHangoutsLoading>(),
      isA<MyHangoutsLoaded>(),
      isA<MyHangoutsInitial>(),
    ],
    verify: (bloc) => expect(bloc.myHangouts, isEmpty),
  );
}
