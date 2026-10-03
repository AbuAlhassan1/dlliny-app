import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/domain/dto/response/business_venue_hours_response.dart';
import 'package:hangout/domain/dto/response/venue_opening_hours_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/venue/controllers/manage_hours/manage_hours_bloc.dart';
import 'package:hangout/presentation/venue/utils/venue_error_codes.dart';
import 'package:hangout/presentation/venue/utils/venue_hours_format.dart';

String branchScopeLabel(EditableScopeHoursDto b, String locale) {
  bool has(String? s) => s != null && s.trim().isNotEmpty;
  final en = locale.startsWith('en');
  final label = en && has(b.labelEn) ? b.labelEn : b.labelAr;
  if (has(label)) return label!.trim();
  final district = en && has(b.districtNameEn)
      ? b.districtNameEn
      : b.districtNameAr;
  if (has(district)) return district!.trim();
  return (b.isPrimary
          ? LocaleKeys.venue_branches_primary_branch
          : LocaleKeys.venue_branches_branch_fallback)
      .tr();
}

String hoursEditorErrorMessage(HoursEditorError e, String locale) {
  var detail = e.detail;
  if (e.code == VenueErrorCodes.hoursOverlap) {
    if (e.conflict.length == 2) {
      detail = e.conflict
          .map(
            (r) =>
                '${weekdayName(r.dayOfWeek, locale)} ${r.isAllDay ? LocaleKeys.venue_hours_open_24h.tr() : formatInterval(HoursIntervalDto(opens: r.opens!, closes: r.closes!, overnight: r.closes!.compareTo(r.opens!) <= 0), locale)}',
          )
          .join('، ');
    } else if (!locale.startsWith('en')) {
      detail = null;
    }
  }
  return hoursEditorErrorText(e.code, detail: detail);
}

String hmOf(TimeOfDay t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

Future<String?> pickHm(
  BuildContext context, {
  required String helpText,
  String? initial,
  String fallback = '09:00',
}) async {
  final src = initial ?? fallback;
  final picked = await showTimePicker(
    context: context,
    helpText: helpText,
    initialTime: TimeOfDay(
      hour: int.parse(src.substring(0, 2)),
      minute: int.parse(src.substring(3, 5)),
    ),
  );
  return picked == null ? null : hmOf(picked);
}

Future<(String?, String?)> pickInterval(
  BuildContext context, {
  String? opens,
  String? closes,
}) async {
  final o = await pickHm(
    context,
    helpText: LocaleKeys.manage_venue_hours_editor_opens_time.tr(),
    initial: opens,
  );
  if (o == null || !context.mounted) return (null, null);
  final cl = await pickHm(
    context,
    helpText: LocaleKeys.manage_venue_hours_editor_closes_time.tr(),
    initial: closes,
    fallback: '17:00',
  );
  return (o, cl);
}

Future<bool> confirmHoursDialog(
  BuildContext context, {
  required String title,
  required String body,
  required String confirm,
  bool destructive = false,
}) async {
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final cc = ctx.c;
      return AlertDialog(
        backgroundColor: cc.surfaceElevated,
        title: Text(
          title,
          style: TextStyle(
            color: cc.onSurface,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        content: Text(
          body,
          style: TextStyle(
            color: cc.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              LocaleKeys.common_cancel.tr(),
              style: TextStyle(
                color: cc.onSurfaceSecondary,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              confirm,
              style: TextStyle(
                color: destructive ? cc.danger : cc.primary,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      );
    },
  );
  return ok == true;
}

class HoursSectionTitle extends StatelessWidget {
  final String text;
  const HoursSectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(
      color: context.c.onSurface,
      fontSize: 15,
      fontWeight: FontWeight.bold,
      fontFamily: 'IBMPlexSansArabic',
    ),
  );
}

class HoursNote extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? color;
  final Widget? action;

  const HoursNote({
    super.key,
    required this.icon,
    required this.text,
    this.color,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final tint = color ?? c.onSurfaceSecondary;
    final textColor = color == null || color == c.warning
        ? c.onSurface
        : color!;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tint.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(icon, color: tint, size: 16),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                if (action != null) ...[const SizedBox(height: 4), action!],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HoursPanel extends StatelessWidget {
  final Widget child;
  const HoursPanel({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: child,
    );
  }
}

class MinTapTarget extends SingleChildRenderObjectWidget {
  const MinTapTarget({super.key, required Widget super.child});

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMinTapTarget();
}

class _RenderMinTapTarget extends RenderShiftedBox {
  _RenderMinTapTarget() : super(null);

  static const double _min = kMinInteractiveDimension;

  Size _sizeFor(BoxConstraints constraints, Size child) =>
      constraints.constrain(
        Size(math.max(child.width, _min), math.max(child.height, _min)),
      );

  @override
  double computeMinIntrinsicWidth(double height) =>
      math.max(child?.getMinIntrinsicWidth(height) ?? 0, _min);

  @override
  double computeMaxIntrinsicWidth(double height) =>
      math.max(child?.getMaxIntrinsicWidth(height) ?? 0, _min);

  @override
  double computeMinIntrinsicHeight(double width) =>
      math.max(child?.getMinIntrinsicHeight(width) ?? 0, _min);

  @override
  double computeMaxIntrinsicHeight(double width) =>
      math.max(child?.getMaxIntrinsicHeight(width) ?? 0, _min);

  @override
  Size computeDryLayout(covariant BoxConstraints constraints) =>
      _sizeFor(constraints, child?.getDryLayout(constraints) ?? Size.zero);

  @override
  void performLayout() {
    final child = this.child!;
    child.layout(constraints, parentUsesSize: true);
    size = _sizeFor(constraints, child.size);
    (child.parentData! as BoxParentData).offset = Alignment.center.alongOffset(
      size - child.size as Offset,
    );
  }

  @override
  bool hitTest(BoxHitTestResult result, {required Offset position}) {
    if (!size.contains(position)) return false;
    if (super.hitTest(result, position: position)) return true;
    final center = child!.size.center(Offset.zero);
    return result.addWithRawTransform(
      transform: MatrixUtils.forceToPoint(center),
      position: center,
      hitTest: (result, _) => child!.hitTest(result, position: center),
    );
  }
}
