import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/domain/dto/response/venue_gallery_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';
import 'package:hangout/presentation/venue/controllers/venue_controller/venue_bloc.dart';
import 'package:hangout/presentation/venue/manage_venue_page_wrapper.dart';
import 'package:hangout/presentation/venue/pages/venue_gallery_manager_page.dart';
import 'package:hangout/presentation/venue/pages/venue_hours_editor_page.dart';
import 'package:hangout/presentation/venue/utils/access_helpers.dart';
import 'package:hangout/presentation/venue/widgets/gallery/venue_gallery_preview.dart';
import 'package:hangout/presentation/venue/widgets/hours/venue_hours_card.dart';
import 'package:hangout/presentation/venue/widgets/venue_about_section.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/test_harness.dart';

class FakeVenueBloc extends MockBloc<VenueEvent, VenueState>
    implements VenueBloc {}

const _venue = VenueResponse(
  id: 'venue-1',
  nameAr: 'مقهى',
  nameEn: 'Cafe',
  avgRating: 0,
  totalRatings: 0,
  followerCount: 0,
  verified: false,
  family: false,
  hasShisha: false,
  hasParking: false,
  hasWifi: false,
  hasOutdoor: false,
  hasPrivateRoom: false,
  hours: [],
  mediaUrls: [],
);

AccessBloc _accessWith(List<String> perms) => AccessBloc()
  ..myAccess = apiOk(
    UserAccessResponse(
      businesses: const [],
      orphanVenues: [
        VenueAccess(
          venueId: 'venue-1',
          nameAr: 'مقهى',
          active: true,
          verified: false,
          venuePermissions: perms,
          effectivePermissions: perms,
        ),
      ],
    ),
  );

void main() {
  late FakeVenueBloc venueBloc;

  setUp(() async {
    await resetLocator();
    putSingleton<ApiService>(MockApiService());
    venueBloc = FakeVenueBloc();
  });

  tearDown(resetLocator);

  Widget host(Widget child, {List<String> perms = const []}) =>
      MultiBlocProvider(
        providers: [
          BlocProvider<AccessBloc>.value(value: _accessWith(perms)),
          BlocProvider<VenueBloc>.value(value: venueBloc),
        ],
        child: MaterialApp(
          theme: Themes.lightTheme,
          home: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      );

  group('VenueAboutSection', () {
    testWidgets('renders nothing until the venue is loaded', (tester) async {
      when(() => venueBloc.state).thenReturn(VenueInitial());
      await tester.pumpWidget(host(const VenueAboutSection()));
      expect(find.byType(VenueHoursCard), findsNothing);
      expect(find.byType(VenueGalleryPreview), findsNothing);
    });

    testWidgets(
      'hosts the hours card and the gallery preview; visitors see no entry',
      (tester) async {
        when(() => venueBloc.state).thenReturn(GetVenueDetailsLoaded(_venue));
        await tester.pumpWidget(host(const VenueAboutSection()));
        expect(find.byType(VenueHoursCard), findsOneWidget);
        expect(find.byType(VenueGalleryPreview), findsOneWidget);
        expect(find.byIcon(TablerIcons.photo), findsNothing);
      },
    );

    testWidgets(
      'staff (media upload, no venue:update) reach the gallery manager',
      (tester) async {
        when(
          () => venueBloc.state,
        ).thenReturn(GetVenueDetailsLoaded(_venueWithEmptyGallery));
        await tester.pumpWidget(
          host(
            const VenueAboutSection(),
            perms: const ['venue:read', VenuePerm.mediaUpload],
          ),
        );
        expect(find.byIcon(TablerIcons.photo), findsOneWidget);

        await tester.tap(find.byIcon(TablerIcons.photo));
        await tester.pumpAndSettle();
        final page = tester.widget<VenueGalleryManagerPage>(
          find.byType(VenueGalleryManagerPage),
        );
        expect(page.venueId, 'venue-1');
      },
    );
  });

  group('Manage hub tiles', () {
    Future<void> pumpHub(WidgetTester tester, List<String> perms) async {
      when(() => venueBloc.state).thenReturn(GetVenueDetailsLoaded(_venue));
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AccessBloc>.value(value: _accessWith(perms)),
            BlocProvider<VenueBloc>.value(value: venueBloc),
          ],
          child: MaterialApp(
            theme: Themes.lightTheme,
            home: const ManageVenuePageWrapper(venue: _venue),
          ),
        ),
      );
    }

    testWidgets(
      'hours tile is gated by venue:hours:manage and opens the editor',
      (tester) async {
        await pumpHub(tester, const [VenuePerm.update, VenuePerm.hoursManage]);
        expect(find.byIcon(TablerIcons.clock), findsOneWidget);

        await tester.tap(find.byIcon(TablerIcons.clock));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<VenueHoursEditorPage>(find.byType(VenueHoursEditorPage))
              .venueId,
          'venue-1',
        );
      },
    );

    testWidgets('no hours or gallery tile without the permissions', (
      tester,
    ) async {
      await pumpHub(tester, const [VenuePerm.update]);
      expect(find.byIcon(TablerIcons.clock), findsNothing);
      expect(find.byIcon(TablerIcons.photo), findsNothing);
    });

    testWidgets(
      'gallery tile is gated by venue:media:upload and opens the manager',
      (tester) async {
        await pumpHub(tester, const [VenuePerm.update, VenuePerm.mediaUpload]);
        expect(find.byIcon(TablerIcons.clock), findsNothing);
        expect(find.byIcon(TablerIcons.photo), findsOneWidget);

        await tester.tap(find.byIcon(TablerIcons.photo));
        await tester.pumpAndSettle();
        expect(find.byType(VenueGalleryManagerPage), findsOneWidget);
      },
    );
  });
}

final _venueWithEmptyGallery = VenueResponse(
  id: _venue.id,
  nameAr: _venue.nameAr,
  nameEn: _venue.nameEn,
  avgRating: 0,
  totalRatings: 0,
  followerCount: 0,
  verified: false,
  family: false,
  hasShisha: false,
  hasParking: false,
  hasWifi: false,
  hasOutdoor: false,
  hasPrivateRoom: false,
  hours: const [],
  mediaUrls: const [],
  gallery: const VenueGalleryDto(),
);
