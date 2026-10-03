import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/api_response.dart';
import 'package:hangout/domain/dto/request/venue_hours_requests.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/presentation/venue/pages/venue_hours_editor_page.dart';
import 'package:mocktail/mocktail.dart';

import '../../../helpers/hours_test_helpers.dart';
import '../../../helpers/locale_test_helper.dart';
import '../../../helpers/test_harness.dart';

const _entry = 'تحديد أوقات لعدة أيام';
const _apply = 'تطبيق';
const _allDays = 'كل الأيام';
const _add = 'إضافة كفترة إضافية';
const _replace = 'استبدال أوقات الأيام المختارة';
const _undo = 'تراجع';
const _deselect = 'إلغاء تحديدها';
const _save = 'حفظ';
const _fsi = '\u2068';
const _pdi = '\u2069';
const _nineToFive = '${_fsi}9:00 ص$_pdi – ${_fsi}5:00 م$_pdi';
const _eightToThree = '${_fsi}8:00 م$_pdi – ${_fsi}3:00 ص$_pdi (اليوم التالي)';

ValueKey<String> _day(int dow) => ValueKey('apply-days-day-$dow');

void main() {
  late MockApiService api;

  setUpAll(() async {
    registerFallbackValue(
      const UpdateVenueHoursRequest(regular: WeeklyScheduleInput(days: [])),
    );
    await loadTestLocale('ar');
  });

  setUp(() async {
    await resetLocator();
    api = MockApiService();
    putSingleton<ApiService>(api);
  });

  tearDown(resetLocator);

  Future<void> open(
    WidgetTester tester,
    BusinessVenueHoursResponse model, {
    Size size = const Size(900, 2000),
    String locale = 'ar',
  }) async {
    tester.view.physicalSize = size * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    when(
      () => api.businessGetVenueHours('venue-1'),
    ).thenAnswer((_) async => apiOk(model));
    await tester.pumpWidget(
      hoursTestApp(
        locale: locale,
        Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => VenueHoursEditorPage.push(context, 'venue-1'),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Future<void> openSheet(WidgetTester tester, {String entry = _entry}) async {
    await tester.ensureVisible(find.text(entry));
    await tester.pumpAndSettle();
    await tester.tap(find.text(entry));
    await tester.pumpAndSettle();
  }

  Future<void> pickNineToFive(WidgetTester tester) async {
    await tester.tap(find.byKey(const ValueKey('apply-days-opens')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  Future<void> typeTime(WidgetTester tester, int hour, String period) async {
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '$hour');
    await tester.enterText(find.byType(TextField).at(1), '00');
    await tester.tap(find.text(period));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();
  }

  ElevatedButton applyButton(WidgetTester tester) => tester
      .widget<ElevatedButton>(find.byKey(const ValueKey('apply-days-apply')));

  ElevatedButton saveButton(WidgetTester tester) =>
      tester.widget<ElevatedButton>(
        find.ancestor(
          of: find.text(_save),
          matching: find.byType(ElevatedButton),
        ),
      );

  testWidgets('day chips, «كل الأيام», and Apply waiting for a range and a '
      'day', (tester) async {
    final semantics = tester.ensureSemantics();
    await open(tester, editorModel(venue: venueScope(regular: fixtureA())));
    expect(
      tester.getSize(find.byKey(const ValueKey('hours-apply-days'))).height,
      greaterThanOrEqualTo(48),
    );
    await openSheet(tester);
    expect(find.text('الأوقات الاعتيادية'), findsWidgets);
    expect(applyButton(tester).onPressed, isNull);

    final saturday = find.byKey(_day(6));
    expect(
      tester.getSemantics(saturday),
      isSemantics(isButton: true, isSelected: false),
    );
    expect(
      tester.getTopRight(saturday).dx,
      greaterThan(tester.getTopRight(find.byKey(_day(0))).dx),
      reason: 'RTL: Saturday is the first chip from the right',
    );
    expect(tester.getSize(saturday).height, greaterThanOrEqualTo(48));

    await tester.tap(saturday);
    await tester.pump();
    expect(
      tester.getSemantics(saturday),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(applyButton(tester).onPressed, isNull);

    await pickNineToFive(tester);
    expect(find.text('9:00 ص'), findsOneWidget);
    expect(find.text('5:00 م'), findsOneWidget);
    expect(applyButton(tester).onPressed, isNotNull);

    final all = find.byKey(const ValueKey('apply-days-all'));
    expect(find.descendant(of: all, matching: find.byType(Icon)), findsNothing);
    await tester.tap(find.text(_allDays));
    await tester.pump();
    for (var dow = 0; dow < 7; dow++) {
      expect(
        tester.getSemantics(find.byKey(_day(dow))),
        isSemantics(isButton: true, isSelected: true),
      );
    }
    expect(
      tester.getSemantics(all),
      isSemantics(isButton: true, isSelected: true),
    );
    expect(find.descendant(of: all, matching: find.byType(Icon)), findsOne);
    await tester.tap(find.text(_allDays));
    await tester.pump();
    for (var dow = 0; dow < 7; dow++) {
      expect(
        tester.getSemantics(find.byKey(_day(dow))),
        isSemantics(isButton: true, isSelected: false),
      );
    }
    expect(applyButton(tester).onPressed, isNull);
    semantics.dispose();
  });

  testWidgets('replace applies to the chosen days; «تراجع» restores the week', (
    tester,
  ) async {
    await open(
      tester,
      editorModel(venue: venueScope(regular: week([iv('20:00', '03:00')]))),
    );
    expect(find.text(_eightToThree), findsNWidgets(7));
    await openSheet(tester);
    await pickNineToFive(tester);
    for (final dow in [6, 0, 1]) {
      await tester.tap(find.byKey(_day(dow)));
    }
    await tester.pump();
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('apply-days-mode-replace')),
      ),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    await tester.tap(find.text(_apply));
    await tester.pumpAndSettle();

    expect(find.text(_nineToFive), findsNWidgets(3));
    expect(find.text(_eightToThree), findsNWidgets(4));
    expect(find.text('تم تطبيق الأوقات على 3 أيام'), findsOneWidget);
    expect(saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.text(_undo));
    await tester.pumpAndSettle();
    expect(find.text(_eightToThree), findsNWidgets(7));
    expect(find.text('تم تطبيق الأوقات على 3 أيام'), findsNothing);
    expect(saveButton(tester).onPressed, isNull, reason: 'nothing to save');
  });

  testWidgets('add: conflicting days are named and must be deselected', (
    tester,
  ) async {
    final evening = [iv('18:00', '22:00')];
    await open(
      tester,
      editorModel(
        venue: venueScope(
          regular: week(
            evening,
            except: {
              0: hoursDay(0, [iv('10:00', '12:00')]),
              4: hoursDay(4, [
                iv('06:00', '07:00'),
                iv('07:00', '08:00'),
                iv('18:00', '19:00'),
                iv('20:00', '21:00'),
              ]),
            },
          ),
        ),
      ),
    );
    await openSheet(tester);
    await pickNineToFive(tester);
    await tester.tap(find.text(_allDays));
    await tester.pump();
    expect(find.byKey(const ValueKey('apply-days-conflict')), findsNothing);
    expect(applyButton(tester).onPressed, isNotNull);

    await tester.tap(find.text(_add));
    await tester.pump();
    expect(
      tester.getSemantics(find.byKey(const ValueKey('apply-days-mode-add'))),
      isSemantics(
        hasCheckedState: true,
        isChecked: true,
        isInMutuallyExclusiveGroup: true,
      ),
    );
    expect(
      tester.getSemantics(
        find.byKey(const ValueKey('apply-days-mode-replace')),
      ),
      isSemantics(hasCheckedState: true, isChecked: false),
    );
    expect(
      find.textContaining('تتداخل مع أوقات موجودة: الأحد\n'),
      findsOneWidget,
    );
    expect(
      find.textContaining('لا يمكن إضافة أكثر من 4 فترات في اليوم: الخميس'),
      findsOneWidget,
    );
    expect(find.textContaining('بدل الإضافة'), findsOneWidget);
    expect(applyButton(tester).onPressed, isNull);
    expect(
      tester.getSemantics(find.byKey(const ValueKey('apply-days-conflict'))),
      isSemantics(isLiveRegion: true),
    );
    expect(
      tester.getSemantics(find.byKey(_day(0))),
      isSemantics(isSelected: true, value: 'تتداخل مع أوقات هذا اليوم'),
    );
    expect(
      tester.getSemantics(find.byKey(_day(4))),
      isSemantics(
        isSelected: true,
        value: 'لا يمكن إضافة أكثر من 4 فترات في اليوم',
      ),
    );

    await tester.tap(find.text(_replace));
    await tester.pump();
    expect(find.byKey(const ValueKey('apply-days-conflict')), findsNothing);
    await tester.tap(find.text(_add));
    await tester.pump();

    await tester.tap(find.text(_deselect));
    await tester.pump();
    expect(find.byKey(const ValueKey('apply-days-conflict')), findsNothing);
    expect(
      tester.getSemantics(find.byKey(_day(0))),
      isSemantics(isButton: true, isSelected: false),
    );
    expect(applyButton(tester).onPressed, isNotNull);

    await tester.tap(find.text(_apply));
    await tester.pumpAndSettle();
    expect(find.text('تم تطبيق الأوقات على 5 أيام'), findsOneWidget);
    expect(find.text(_nineToFive), findsNWidgets(5));
    expect(find.text('${_fsi}10:00 ص$_pdi – ${_fsi}12:00 م$_pdi'), findsOne);
  });

  testWidgets('another day\'s hours are named; deselecting a day can bring '
      'its own hours back into a neighbour\'s way', (tester) async {
    await open(
      tester,
      editorModel(venue: venueScope(regular: week([iv('06:00', '12:00')]))),
    );
    await openSheet(tester);
    await tester.tap(find.byKey(const ValueKey('apply-days-opens')));
    await tester.pumpAndSettle();
    await typeTime(tester, 8, 'PM');
    await typeTime(tester, 7, 'AM');
    await tester.tap(find.byKey(_day(0)));
    await tester.tap(find.byKey(_day(1)));
    await tester.pump();

    expect(
      find.textContaining(
        'تتداخل مع أوقات موجودة: الاثنين (مع أوقات الثلاثاء)',
      ),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(_day(1))),
      isSemantics(isSelected: true, value: 'تتداخل مع أوقات الثلاثاء'),
    );
    expect(find.textContaining('بدل الإضافة'), findsNothing);

    await tester.tap(find.text(_deselect));
    await tester.pump();
    expect(
      find.textContaining('تتداخل مع أوقات موجودة: الأحد (مع أوقات الاثنين)'),
      findsOneWidget,
    );
    expect(
      tester.getSemantics(find.byKey(_day(0))),
      isSemantics(isSelected: true),
    );
    expect(
      tester.getSemantics(find.byKey(_day(1))),
      isSemantics(isSelected: false),
    );
    expect(applyButton(tester).onPressed, isNull);
  });

  testWidgets('at phone size with large text the conflict state fits', (
    tester,
  ) async {
    await open(
      tester,
      editorModel(
        venue: venueScope(
          regular: week(
            [iv('18:00', '22:00')],
            except: {
              0: hoursDay(0, [iv('10:00', '12:00')]),
              4: hoursDay(4, [
                iv('06:00', '07:00'),
                iv('07:00', '08:00'),
                iv('18:00', '19:00'),
                iv('20:00', '21:00'),
              ]),
            },
          ),
        ),
      ),
      size: const Size(390, 844),
    );
    await openSheet(tester);
    await pickNineToFive(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.tap(find.text(_allDays));
    await tester.tap(find.text(_add));
    await tester.pumpAndSettle();
    expect(
      MediaQuery.textScalerOf(tester.element(find.text(_allDays))).scale(10),
      20,
    );

    final apply = tester.getRect(
      find.byKey(const ValueKey('apply-days-apply')),
    );
    expect(apply.top, greaterThan(0));
    expect(apply.bottom, lessThanOrEqualTo(844));
    expect(apply.height, greaterThanOrEqualTo(48));
    for (var dow = 0; dow < 7; dow++) {
      expect(
        tester.getSize(find.byKey(_day(dow))).height,
        greaterThanOrEqualTo(48),
      );
    }
    await tester.ensureVisible(find.text(_deselect));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('لا يمكن إضافة أكثر من 4 فترات في اليوم: الخميس'),
      findsOneWidget,
    );
    await tester.tap(find.text(_deselect));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('apply-days-conflict')), findsNothing);
    expect(applyButton(tester).onPressed, isNotNull);
  });

  testWidgets('past midnight reads «(اليوم التالي)»; the same two times '
      'can\'t apply', (tester) async {
    await open(tester, editorModel(venue: venueScope(regular: fixtureA())));
    await openSheet(tester);
    await tester.tap(find.byKey(_day(6)));
    await tester.tap(find.byKey(const ValueKey('apply-days-opens')));
    await tester.pumpAndSettle();
    await typeTime(tester, 4, 'PM');
    await typeTime(tester, 2, 'AM');
    final closes = find.byKey(const ValueKey('apply-days-closes'));
    expect(
      find.descendant(of: closes, matching: find.text('(اليوم التالي)')),
      findsOneWidget,
    );
    expect(applyButton(tester).onPressed, isNotNull);

    await tester.tap(closes);
    await tester.pumpAndSettle();
    await typeTime(tester, 4, 'PM');
    expect(
      find.text('وقت الفتح والإغلاق يجب أن يختلفا — اختر 24 ساعة'),
      findsOneWidget,
    );
    expect(applyButton(tester).onPressed, isNull);
  });

  testWidgets('the whole dashed time field answers a tap', (tester) async {
    await open(tester, editorModel(venue: venueScope(regular: fixtureA())));
    await openSheet(tester);
    final field = tester.getRect(
      find.byKey(const ValueKey('apply-days-closes')),
    );
    await tester.tapAt(Offset(field.left + 8, field.center.dy));
    await tester.pumpAndSettle();
    expect(find.byType(TimePickerDialog), findsOneWidget);
  });

  testWidgets('a later edit of the week takes the «تراجع» away', (
    tester,
  ) async {
    await open(tester, editorModel(venue: venueScope(regular: fixtureA())));
    await openSheet(tester);
    await pickNineToFive(tester);
    await tester.tap(find.byKey(_day(5)));
    await tester.pump();
    await tester.tap(find.text(_apply));
    await tester.pumpAndSettle();
    expect(find.text(_undo), findsOneWidget);

    await tester.tap(find.text('مغلق').first);
    await tester.pumpAndSettle();
    expect(find.text(_undo), findsNothing);
  });

  testWidgets('a save starting takes the «تراجع» away', (tester) async {
    final saving = Completer<ApiResponse<BusinessVenueHoursResponse>>();
    when(
      () => api.businessUpdateVenueHours('venue-1', any()),
    ).thenAnswer((_) => saving.future);
    final model = editorModel(venue: venueScope(regular: fixtureA()));
    await open(tester, model);
    await openSheet(tester);
    await pickNineToFive(tester);
    await tester.tap(find.byKey(_day(5)));
    await tester.pump();
    await tester.tap(find.text(_apply));
    await tester.pumpAndSettle();
    expect(find.text(_undo), findsOneWidget);

    await tester.tap(find.text(_save));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text(_undo), findsNothing);

    saving.complete(apiOk(model));
    await tester.pumpAndSettle();
    expect(find.byType(VenueHoursEditorPage), findsNothing);
  });

  testWidgets('with a screen reader on, the snackbar stays and has a ✕', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(accessibleNavigation: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await open(tester, editorModel(venue: venueScope(regular: fixtureA())));
    await openSheet(tester);
    await pickNineToFive(tester);
    await tester.tap(find.byKey(_day(5)));
    await tester.pump();
    await tester.tap(find.text(_apply));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 30));
    final bar = find.byKey(const ValueKey('hours-applied-snackbar'));
    expect(find.text('تم تطبيق الأوقات على يوم واحد'), findsOneWidget);
    final close = find.descendant(of: bar, matching: find.byType(IconButton));
    expect(close, findsOneWidget);
    await tester.tap(close);
    await tester.pumpAndSettle();
    expect(bar, findsNothing);
  });

  testWidgets('English copy', (tester) async {
    await loadTestLocale('en');
    addTearDown(() => loadTestLocale('ar'));
    await open(
      tester,
      editorModel(
        venue: venueScope(
          regular: week(
            [iv('18:00', '22:00')],
            except: {
              0: hoursDay(0, [iv('10:00', '12:00')]),
              4: hoursDay(4, [
                iv('06:00', '07:00'),
                iv('07:00', '08:00'),
                iv('18:00', '19:00'),
                iv('20:00', '21:00'),
              ]),
            },
          ),
        ),
      ),
      locale: 'en',
    );
    await openSheet(tester, entry: 'Set hours for several days');
    for (final text in [
      'Opening period',
      'Days',
      'All days',
      'How to apply',
      "Replace the chosen days' hours",
      'Add as an extra period',
      'Apply',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.text('Pick a time'), findsNWidgets(2));
    expect(
      tester.getTopLeft(find.byKey(_day(6))).dx,
      lessThan(tester.getTopLeft(find.byKey(_day(0))).dx),
    );

    await pickNineToFive(tester);
    await tester.tap(find.text('All days'));
    await tester.tap(find.text('Add as an extra period'));
    await tester.pump();
    expect(
      find.text(
        'Overlaps existing hours: Sunday\n'
        "A day can't have more than 4 periods: Thursday\n"
        'Deselect these days or change the period, or choose '
        "“Replace the chosen days' hours” instead of adding.",
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Deselect them'));
    await tester.pump();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();
    expect(find.text('Applied to 5 days'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);
  });

  testWidgets('no entry where the week is read-only or missing', (
    tester,
  ) async {
    await open(
      tester,
      editorModel(
        venue: venueScope(regular: fixtureA()),
        branches: [
          branchScope('karrada', labelAr: 'الكرادة', isPrimary: true),
          branchScope('mansour', districtNameAr: 'المنصور'),
        ],
      ),
    );
    expect(find.text(_entry), findsOneWidget);

    await tester.tap(find.text('المنصور'));
    await tester.pumpAndSettle();
    expect(find.text(_entry), findsNothing);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text(_entry), findsOneWidget);
    await openSheet(tester);
    expect(find.text('الأوقات الاعتيادية · المنصور'), findsOneWidget);
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    await tester.tap(find.text('أوقات رمضان'));
    await tester.pumpAndSettle();
    expect(find.text(_entry), findsNothing);
  });
}
