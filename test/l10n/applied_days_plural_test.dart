import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:hangout/generated/locale_keys.g.dart';

Future<void> _mount(
  WidgetTester tester,
  String locale, {
  required bool cldr,
}) async {
  EasyLocalization.logger.enableBuildModes = [];
  await tester.pumpWidget(
    EasyLocalization(
      key: UniqueKey(),
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations',
      assetLoader: const CodegenLoader(),
      startLocale: Locale(locale),
      saveLocale: false,
      ignorePluralRules: !cldr,
      child: Builder(
        builder: (context) => Localizations(
          locale: context.locale,
          delegates: context.localizationDelegates,
          child: const SizedBox(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  const key = LocaleKeys.manage_venue_hours_editor_applied_days;

  for (final cldr in [false, true]) {
    testWidgets('Arabic, ${cldr ? 'CLDR rules' : 'the default rules'}', (
      tester,
    ) async {
      await _mount(tester, 'ar', cldr: cldr);
      expect(key.plural(1), 'تم تطبيق الأوقات على يوم واحد');
      expect(key.plural(2), 'تم تطبيق الأوقات على يومين');
      for (var n = 3; n <= 7; n++) {
        expect(key.plural(n), 'تم تطبيق الأوقات على $n أيام');
      }
      expect(
        key.plural(11),
        cldr ? 'تم تطبيق الأوقات على 11 يومًا' : 'تم تطبيق الأوقات على 11 أيام',
      );
    });
  }

  testWidgets('English', (tester) async {
    await _mount(tester, 'en', cldr: false);
    expect(key.plural(1), 'Applied to 1 day');
    expect(key.plural(6), 'Applied to 6 days');
  });
}
