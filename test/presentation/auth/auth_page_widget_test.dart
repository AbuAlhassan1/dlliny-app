import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/presentation/auth/auth_page_wrapper.dart';
import 'package:hangout/presentation/auth/controller/auth_controller/auth_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc bloc;

  setUpAll(() {
    registerFallbackValue(GoogleSignInRequested());
  });

  setUp(() {
    bloc = MockAuthBloc();
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: Unauthenticated(),
    );
  });

  tearDown(() => bloc.close());

  Widget wrap(AuthBloc authBloc) => MaterialApp(
    theme: Themes.lightTheme,
    home: BlocProvider<AuthBloc>.value(
      value: authBloc,
      child: const AuthPageWrapper(),
    ),
  );

  testWidgets('renders the Google sign-in CTA', (tester) async {
    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(TablerIcons.brand_google_filled), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('does not render the Apple CTA off iOS', (tester) async {
    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byIcon(TablerIcons.brand_apple_filled), findsNothing);
  });

  testWidgets('tapping Google dispatches GoogleSignInRequested', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    await tester.tap(find.byIcon(TablerIcons.brand_google_filled));
    await tester.pump();

    final added = verify(() => bloc.add(captureAny())).captured;
    expect(added.single, isA<GoogleSignInRequested>());
  });

  testWidgets('while loading it shows a spinner and ignores taps', (
    tester,
  ) async {
    whenListen(
      bloc,
      const Stream<AuthState>.empty(),
      initialState: AuthLoading(),
    );

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byIcon(TablerIcons.brand_google_filled), findsNothing);

    await tester.tap(find.byType(InkWell));
    await tester.pump();

    verifyNever(() => bloc.add(any()));
  });

  testWidgets('surfaces a server error message through the global toast', (
    tester,
  ) async {
    final messages = <AppToastMessage>[];
    final sub = appToast.stream.listen(messages.add);
    addTearDown(sub.cancel);

    final controller = StreamController<AuthState>();
    addTearDown(controller.close);
    whenListen(bloc, controller.stream, initialState: Unauthenticated());

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    controller.add(OtpInvalidFromApi(message: 'الرمز غير صحيح'));
    await tester.pump();

    expect(messages, hasLength(1));
    expect(messages.single.text, 'الرمز غير صحيح');
    expect(messages.single.severity, AppToastSeverity.error);
  });

  testWidgets('a generic ApiCallError still raises an error toast', (
    tester,
  ) async {
    final messages = <AppToastMessage>[];
    final sub = appToast.stream.listen(messages.add);
    addTearDown(sub.cancel);

    final controller = StreamController<AuthState>();
    addTearDown(controller.close);
    whenListen(bloc, controller.stream, initialState: Unauthenticated());

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    controller.add(ApiCallError());
    await tester.pump();

    expect(messages, hasLength(1));
    expect(messages.single.severity, AppToastSeverity.error);
  });

  testWidgets('happy-path states raise no toast', (tester) async {
    final messages = <AppToastMessage>[];
    final sub = appToast.stream.listen(messages.add);
    addTearDown(sub.cancel);

    final controller = StreamController<AuthState>();
    addTearDown(controller.close);
    whenListen(bloc, controller.stream, initialState: Unauthenticated());

    await tester.pumpWidget(wrap(bloc));
    await tester.pump(const Duration(seconds: 2));

    controller.add(Authenticated());
    await tester.pump();

    expect(messages, isEmpty);
  });
}
