// ignore_for_file: use_build_context_synchronously

import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_hangout_request.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/get_mime_type_from_file.dart';
import 'package:hangout/presentation/my_profile/controller/create_hangout_controller/create_hangout_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/hangouts/my_hangouts_bloc.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/date_time_picker_sheet.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/fullscreen_step_one.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/step_footer.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/step_one_media.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/step_two_details.dart';
import 'package:hangout/presentation/my_profile/pages/create_post/widgets/gallery_picker_sheet.dart';
import 'package:hangout/presentation/my_profile/widgets/author_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_choice_sheet.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/photo_cropper.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/video_cropper.dart';

class CreateHangoutPageWrapper extends StatefulWidget {

  final VenueSearchResultDto? initialVenue;

  const CreateHangoutPageWrapper({super.key, this.initialVenue});

  @override
  State<CreateHangoutPageWrapper> createState() =>
      _CreateHangoutPageWrapperState();
}

class _CreateHangoutPageWrapperState extends State<CreateHangoutPageWrapper> {
  List<File> media = [];
  final ScrollController _mediaScrollController = ScrollController();
  CaptureAspectRatio _aspect = CaptureAspectRatio.square;

  late AuthorIdentity _author = _buildMeFromProfile();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _inviteMessageController =
      TextEditingController();
  late VenueSearchResultDto? _selectedVenue = widget.initialVenue;
  VenueResponse? _selectedVenueDetails;
  int _venueDetailsSeq = 0;
  bool _venueDetailsLoading = false;

  VenueLocationResponse? _selectedBranch;
  DateTime? _scheduledAt;
  String _joinPolicy = 'OPEN';
  String _postVisibility = 'PUBLIC';
  List<UserSearchResultDto> _invitees = const [];

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    if (_selectedVenue != null) {
      _loadVenueDetails(_selectedVenue!.id);
    }
  }

  @override
  void dispose() {
    _mediaScrollController.dispose();
    _descriptionController.dispose();
    _inviteMessageController.dispose();
    super.dispose();
  }

  AuthorIdentity _buildMeFromProfile() {
    final me = context.read<MyProfileBloc>().user;
    return MeAuthor(
      userId: me?.id ?? '',
      displayName: me?.displayName?.isNotEmpty == true
          ? me!.displayName!
          : (me?.username ?? LocaleKeys.hangout_create_self_fallback_name.tr()),
      imageUrl: me?.avatarUrl,
    );
  }

  Future<void> _onCaptured(CapturedMedia captured) async {

    if (media.isEmpty && captured.aspect != _aspect) {
      setState(() => _aspect = captured.aspect);
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
      final chosen = await showAspectChoiceSheet(
        context,
        initial: _aspect,
        ratios: hangoutAspectRatios,
      );
      if (!mounted) return;
      if (chosen == null) return;
      if (chosen != _aspect) setState(() => _aspect = chosen);
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

  Future<void> _openGalleryPicker() async {
    final picked = await showModalBottomSheet<List<File>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const GalleryPickerSheet(maxSelection: 10),
    );
    if (picked != null && picked.isNotEmpty) {
      await _onGalleryPicked(picked);
    }
  }

  void _removeMedia(int index) {
    setState(() => media.removeAt(index));
  }

  Future<void> _loadVenueDetails(String venueId) async {
    final seq = ++_venueDetailsSeq;
    setState(() => _venueDetailsLoading = true);
    try {
      final res = await serviceLocator.get<ApiService>().getVenue(venueId);
      if (!mounted || seq != _venueDetailsSeq) return;
      final details = res.success ? res.data : null;
      setState(() {
        _selectedVenueDetails = details;
        _venueDetailsLoading = false;
        _selectedBranch = _autoSelectBranch(details);
      });
    } catch (_) {
      if (!mounted || seq != _venueDetailsSeq) return;
      setState(() {
        _selectedVenueDetails = null;
        _venueDetailsLoading = false;
        _selectedBranch = null;
      });
    }
  }

  VenueLocationResponse? _autoSelectBranch(VenueResponse? details) {
    if (details == null) return null;
    if (details.locations.length == 1) return details.locations.first;
    return null;
  }

  void _onVenuePicked(VenueSearchResultDto venue) {
    setState(() {
      _selectedVenue = venue;
      _selectedVenueDetails = null;
      _selectedBranch = null;
    });
    _loadVenueDetails(venue.id);
  }

  void _clearVenue() {
    setState(() {
      _selectedVenue = null;
      _selectedVenueDetails = null;
      _venueDetailsSeq++;
      _venueDetailsLoading = false;
      _selectedBranch = null;
    });
  }

  void _onBranchPicked(VenueLocationResponse branch) {
    setState(() => _selectedBranch = branch);
  }

  Future<void> _pickDateTime() async {
    final picked = await showDateTimePickerSheet(
      context,
      initial: _scheduledAt,
    );
    if (picked == null || !mounted) return;
    setState(() => _scheduledAt = picked);
  }

  bool _validateDetails() {
    if (_selectedVenue == null) {
      appToast.info(LocaleKeys.hangout_create_pick_venue_toast.tr());
      return false;
    }
    final branches = _selectedVenueDetails?.locations ?? const [];
    if (branches.length >= 2 && _selectedBranch == null) {
      appToast.info(LocaleKeys.hangout_create_branch_required_toast.tr());
      return false;
    }
    if (_scheduledAt == null) {
      appToast.info(LocaleKeys.hangout_create_pick_datetime_toast.tr());
      return false;
    }
    return true;
  }

  void _goToMedia() {
    if (!_validateDetails()) return;
    setState(() => _currentStep = 1);
  }

  void _submit() {
    if (!_validateDetails()) return;

    final inviteMessage = _inviteMessageController.text.trim();

    context.read<CreateHangoutBloc>().add(
          AddNewHangout(
            CreateHangoutRequest(
              venueId: _selectedVenue!.id,
              venueLocationId: _selectedBranch?.id,
              description: _descriptionController.text.trim().isEmpty
                  ? null
                  : _descriptionController.text.trim(),

              scheduledAt: _scheduledAt!.toUtc().toIso8601String(),
              joinPolicy: _joinPolicy,
              postVisibility: _postVisibility,
              inviteeUserIds: _invitees.isEmpty
                  ? null
                  : _invitees.map((u) => u.id).toList(),
              inviteMessage: (_invitees.isEmpty || inviteMessage.isEmpty)
                  ? null
                  : inviteMessage,
            ),
            media.isEmpty ? null : media,
            switch (_author) {
              VenueAuthor(:final venueId) => venueId,
              MeAuthor() => null,
            },
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentStep == 1 && _aspect == CaptureAspectRatio.vertical) {
      return FullscreenStepOne(
        author: _author,
        onAuthorChanged: (next) => setState(() => _author = next),
        aspect: _aspect,
        aspectLocked: media.isNotEmpty,
        onAspectChanged: (next) => setState(() => _aspect = next),
        onCaptured: _onCaptured,
        media: media,
        mediaScrollController: _mediaScrollController,
        onAddMediaTap: _openGalleryPicker,
        onRemoveMedia: _removeMedia,
        onNext: _submit,
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: IndexedStack(
                  index: _currentStep,
                  children: [
                    StepTwoDetails(
                      postVisibility: _postVisibility,
                      onPostVisibilityChanged: (v) =>
                          setState(() => _postVisibility = v),
                      descriptionController: _descriptionController,
                      selectedVenue: _selectedVenue,
                      selectedVenueDetails: _selectedVenueDetails,
                      venueDetailsLoading: _venueDetailsLoading,
                      onVenuePicked: _onVenuePicked,
                      onVenueCleared: _clearVenue,
                      selectedBranch: _selectedBranch,
                      onBranchPicked: _onBranchPicked,
                      scheduledAt: _scheduledAt,
                      onPickDateTime: _pickDateTime,
                      joinPolicy: _joinPolicy,
                      onJoinPolicyChanged: (v) =>
                          setState(() => _joinPolicy = v),
                      invitees: _invitees,
                      onInviteesChanged: (next) =>
                          setState(() => _invitees = next),
                      inviteMessageController: _inviteMessageController,
                    ),
                    StepOneMedia(
                      author: _author,
                      onAuthorChanged: (next) =>
                          setState(() => _author = next),
                      aspect: _aspect,
                      aspectLocked: media.isNotEmpty,
                      onAspectChanged: (next) =>
                          setState(() => _aspect = next),
                      onCaptured: _onCaptured,
                      media: media,
                      mediaScrollController: _mediaScrollController,
                      onAddMediaTap: _openGalleryPicker,
                      onRemoveMedia: _removeMedia,
                    ),
                  ],
                ),
              ),
              StepFooter(
                currentStep: _currentStep,
                onNext: _goToMedia,
                onBack: () => setState(() => _currentStep = 0),
                onSubmit: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<T?> openCreateHangoutPage<T>(
  BuildContext context, {
  VenueSearchResultDto? initialVenue,
}) {
  MyHangoutsBloc? myHangouts;
  try {
    myHangouts = context.read<MyHangoutsBloc>();
  } on ProviderNotFoundException catch (_) {
    myHangouts = null;
  }

  return Navigator.of(context).push<T>(
    MaterialPageRoute(
      builder: (_) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => CreateHangoutBloc()),
          if (myHangouts != null) BlocProvider.value(value: myHangouts),
        ],
        child: CreateHangoutPageWrapper(initialVenue: initialVenue),
      ),
    ),
  );
}
