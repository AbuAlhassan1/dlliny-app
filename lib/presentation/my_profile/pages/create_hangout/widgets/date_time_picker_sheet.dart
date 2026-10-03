import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

Future<DateTime?> showDateTimePickerSheet(
  BuildContext context, {
  DateTime? initial,
}) async {
  final now = DateTime.now();
  final start = initial ?? now.add(const Duration(days: 1));
  DateTime working = start;

  return showModalBottomSheet<DateTime>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      final c = sheetContext.c;
      return SafeArea(
        top: false,
        child: SizedBox(
          height: 280,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: Text(
                        LocaleKeys.common_cancel.tr(),
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      LocaleKeys.hangout_create_datetime_sheet_title.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: () => Navigator.pop(sheetContext, working),
                      child: Text(
                        LocaleKeys.hangout_create_datetime_sheet_confirm.tr(),
                        style: TextStyle(
                          color: c.onSurface,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoTheme(
                  data: CupertinoThemeData(
                    brightness: Brightness.dark,
                    textTheme: CupertinoTextThemeData(
                      dateTimePickerTextStyle: TextStyle(
                        color: c.onSurface,
                        fontSize: 16,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ),
                  child: CupertinoDatePicker(
                    mode: CupertinoDatePickerMode.dateAndTime,
                    initialDateTime: start,
                    minimumDate: now,
                    maximumDate: now.add(const Duration(days: 365)),
                    use24hFormat: true,
                    onDateTimeChanged: (dt) => working = dt,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
