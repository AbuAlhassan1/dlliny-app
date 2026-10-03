import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/media_strip.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/create_post_mention_textfield.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';

class PostStepTwoCaption extends StatelessWidget {
  final AuthorIdentity author;
  final ValueChanged<AuthorIdentity> onAuthorChanged;

  final List<File> media;
  final ScrollController mediaScrollController;

  final VoidCallback onAddMediaTap;
  final ValueChanged<int> onRemoveMedia;

  final MentionTagTextEditingController captionController;

  final bool isProduct;
  final TextEditingController priceController;
  final ValueChanged<bool> onProductToggle;

  final VoidCallback onBack;

  const PostStepTwoCaption({
    super.key,
    required this.author,
    required this.onAuthorChanged,
    required this.media,
    required this.mediaScrollController,
    required this.onAddMediaTap,
    required this.onRemoveMedia,
    required this.captionController,
    required this.isProduct,
    required this.priceController,
    required this.onProductToggle,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: 4,
              end: 12,
              top: 8,
              bottom: 4,
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: onBack,
                  icon: Icon(
                    TablerIcons.chevron_right,
                    color: context.c.onSurface,
                  ),
                  tooltip: LocaleKeys.post_create_step_back_tooltip.tr(),
                ),
                Expanded(
                  child: AuthorPickerSwitcher(
                    current: author,
                    onChanged: onAuthorChanged,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          MediaStrip(
            media: media,
            scrollController: mediaScrollController,
            onAddTap: onAddMediaTap,
            onRemove: onRemoveMedia,
          ),
          const SizedBox(height: 15),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CreatePostMentionTextfield(
              controller: captionController,
            ),
          ),
          if (author is VenueAuthor)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: _ProductToggleSection(
                isProduct: isProduct,
                priceController: priceController,
                onToggle: onProductToggle,
              ),
            ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _ProductToggleSection extends StatelessWidget {
  final bool isProduct;
  final TextEditingController priceController;
  final ValueChanged<bool> onToggle;
  const _ProductToggleSection({
    required this.isProduct,
    required this.priceController,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c.surfaceMuted,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                TablerIcons.shopping_bag,
                color: c.onSurfaceSecondary,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocaleKeys.post_create_is_product_label.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    Text(
                      LocaleKeys.post_create_is_product_subtitle.tr(),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 11,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: isProduct,
                onChanged: onToggle,
                activeThumbColor: c.onSurface,
              ),
            ],
          ),
          if (isProduct)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
              child: AppTextField(
                controller: priceController,
                label: LocaleKeys.post_create_price_label.tr(),
                hint: LocaleKeys.post_create_price_hint.tr(),
                requiredMark: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: false,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
