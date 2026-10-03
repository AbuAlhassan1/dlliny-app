import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/presentation/venue/pages/venue_hours_editor_page.dart';
import 'package:hangout/presentation/venue/widgets/hours/editor/hours_editor_common.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/hours_test_helpers.dart';
import '../../../helpers/locale_test_helper.dart';
import '../../../helpers/test_harness.dart';

final _regular = week([iv('09:00', '17:00')]);
final _ramadan = week([iv('20:00', '03:00')]);

const _allBranches = 'كل الفروع (الافتراضي)';
const _save = 'حفظ';
const _incomplete = 'اختر وقت الفتح والإغلاق لكل يوم مفتوح';
const _unsaved = ValueKey('hours-scope-unsaved');
const _fsi = '\u2068';
const _pdi = '\u2069';

void main() {
  late MockApiService api;

  setUpAll(() {
    registerFallbackValue(
      const UpdateVenueHoursRequest(regular: WeeklyScheduleInput(days: [])),
    );
    registerFallbackValue(const UpdateBranchHoursRequest(mode: 'OWN'));
    return loadTestLocale('ar');
  });

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  Future<bool? Function()> open(
    WidgetTester tester,
    BusinessVenueHoursResponse model,
  ) async {
    tester.view.physicalSize = const Size(2700, 6000);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    when(
      () => api.businessGetVenueHours('venue-1'),
    ).thenAnswer((_) async => apiOk(model));
    bool? result;
    await tester.pumpWidget(
      hoursTestApp(
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async =>
                  result = await VenueHoursEditorPage.push(context, 'venue-1'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return () => result;
  }

  ElevatedButton saveButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(_save),
          matching: find.byType(ElevatedButton),
        ),
      );

  Future<void> pickOkTwice(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  group('scope chips', () {
    testWidgets('two branches: default + one chip each, district label', (
      tester,
    ) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [
            branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
            branchScope('mansour', districtNameAr: 'المنصور'),
          ],
        ),
      );
      expect(find.text(_allBranches), findsOneWidget);
      expect(find.text('الكرادة'), findsOneWidget);
      expect(find.text('المنصور'), findsOneWidget);
    });

    testWidgets('a single branch that still overrides (I12) gets chips', (
      tester,
    ) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [
            branchScope(
              'karrada',
              isPrimary: true,
              ownHours: true,
              regular: _regular,
              ownStatus: true,
              status: 'TEMPORARILY_CLOSED',
            ),
          ],
        ),
      );
      expect(find.text(_allBranches), findsOneWidget);
      expect(find.text('الفرع الرئيسي'), findsOneWidget);
    });

    testWidgets('a single inheriting branch: no chips', (tester) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [branchScope('karrada', isPrimary: true)],
        ),
      );
      expect(find.text(_allBranches), findsNothing);
    });
  });

  group('branch hours', () {
    BusinessVenueHoursResponse model() => editorModel(
      venue: venueScope(regular: _regular, ramadan: _ramadan),
      branches: [
        branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
        branchScope('mansour', districtNameAr: 'المنصور'),
      ],
    );

    testWidgets('own hours seed BOTH weeks from the venue default', (
      tester,
    ) async {
      await open(tester, model());
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(
        find.text('هذا الفرع يتبع أوقات المكان الافتراضية.'),
        findsOneWidget,
      );

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(
        find.text('${_fsi}9:00 ص$_pdi – ${_fsi}5:00 م$_pdi'),
        findsNWidgets(7),
      );

      await tester.tap(find.text('أوقات رمضان'));
      await tester.pumpAndSettle();
      expect(
        find.text('${_fsi}8:00 م$_pdi – ${_fsi}3:00 ص$_pdi (اليوم التالي)'),
        findsNWidgets(7),
      );
    });

    testWidgets('saving it without Ramadan hours asks first', (tester) async {
      await open(tester, model());
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text('أوقات رمضان'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف أوقات رمضان'));
      await tester.pumpAndSettle();

      await tester.tap(find.text(_save));
      await tester.pumpAndSettle();
      expect(find.text('هذا الفرع بدون أوقات رمضان'), findsOneWidget);
      verifyNever(() => api.businessUpdateBranchHours(any(), any(), any()));
    });
  });

  group('venue hours', () {
    testWidgets('no hours yet: empty intervals, Save disabled until filled', (
      tester,
    ) async {
      await open(tester, editorModel());
      expect(find.text('اختر الوقت'), findsNWidgets(7));
      expect(saveButton(tester).onPressed, isNull);
      expect(find.text(_incomplete), findsOneWidget);

      await tester.tap(find.text('اختر الوقت').first);
      await pickOkTwice(tester);
      expect(find.text('اختر الوقت'), findsNWidgets(6));
      expect(find.text(_incomplete), findsOneWidget);
      expect(saveButton(tester).onPressed, isNull);

      await tester.tap(find.text('تحديد أوقات لعدة أيام'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('apply-days-opens')));
      await pickOkTwice(tester);
      await tester.tap(find.text('كل الأيام'));
      await tester.pump();
      await tester.tap(find.text('تطبيق'));
      await tester.pumpAndSettle();
      expect(find.text('اختر الوقت'), findsNothing);
      expect(find.text(_incomplete), findsNothing);
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('closed all week asks for confirmation', (tester) async {
      await open(tester, editorModel(venue: venueScope(regular: _regular)));
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('مغلق').at(i));
        await tester.pump();
      }
      await tester.tap(find.text(_save));
      await tester.pumpAndSettle();
      expect(find.text('مغلق طوال الأسبوع؟'), findsOneWidget);
      verifyNever(() => api.businessUpdateVenueHours(any(), any()));
    });

    testWidgets('a saved change pops with true', (tester) async {
      final result = await open(
        tester,
        editorModel(venue: venueScope(regular: _regular)),
      );
      when(() => api.businessUpdateVenueHours('venue-1', any())).thenAnswer(
        (_) async => apiOk(editorModel(venue: venueScope(regular: _regular))),
      );
      await tester.tap(find.text('مغلق').last);
      await tester.pump();
      await tester.tap(find.text(_save));
      await tester.pumpAndSettle();
      verify(() => api.businessUpdateVenueHours('venue-1', any())).called(1);
      expect(find.byType(VenueHoursEditorPage), findsNothing);
      expect(result(), isTrue);
    });

    testWidgets('leaving with unsaved changes asks first', (tester) async {
      await open(tester, editorModel(venue: venueScope(regular: _regular)));
      await tester.tap(find.text('مغلق').last);
      await tester.pump();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
      await tester.tap(find.text('تجاهل'));
      await tester.pumpAndSettle();
      expect(find.byType(VenueHoursEditorPage), findsNothing);
    });
  });

  group('status', () {
    testWidgets(
      'the reopen date picker starts the day after the SERVER\'s today',
      (tester) async {
        await open(
          tester,
          editorModel(
            venue: venueScope(regular: _regular),
            today: '2027-01-10',
          ),
        );
        await tester.tap(find.text('مغلق مؤقتاً'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('تاريخ العودة (اختياري)'));
        await tester.pumpAndSettle();
        final picker = tester.widget<DatePickerDialog>(
          find.byType(DatePickerDialog),
        );
        expect(picker.firstDate, DateTime(2027, 1, 11));
        expect(picker.lastDate, DateTime(2028, 1, 10));
        expect(picker.currentDate, DateTime(2027, 1, 10));
      },
    );

    testWidgets('permanently closed asks first', (tester) async {
      await open(tester, editorModel(venue: venueScope(regular: _regular)));
      await tester.tap(find.text('مغلق نهائياً'));
      await tester.pumpAndSettle();
      expect(find.text('إغلاق نهائي؟'), findsOneWidget);
      await tester.tap(find.text('إغلاق نهائي'));
      await tester.pumpAndSettle();
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('a lapsed closure offers «اجعله مفتوحاً»', (tester) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(
            regular: _regular,
            status: 'TEMPORARILY_CLOSED',
            reopensOn: '2026-09-27',
            statusExpired: true,
          ),
        ),
      );
      expect(find.textContaining('عدت للعمل منذ'), findsOneWidget);
      await tester.tap(find.text('اجعله مفتوحاً'));
      await tester.pumpAndSettle();
      expect(find.textContaining('عدت للعمل منذ'), findsNothing);
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('a branch\'s status card says «حالة الفرع»', (tester) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [
            branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
            branchScope('mansour', districtNameAr: 'المنصور'),
          ],
        ),
      );
      expect(find.text('حالة المكان'), findsOneWidget);
      expect(find.text('حالة الفرع'), findsNothing);
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(find.text('حالة الفرع'), findsOneWidget);
      expect(find.text('حالة المكان'), findsNothing);
      expect(find.text('نفس حالة المكان'), findsOneWidget);
    });
  });

  group('clear all hours', () {
    BusinessVenueHoursResponse model({bool cleared = false}) => editorModel(
      venue: venueScope(regular: cleared ? null : _regular),
      branches: [
        branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
        branchScope('mansour', districtNameAr: 'المنصور'),
      ],
    );

    testWidgets('stays on the page and keeps a branch\'s unsaved edit', (
      tester,
    ) async {
      final toasts = <String>[];
      final sub = appToast.stream.listen((m) => toasts.add(m.text));
      addTearDown(sub.cancel);
      final result = await open(tester, model());
      when(
        () => api.businessClearVenueHours('venue-1'),
      ).thenAnswer((_) async => apiOk(model(cleared: true)));

      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      await tester.tap(find.text(_allBranches));
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byIcon(TablerIcons.dots_vertical),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('حذف كل الأوقات'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'حذف كل الأوقات'));
      await tester.pumpAndSettle();

      verify(() => api.businessClearVenueHours('venue-1')).called(1);
      expect(find.byType(VenueHoursEditorPage), findsOneWidget);
      expect(toasts, ['تم حذف الأوقات']);
      expect(find.text('اختر الوقت'), findsNWidgets(7));
      expect(find.byKey(_unsaved), findsOneWidget);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text('تجاهل التغييرات؟'), findsOneWidget);
      await tester.tap(find.text('تجاهل'));
      await tester.pumpAndSettle();
      expect(find.byType(VenueHoursEditorPage), findsNothing);
      expect(result(), isTrue);
    });
  });

  group('an inheriting branch (read-only default)', () {
    List<EditableScopeHoursDto> branches() => [
      branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
      branchScope('mansour', districtNameAr: 'المنصور'),
    ];

    testWidgets('no default hours: a note, never «مغلق»', (tester) async {
      await open(tester, editorModel(branches: branches()));
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          'لم تُضف أوقات افتراضية بعد، لذلك لا يرى الزوار أوقاتاً لهذا الفرع.',
        ),
        findsOneWidget,
      );
      expect(find.text('مغلق'), findsNothing);
      expect(find.text('السبت'), findsNothing);
    });

    testWidgets('a day still being written on the default reads «—»', (
      tester,
    ) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: branches(),
        ),
      );
      await tester.tap(find.text('+ فترة').at(2));
      await tester.pumpAndSettle();
      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      expect(find.text('—'), findsOneWidget);
      expect(find.text('مغلق'), findsNothing);
      expect(
        find.text('${_fsi}9:00 ص$_pdi – ${_fsi}5:00 م$_pdi'),
        findsNWidgets(6),
      );
    });
  });

  group('scope chips mark unsaved scopes', () {
    testWidgets('every scope Save would write carries the marker', (
      tester,
    ) async {
      await open(
        tester,
        editorModel(
          venue: venueScope(regular: _regular),
          branches: [
            branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
            branchScope('mansour', districtNameAr: 'المنصور'),
          ],
        ),
      );
      expect(find.byKey(_unsaved), findsNothing);

      await tester.tap(find.text('مغلق').last);
      await tester.pump();
      expect(find.byKey(_unsaved), findsOneWidget);
      expect(
        find.descendant(
          of: find.ancestor(
            of: find.text(_allBranches),
            matching: find.byType(InkWell),
          ),
          matching: find.byKey(_unsaved),
        ),
        findsOneWidget,
      );

      await tester.tap(find.text('المنصور'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byKey(_unsaved), findsNWidgets(2));

      await tester.tap(find.byType(Switch));
      await tester.pumpAndSettle();
      expect(find.byKey(_unsaved), findsOneWidget);
    });
  });

  group('day rows: 48 dp touch targets', () {
    testWidgets('a kind segment answers a tap beside its compact pill', (
      tester,
    ) async {
      await open(tester, editorModel(venue: venueScope(regular: _regular)));
      final saturdayClosed = find.text('مغلق').first;
      final target = tester.getRect(
        find.ancestor(of: saturdayClosed, matching: find.byType(MinTapTarget)),
      );
      final pill = tester.getRect(
        find
            .ancestor(of: saturdayClosed, matching: find.byType(Material))
            .first,
      );
      expect(target.height, greaterThanOrEqualTo(48));
      expect(pill.height, lessThan(target.height));

      await tester.tapAt(Offset(pill.center.dx, target.bottom - 2));
      await tester.pump();
      expect(
        find.text('${_fsi}9:00 ص$_pdi – ${_fsi}5:00 م$_pdi'),
        findsNWidgets(6),
      );
      expect(saveButton(tester).onPressed, isNotNull);
    });

    testWidgets('the interval ✕ is a 48 dp button', (tester) async {
      await open(tester, editorModel(venue: venueScope(regular: _regular)));
      await tester.tap(find.text('+ فترة').first);
      await tester.pumpAndSettle();
      final remove = find.widgetWithIcon(IconButton, TablerIcons.x);
      expect(remove, findsNWidgets(2));
      final size = tester.getSize(remove.first);
      expect(size.width, greaterThanOrEqualTo(48));
      expect(size.height, greaterThanOrEqualTo(48));

      await tester.tap(remove.last);
      await tester.pumpAndSettle();
      expect(remove, findsNothing);
      expect(find.text('اختر الوقت'), findsNothing);
    });
  });
}
