import 'package:flutter/material.dart';
import 'package:hangout/domain/dto/response/chat_enums.dart';
import 'package:hangout/presentation/chat/widgets/share_target_sheet.dart';

Future<void> openShareSheet(
  BuildContext context, {
  required SharedResourceType resourceType,
  required String resourceId,
  String? headlineLabel,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (_) => ShareTargetSheet(
      resourceType: resourceType,
      resourceId: resourceId,
      headlineLabel: headlineLabel,
    ),
  );
}
