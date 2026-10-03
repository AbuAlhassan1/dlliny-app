import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class CreatePostTextfield extends StatelessWidget {
  const CreatePostTextfield({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return TextField(
      decoration: InputDecoration(
        hintText: LocaleKeys.post_create_caption_hint.tr(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderStrong, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: c.borderStrong, width: 2),
        ),
        contentPadding: EdgeInsets.zero,
        labelStyle: TextStyle(color: c.onSurface),
        hintStyle: TextStyle(color: c.onSurfaceMuted),
        prefixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(top: 16, start: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Text(LocaleKeys.post_create_talk_label.tr(), style: TextStyle(color: c.onSurfaceMuted)),
            ],
          ),
        )
      ),
      style: TextStyle(
        color: c.onSurface
      ),
      maxLines: null,
    );
  }
}
