// ignore_for_file: use_build_context_synchronously

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/create_hangout_request.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/domain/dto/response/venue_location_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/hangout/quick_create/quick_hangout_pickers.dart';
import 'package:hangout/presentation/hangout/quick_create/quick_sheet_controller.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/aspect_frame_overlay.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_chip.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_create_button.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_hangout_header.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_hangout_media_layer.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/quick_media_strip.dart';
import 'package:hangout/presentation/hangout/quick_create/widgets/venue_selector.dart';
import 'package:hangout/presentation/my_profile/controller/create_hangout_controller/create_hangout_bloc.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/date_time_picker_sheet.dart';
import 'package:hangout/presentation/my_profile/pages/create_hangout/widgets/invitee_picker_field.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/aspect_ratio_picker.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/capture_aspect_ratio.dart';
import 'package:hangout/presentation/shared/widgets/media_capture/media_capture_camera.dart';

class QuickHangoutSheet extends StatefulWidget {
  final QuickSheetController controller;

  const QuickHangoutSheet({super.key, required this.controller});

  @override
  State<QuickHangoutSheet> createState() => _QuickHangoutSheetState();
}

class _QuickHangoutSheetState extends State<QuickHangoutSheet> {
  QuickSheetController get _controller => widget.controller;

  List<QuickMediaItem> _media = [];
  CaptureAspectRatio _aspect = CaptureAspectRatio.portrait;

  String? _venueId;
  String? _venueName;
  VenueResponse? _venueDetails;
  VenueLocationResponse? _branch;
  bool _venueLoading = false;
  int _venueSeq = 0;

  bool _isNow = true;
  DateTime? _scheduledAt;

  List<UserSearchResultDto> _invitees = const [];
  String _postVisibility = 'PUBLIC';
  String _joinPolicy = 'OPEN';

  void _closePanel() {
    FocusScope.of(context).unfocus();
    _controller.close();
  }

  void _onDragUpdate(DragUpdateDetails d) =>
      _controller.onDragUpdate(d.primaryDelta ?? 0);

  void _onDragEnd(DragEndDetails d) =>
      _controller.onDragEnd(d.primaryVelocity ?? 0);

  Future<void> _pickVenue() async {
    final picked = await showQuickVenuePicker(context, selectedId: _venueId);
    if (picked == null || !mounted) return;
    _selectVenue(picked.id, picked.name);
  }

  void _selectVenue(String id, String name) {
    if (id == _venueId) return;
    setState(() {
      _venueId = id;
      _venueName = name;
      _venueDetails = null;
      _branch = null;
      _venueLoading = true;
    });
    _loadVenueDetails(id);
  }

  Future<void> _loadVenueDetails(String venueId) async {
    final seq = ++_venueSeq;
    try {
      final res = await serviceLocator.get<ApiService>().getVenue(venueId);
      if (!mounted || seq != _venueSeq) return;
      final details = res.success ? res.data : null;
      setState(() {
        _venueDetails = details;
        _venueLoading = false;
        _branch = (details != null && details.locations.length == 1)
            ? details.locations.first
            : null;
      });
    } catch (_) {
      if (!mounted || seq != _venueSeq) return;
      setState(() {
        _venueDetails = null;
        _venueLoading = false;
        _branch = null;
      });
    }
  }

  Future<void> _pickBranch() async {
    final details = _venueDetails;
    if (details == null || details.locations.length < 2) return;
    final picked = await showQuickBranchPicker(
      context,
      venue: details,
      selected: _branch,
    );
    if (picked != null && mounted) setState(() => _branch = picked);
  }

  Future<void> _pickDateTime() async {
    final picked = await showDateTimePickerSheet(
      context,
      initial: _scheduledAt,
    );
    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _scheduledAt = picked;
        _isNow = false;
      });
    }
  }

  void _toggleNow() {
    if (_isNow) {
      setState(() => _isNow = false);
      _pickDateTime();
    } else {
      setState(() {
        _isNow = true;
        _scheduledAt = null;
      });
    }
  }

  Future<void> _pickInvitees() async {
    final updated = await showModalBottomSheet<List<UserSearchResultDto>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteePickerSheet(initial: _invitees),
    );
    if (updated != null && mounted) setState(() => _invitees = updated);
  }

  Future<void> _openPrivacy() async {
    final picked = await showQuickPrivacySheet(
      context,
      visibility: _postVisibility,
      join: _joinPolicy,
    );
    if (picked != null && mounted) {
      setState(() {
        _postVisibility = picked.visibility;
        _joinPolicy = picked.join;
      });
    }
  }

  void _onCaptured(CapturedMedia captured) {
    setState(() {
      _media = [..._media, QuickMediaItem(captured.file, captured.isVideo)];
    });
  }

  void _removeMedia(int index) {
    setState(() => _media = [..._media]..removeAt(index));
  }

  void _submit(BuildContext context) {
    if (_venueId == null) {
      appToast.info(
        context.pickBilingual(ar: 'اختر المكان أول', en: 'Pick a venue first'),
      );
      return;
    }
    final branches = _venueDetails?.locations ?? const [];
    if (branches.length >= 2 && _branch == null) {
      appToast.info(
        context.pickBilingual(ar: 'اختر الفرع', en: 'Pick a branch'),
      );
      return;
    }
    final when = _isNow ? DateTime.now() : _scheduledAt;
    if (when == null) {
      appToast.info(
        context.pickBilingual(ar: 'حدد وقت الطلعة', en: 'Pick a time'),
      );
      return;
    }
    if (_media.isEmpty) {
      appToast.info(
        context.pickBilingual(
          ar: 'صوّر صورة أو مقطع للطلعة',
          en: 'Capture a photo or clip',
        ),
      );
      return;
    }
    context.read<CreateHangoutBloc>().add(
      AddNewHangout(
        CreateHangoutRequest(
          venueId: _venueId!,
          venueLocationId: _branch?.id,
          scheduledAt: when.toUtc().toIso8601String(),
          joinPolicy: _joinPolicy,
          postVisibility: _postVisibility,
          inviteeUserIds: _invitees.isEmpty
              ? null
              : _invitees.map((u) => u.id).toList(),
        ),
        _media.map((m) => m.file).toList(),
        null,
      ),
    );
  }

  void _reset() {
    setState(() {
      _media = [];
      _aspect = CaptureAspectRatio.portrait;
      _venueId = null;
      _venueName = null;
      _venueDetails = null;
      _branch = null;
      _invitees = const [];
      _isNow = true;
      _scheduledAt = null;
      _postVisibility = 'PUBLIC';
      _joinPolicy = 'OPEN';
    });
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenH = mq.size.height;
    final expandedTop = mq.padding.top;
    _controller.dragRange = screenH - expandedTop;

    final buttonYFromBottom = mq.padding.bottom + 12 + 31;
    final panelH = screenH - expandedTop;
    final buttonAlignY =
        (((screenH - buttonYFromBottom - expandedTop) / panelH) * 2 - 1).clamp(
          -1.0,
          1.0,
        );

    return BlocProvider<CreateHangoutBloc>(
      create: (_) => CreateHangoutBloc(),
      child: Builder(
        builder: (context) =>
            BlocListener<CreateHangoutBloc, CreateHangoutState>(
              listener: (context, state) {
                if (state is CreateHangoutSuccess) {
                  appToast.success(
                    context.pickBilingual(
                      ar: 'انطلقت طلعتك!',
                      en: 'Your hangout is live!',
                    ),
                  );
                  _reset();
                  _closePanel();
                } else if (state is CreateHangoutError) {
                  appToast.error(
                    context.pickBilingual(
                      ar: 'تعذّر إنشاء الطلعة',
                      en: 'Could not create the hangout',
                    ),
                  );
                }
              },
              child: AnimatedBuilder(
                animation: _controller.animation,
                builder: (context, _) {
                  final t = _controller.animation.value.clamp(0.0, 1.0);
                  return Stack(
                    children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          ignoring: t < 0.02,
                          child: GestureDetector(
                            onTap: _closePanel,
                            child: Container(
                              color: Colors.black.withValues(alpha: 0.5 * t),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: expandedTop,
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: IgnorePointer(
                          ignoring: t < 0.98,
                          child: Padding(
                            padding: const EdgeInsets.all(0),
                            child: Opacity(
                              opacity: t,
                              child: Transform.scale(
                                scale: 0.1 + 0.9 * t,
                                alignment: Alignment(0, buttonAlignY),
                                child: _panel(context, t),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
      ),
    );
  }

  Widget _panel(BuildContext context, double t) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: ColoredBox(
        color: context.c.background,
        child: t > 0.05 ? _body(context) : const SizedBox.expand(),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    final hasMedia = _media.isNotEmpty;
    final cameraLive = _controller.animation.value > 0.15;

    return GestureDetector(
      onVerticalDragUpdate: _onDragUpdate,
      onVerticalDragEnd: _onDragEnd,
      child: Stack(
        fit: StackFit.expand,
        children: [
          QuickHangoutMediaLayer(
            cameraLive: cameraLive,
            aspect: _aspect,
            onCaptured: _onCaptured,
          ),
          AspectFrameOverlay(aspect: _aspect),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: QuickHangoutHeader(onClose: _closePanel),
          ),
          Positioned(
            top: 50,
            left: 15,
            right: 15,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      context.pickBilingual(
                        ar: 'وين الطلعة اليوم؟',
                        en: 'Where are we going today?',
                      ),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    SizedBox(width: 6),
                    VenueSelector(
                      selectedId: _venueId,
                      selectedName: _venueName,
                      loading: _venueLoading,
                      onSelect: _selectVenue,
                      onSearch: _pickVenue,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (hasMedia)
            Positioned(
              left: 12,
              right: 12,
              bottom: 156 + safeBottom,
              child: QuickMediaStrip(media: _media, onRemove: _removeMedia),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 104 + safeBottom,
            child: Column(
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [..._branchChips(context)],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._whenChips(context),
                    _inviteeChip(context),
                    _privacyChip(context),
                  ],
                ),
                SizedBox(height: 8),
                AspectRatioPicker(
                  current: _aspect,
                  locked: hasMedia,
                  ratios: const [
                    CaptureAspectRatio.square,
                    CaptureAspectRatio.portrait,
                    CaptureAspectRatio.landscape,
                    CaptureAspectRatio.vertical,
                  ],
                  onChanged: (a) => setState(() => _aspect = a),
                ),
              ],
            ),
          ),
          if (hasMedia)
            PositionedDirectional(
              end: 14,
              bottom: 40 + safeBottom,
              child: QuickCreateButton(
                count: _media.length,
                onSubmit: () => _submit(context),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _branchChips(BuildContext context) {
    if ((_venueDetails?.locations.length ?? 0) < 2) return const [];
    return [
      QuickChip(
        icon: TablerIcons.building,
        label: _branch == null
            ? context.pickBilingual(ar: 'الفرع', en: 'Branch')
            : context.pickBilingual(
                ar: _branch!.labelAr ?? _branch!.addressAr ?? 'الفرع',
                en: _branch!.labelEn ?? _branch!.addressEn ?? 'Branch',
              ),
        onTap: _pickBranch,
      ),
    ];
  }

  List<Widget> _whenChips(BuildContext context) {
    return [
      QuickChip(
        icon: TablerIcons.clock,
        label: context.pickBilingual(ar: 'الآن', en: 'Now'),
        active: _isNow,
        onTap: _toggleNow,
      ),
      if (!_isNow)
        QuickChip(
          icon: TablerIcons.calendar_event,
          label: _scheduledAt == null
              ? context.pickBilingual(ar: 'اختر الوقت', en: 'Pick time')
              : DateFormat(
                  'EEE d MMM • h:mm a',
                  context.locale.toString(),
                ).format(_scheduledAt!),
          onTap: _pickDateTime,
        ),
    ];
  }

  Widget _inviteeChip(BuildContext context) {
    return QuickChip(
      icon: TablerIcons.users_plus,
      label: _invitees.isEmpty
          ? context.pickBilingual(ar: 'ادعُ أصدقاء', en: 'Invite friends')
          : context.pickBilingual(
              ar: '${_invitees.length} مدعو',
              en: '${_invitees.length} invited',
            ),
      active: _invitees.isNotEmpty,
      onTap: _pickInvitees,
    );
  }

  Widget _privacyChip(BuildContext context) {
    final vis = switch (_postVisibility) {
      'FOLLOWERS' => context.pickBilingual(ar: 'المتابعين', en: 'Followers'),
      'INVITEES' => context.pickBilingual(ar: 'المدعوين', en: 'Invitees'),
      _ => context.pickBilingual(ar: 'عام', en: 'Public'),
    };
    final join = _joinPolicy == 'INVITE_ONLY'
        ? context.pickBilingual(ar: 'بالدعوة', en: 'Invite')
        : context.pickBilingual(ar: 'مفتوح', en: 'Open');
    return QuickChip(
      icon: _postVisibility == 'PUBLIC' ? TablerIcons.world : TablerIcons.lock,
      label: '$vis · $join',
      onTap: _openPrivacy,
    );
  }
}
