// ignore_for_file: implementation_imports

import 'dart:ui';

import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:hangout/generated/codegen_loader.g.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> loadTestLocale(String locale) async {
  await initializeDateFormatting();
  Localization.load(
    Locale(locale),
    translations: Translations(CodegenLoader.mapLocales[locale]!),
  );
}
