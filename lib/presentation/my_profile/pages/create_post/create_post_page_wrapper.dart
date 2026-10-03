// ignore_for_file: use_build_context_synchronously

import 'dart:developer';
import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/domain/dto/request/create_post_request.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:hangout/presentation/my_profile/controller/create_post_controller/create_post_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/fullscreen_step_one.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/step_one_media.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/gallery_picker_sheet.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/post_step_footer.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/post_step_two_caption.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_choice_sheet.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/photo_cropper.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/video_cropper.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';

class CreatePostPageWrapper extends StatefulWidget {
  const CreatePostPageWrapper({super.key});

  @override
  State<CreatePostPageWrapper> createState() => _CreatePostPageWrapperState();
}

class _CreatePostPageWrapperState extends State<CreatePostPageWrapper> {
  List<File> media = [];
  final ScrollController mediaScrollController = ScrollController();
  final MentionTagTextEditingController captionController =
      MentionTagTextEditingController();
  CaptureAspectRatio _aspect = CaptureAspectRatio.square;
  late AuthorIdentity _author = _buildMeFromProfile();

  bool _isProduct = false;
  final TextEditingController _priceController = TextEditingController();

  int _currentStep = 0;

  bool get _useFullscreenForStepZero =>
      _currentStep == 0 && _aspect == CaptureAspectRatio.vertical;

  AuthorIdentity _buildMeFromProfile() {
    final me = context.read<MyProfileBloc>().user;
    return MeAuthor(
      userId: me?.id ?? '',
      displayName: me?.displayName?.isNotEmpty == true
          ? me!.displayName!
          : (me?.username ?? LocaleKeys.post_create_self_fallback_name.tr()),
      imageUrl: me?.avatarUrl,
    );
  }

  @override
  void dispose() {
    captionController.dispose();
    mediaScrollController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _setAspect(CaptureAspectRatio next) {
    setState(() => _aspect = next);
  }

  void _removeMedia(int index) {
    setState(() => media.removeAt(index));
  }

  Future<void> _openGalleryPicker() async {
    final picked = await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => GalleryPickerSheet(maxSelection: 15),
    );
    if (picked != null && picked.isNotEmpty) {
      await _onGalleryPicked(picked);
    }
  }

  Future<void> _onCaptured(CapturedMedia captured) async {
    if (media.isEmpty && captured.aspect != _aspect) {
      _setAspect(captured.aspect);
    }
    if (captured.aspect == CaptureAspectRatio.vertical) {
      if (!captured.isVideo) {
        appToast.info(LocaleKeys.post_create_aspect_video_only_toast.tr());
        return;
      }
      if (media.isNotEmpty) {
        appToast.info(LocaleKeys.post_create_aspect_one_video_only_toast.tr());
        return;
      }
    }
    if (captured.isVideo) {
      final processed = await cropVideoWithLoadingDialog(
        context: context,
        file: captured.file,
        aspect: captured.aspect,
      );
      if (!mounted) return;
      setState(() => media.add(processed));
      return;
    }
    final cropped = await openPhotoCropper(
      file: captured.file,
      aspect: captured.aspect,
    );
    if (cropped == null || !mounted) return;
    setState(() => media.add(cropped));
  }

  Future<void> _onGalleryPicked(List<File> files) async {
    if (media.isEmpty) {
      final chosen = await showAspectChoiceSheet(context, initial: _aspect);
      if (!mounted) return;
      if (chosen == null) return;
      if (chosen != _aspect) setState(() => _aspect = chosen);
    }
    if (_aspect == CaptureAspectRatio.vertical) {
      if (media.isNotEmpty) {
        appToast.info(LocaleKeys.post_create_aspect_one_video_only_toast.tr());
        return;
      }
      final firstVideo = files.firstWhere(
        (f) => mediaTypeFromContentType(contentTypeFromFile(f)) == 'video',
        orElse: () => File(''),
      );
      if (firstVideo.path.isEmpty) {
        appToast.info(LocaleKeys.post_create_aspect_video_only_toast.tr());
        return;
      }
      final processed = await cropVideoWithLoadingDialog(
        context: context,
        file: firstVideo,
        aspect: _aspect,
      );
      if (!mounted) return;
      setState(() => media.add(processed));
      if (files.length > 1) {
        appToast.info(LocaleKeys.post_create_aspect_one_video_only_toast.tr());
      }
      return;
    }
    for (final file in files) {
      final isVideo =
          mediaTypeFromContentType(contentTypeFromFile(file)) == 'video';
      if (isVideo) {
        if (!mounted) return;
        final processed = await cropVideoWithLoadingDialog(
          context: context,
          file: file,
          aspect: _aspect,
        );
        if (!mounted) return;
        setState(() => media.add(processed));
        continue;
      }
      final cropped = await openPhotoCropper(file: file, aspect: _aspect);
      if (!mounted) return;
      if (cropped != null) {
        setState(() => media.add(cropped));
      }
    }
  }

  void _goToCaption() {
    if (media.isEmpty) {
      appToast.info(LocaleKeys.post_create_no_media_toast.tr());
      return;
    }
    setState(() => _currentStep = 1);
  }

  void _goBackToMedia() {
    setState(() => _currentStep = 0);
  }

  void _submit() {
    if (media.isEmpty) {
      appToast.info(LocaleKeys.post_create_no_media_toast.tr());
      return;
    }
    final mentionedUsers = captionController.mentions
        .where((m) => m.type == 'user')
        .map((m) => m.id.toString())
        .toList();
    final mentionedVenues = captionController.mentions
        .where((m) => m.type == 'venue')
        .map((m) => m.id.toString())
        .toList();
    log('mentionedUsers: $mentionedUsers');
    log('mentionedVenues: $mentionedVenues');

    final asVenueId = switch (_author) {
      VenueAuthor(:final venueId) => venueId,
      MeAuthor() => null,
    };

    final isVenuePost = asVenueId != null;
    bool? sendIsProduct;
    double? sendPrice;
    if (isVenuePost && _isProduct) {
      final parsed = double.tryParse(_priceController.text.trim());
      if (parsed == null || parsed <= 0) {
        appToast.error(LocaleKeys.post_create_invalid_price_toast.tr());
        return;
      }
      sendIsProduct = true;
      sendPrice = parsed;
    }

    context.read<CreatePostBloc>().add(
          AddNewPost(
            CreatePostRequest(
              caption: captionController.getText,
              mentionedUserIds: mentionedUsers,
              mentionedVenueIds: mentionedVenues,
              isProduct: sendIsProduct,
              price: sendPrice,
            ),
            media,
            asVenueId,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_useFullscreenForStepZero) {
      return FullscreenStepOne(
        author: _author,
        onAuthorChanged: (next) => setState(() => _author = next),
        aspect: _aspect,
        aspectLocked: media.isNotEmpty,
        onAspectChanged: _setAspect,
        onCaptured: _onCaptured,
        media: media,
        mediaScrollController: mediaScrollController,
        onAddMediaTap: _openGalleryPicker,
        onRemoveMedia: _removeMedia,
        onNext: _goToCaption,
        onBack: () => Navigator.of(context).maybePop(),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    StepOneMedia(
                      author: _author,
                      onAuthorChanged: (next) =>
                          setState(() => _author = next),
                      aspect: _aspect,
                      aspectLocked: media.isNotEmpty,
                      onAspectChanged: _setAspect,
                      onCaptured: _onCaptured,
                      media: media,
                      mediaScrollController: mediaScrollController,
                      onAddMediaTap: _openGalleryPicker,
                      onRemoveMedia: _removeMedia,
                      ratios: null,
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                    PostStepTwoCaption(
                      author: _author,
                      onAuthorChanged: (next) =>
                          setState(() => _author = next),
                      media: media,
                      mediaScrollController: mediaScrollController,
                      onAddMediaTap: _openGalleryPicker,
                      onRemoveMedia: _removeMedia,
                      captionController: captionController,
                      isProduct: _isProduct,
                      priceController: _priceController,
                      onProductToggle: (v) => setState(() => _isProduct = v),
                      onBack: () => Navigator.of(context).maybePop(),
                    ),
                  ],
                ),
              ),
              PostStepFooter(
                currentStep: _currentStep,
                onNext: _goToCaption,
                onBack: _goBackToMedia,
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
