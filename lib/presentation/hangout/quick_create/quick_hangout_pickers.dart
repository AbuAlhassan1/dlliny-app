import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/venue_picker_sheet.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/segmented_selector.dart';

typedef QuickPrivacy = ({String visibility, String join});

const RoundedRectangleBorder _sheetShape = RoundedRectangleBorder(
  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
);

Future<QuickVenue?> showQuickVenuePicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<QuickVenue>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.c.surfaceElevated,
    shape: _sheetShape,
    builder: (_) => VenuePickerSheet(selectedId: selectedId),
  );
}

Future<VenueLocationResponse?> showQuickBranchPicker(
  BuildContext context, {
  required VenueResponse venue,
  VenueLocationResponse? selected,
}) {
  final sorted = [...venue.locations]..sort((a, b) {
    if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
    return a.sortOrder.compareTo(b.sortOrder);
  });
  return showModalBottomSheet<VenueLocationResponse>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: _sheetShape,
    builder: (ctx) => SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Text(
            ctx.pickBilingual(ar: 'اختر الفرع', en: 'Choose branch'),
            style: TextStyle(
              color: ctx.c.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: 15,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: sorted.length,
              separatorBuilder: (_, _) =>
                  Divider(height: 1, color: ctx.c.divider),
              itemBuilder: (_, i) {
                final b = sorted[i];
                final label = ctx.pickBilingual(
                  ar: b.labelAr ?? b.addressAr ?? '',
                  en: b.labelEn ?? b.addressEn ?? '',
                );
                return ListTile(
                  onTap: () => Navigator.pop(ctx, b),
                  leading: Icon(TablerIcons.map_pin, color: ctx.c.primary),
                  title: Text(
                    label.isEmpty
                        ? ctx.pickBilingual(ar: 'فرع', en: 'Branch')
                        : label,
                    style: TextStyle(
                      color: ctx.c.onSurface,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                  trailing: b.id == selected?.id
                      ? Icon(TablerIcons.circle_check_filled,
                          color: ctx.c.primary)
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}

Future<QuickPrivacy?> showQuickPrivacySheet(
  BuildContext context, {
  required String visibility,
  required String join,
}) {
  var vis = visibility;
  var jn = join;
  return showModalBottomSheet<QuickPrivacy>(
    context: context,
    backgroundColor: context.c.surfaceElevated,
    shape: _sheetShape,
    builder: (ctx) => SafeArea(
      top: false,
      child: StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _label(ctx, ar: 'من يشوف الطلعة', en: 'Who can see it'),
              const SizedBox(height: 8),
              SegmentedSelector<String>(
                selected: vis,
                onChanged: (v) => setSheet(() => vis = v),
                options: [
                  SegmentOption(
                    value: 'PUBLIC',
                    label: ctx.pickBilingual(ar: 'عام', en: 'Public'),
                  ),
                  SegmentOption(
                    value: 'FOLLOWERS',
                    label: ctx.pickBilingual(ar: 'المتابعين', en: 'Followers'),
                  ),
                  SegmentOption(
                    value: 'INVITEES',
                    label: ctx.pickBilingual(ar: 'المدعوين', en: 'Invitees'),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _label(ctx, ar: 'مين يقدر ينضم', en: 'Who can join'),
              const SizedBox(height: 8),
              SegmentedSelector<String>(
                selected: jn,
                onChanged: (v) => setSheet(() => jn = v),
                options: [
                  SegmentOption(
                    value: 'OPEN',
                    label: ctx.pickBilingual(ar: 'مفتوح', en: 'Open'),
                  ),
                  SegmentOption(
                    value: 'INVITE_ONLY',
                    label:
                        ctx.pickBilingual(ar: 'بالدعوة فقط', en: 'Invite only'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () =>
                      Navigator.pop(ctx, (visibility: vis, join: jn)),
                  style: FilledButton.styleFrom(
                    backgroundColor: ctx.c.primary,
                    foregroundColor: ctx.c.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    ctx.pickBilingual(ar: 'تم', en: 'Done'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

Widget _label(BuildContext context, {required String ar, required String en}) =>
    Text(
      context.pickBilingual(ar: ar, en: en),
      style: TextStyle(
        color: context.c.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 14,
        fontFamily: 'IBMPlexSansArabic',
      ),
    );
