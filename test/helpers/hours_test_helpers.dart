import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/user_access_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/auth/controller/access_controller/access_bloc.dart';

import 'test_harness.dart';

class _AnyLocaleMaterial extends LocalizationsDelegate<MaterialLocalizations> {
  const _AnyLocaleMaterial();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<MaterialLocalizations> load(Locale locale) =>
      DefaultMaterialLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleMaterial old) => false;
}

class _AnyLocaleCupertino
    extends LocalizationsDelegate<CupertinoLocalizations> {
  const _AnyLocaleCupertino();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<CupertinoLocalizations> load(Locale locale) =>
      DefaultCupertinoLocalizations.load(locale);
  @override
  bool shouldReload(_AnyLocaleCupertino old) => false;
}

class _RtlWidgetsLocalizations extends DefaultWidgetsLocalizations {
  const _RtlWidgetsLocalizations();
  @override
  TextDirection get textDirection => TextDirection.rtl;
}

class _DirectionalWidgets extends LocalizationsDelegate<WidgetsLocalizations> {
  const _DirectionalWidgets();
  @override
  bool isSupported(Locale locale) => true;
  @override
  Future<WidgetsLocalizations> load(Locale locale) =>
      SynchronousFuture<WidgetsLocalizations>(
        locale.languageCode == 'ar'
            ? const _RtlWidgetsLocalizations()
            : const DefaultWidgetsLocalizations(),
      );
  @override
  bool shouldReload(_DirectionalWidgets old) => false;
}

Widget hoursTestApp(
  Widget home, {
  String locale = 'ar',
  List<BlocProvider> providers = const [],
  ThemeData? theme,
}) {
  final app = MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme ?? Themes.lightTheme,
    locale: Locale(locale),
    supportedLocales: const [Locale('ar'), Locale('en')],
    localizationsDelegates: const [
      _AnyLocaleMaterial(),
      _AnyLocaleCupertino(),
      _DirectionalWidgets(),
    ],
    home: home,
  );
  return providers.isEmpty
      ? app
      : MultiBlocProvider(providers: providers, child: app);
}

AccessBloc accessWith(List<String> perms, {String venueId = 'venue-1'}) =>
    AccessBloc()
      ..myAccess = apiOk(
        UserAccessResponse(
          businesses: const [],
          orphanVenues: [
            VenueAccess(
              venueId: venueId,
              nameAr: 'مقهى',
              active: true,
              verified: false,
              venuePermissions: perms,
              effectivePermissions: perms,
            ),
          ],
        ),
      );

HoursMomentDto moment(
  String time, {
  int dayOffset = 0,
  int dayOfWeek = 1,
  String date = '2026-09-28',
}) => HoursMomentDto(
  at: '${date}T$time:00+03:00',
  localTime: time,
  localDate: date,
  dayOfWeek: dayOfWeek,
  dayOffset: dayOffset,
);

HoursIntervalDto iv(String opens, String closes) => HoursIntervalDto(
  opens: opens,
  closes: closes,
  overnight: closes.compareTo(opens) <= 0,
);

DayScheduleDto hoursDay(int dow, List<HoursIntervalDto> intervals) =>
    DayScheduleDto(
      dayOfWeek: dow,
      kind: HoursDayKind.hours,
      intervals: intervals,
    );

DayScheduleDto closedDay(int dow) => DayScheduleDto(dayOfWeek: dow);

DayScheduleDto allDay(int dow) =>
    DayScheduleDto(dayOfWeek: dow, kind: HoursDayKind.open24h);

WeeklyScheduleDto week(
  List<HoursIntervalDto> intervals, {
  Map<int, DayScheduleDto> except = const {},
}) => WeeklyScheduleDto(
  days: [for (var d = 0; d < 7; d++) except[d] ?? hoursDay(d, intervals)],
);

WeeklyScheduleDto fixtureA() => WeeklyScheduleDto(
  days: [
    hoursDay(0, [iv('08:00', '12:00'), iv('16:00', '23:00')]),
    hoursDay(1, [iv('18:00', '00:00')]),
    allDay(2),
    hoursDay(3, [iv('20:00', '03:00')]),
    hoursDay(4, [iv('18:00', '03:00')]),
    closedDay(5),
    hoursDay(6, [iv('09:00', '17:00')]),
  ],
);

TodayHoursDto todayOf(
  String date,
  int dow, {
  HoursDayKind kind = HoursDayKind.hours,
  List<HoursIntervalDto> intervals = const [],
  List<HoursIntervalDto> eve = const [],
  HoursSeason season = HoursSeason.regular,
}) => TodayHoursDto(
  date: date,
  dayOfWeek: dow,
  season: season,
  kind: kind,
  intervals: intervals,
  ramadanEveIntervals: eve,
);

ScopeHoursDto scopeOf(
  OpenStatusDto status, {
  String? locationId,
  TodayHoursDto? today,
  TodayHoursDto? lastNight,
  WeeklyScheduleDto? regular,
  WeeklyScheduleDto? ramadan,
  HoursSource hoursSource = HoursSource.venue,
  HoursSource statusSource = HoursSource.venue,
  String? hoursUpdatedAt = '2026-09-20T10:12:44Z',
}) => ScopeHoursDto(
  locationId: locationId,
  hoursSource: hoursSource,
  statusSource: statusSource,
  status: status,
  today: today,
  lastNight: lastNight,
  regular: regular,
  ramadan: ramadan,
  hoursUpdatedAt: hoursUpdatedAt,
);

VenueOpeningHoursDto openingHoursOf(
  ScopeHoursDto summary, {
  List<ScopeHoursDto> branches = const [],
  RamadanWindowDto? window,
  String evaluatedAt = '2026-09-28T21:40:00+03:00',
}) => VenueOpeningHoursDto(
  timezone: 'Asia/Baghdad',
  evaluatedAt: evaluatedAt,
  ramadanWindow: window,
  summary: summary,
  branches: branches,
);

VenueResponse venueWithHours(
  VenueOpeningHoursDto? hours, {
  String id = 'venue-1',
  List<VenueLocationResponse> locations = const [],
}) => VenueResponse(
  id: id,
  nameAr: 'مقهى الشناشيل',
  nameEn: 'Shanasheel',
  avgRating: 4.5,
  totalRatings: 12,
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
  openingHours: hours,
  locations: locations,
);

const OpenStatusDto kOpenStatus = OpenStatusDto(
  state: OpenState.open,
  openNow: true,
);

EditableScopeHoursDto venueScope({
  WeeklyScheduleDto? regular,
  WeeklyScheduleDto? ramadan,
  String status = 'OPEN',
  String? reopensOn,
  bool statusExpired = false,
}) => EditableScopeHoursDto(
  hoursMode: 'OWN',
  statusMode: 'OWN',
  operatingStatus: status,
  reopensOn: reopensOn,
  statusExpired: statusExpired,
  regular: regular,
  ramadan: ramadan,
  effectiveStatus: kOpenStatus,
);

EditableScopeHoursDto branchScope(
  String id, {
  String? labelAr,
  String? districtNameAr,
  bool isPrimary = false,
  bool ownHours = false,
  bool ownStatus = false,
  WeeklyScheduleDto? regular,
  WeeklyScheduleDto? ramadan,
  String? status,
  String? reopensOn,
}) => EditableScopeHoursDto(
  locationId: id,
  labelAr: labelAr,
  districtNameAr: districtNameAr,
  isPrimary: isPrimary,
  hoursMode: ownHours ? 'OWN' : 'INHERIT',
  statusMode: ownStatus ? 'OWN' : 'INHERIT',
  operatingStatus: ownStatus ? (status ?? 'OPEN') : null,
  reopensOn: ownStatus ? reopensOn : null,
  regular: ownHours ? regular : null,
  ramadan: ownHours ? ramadan : null,
  effectiveStatus: kOpenStatus,
);

BusinessVenueHoursResponse editorModel({
  EditableScopeHoursDto? venue,
  List<EditableScopeHoursDto> branches = const [],
  String today = '2026-09-28',
  RamadanWindowDto? window,
}) => BusinessVenueHoursResponse(
  venueId: 'venue-1',
  timezone: 'Asia/Baghdad',
  evaluatedAt: '${today}T21:40:00+03:00',
  today: today,
  ramadanWindow: window,
  venue: venue ?? venueScope(),
  branches: branches,
);
