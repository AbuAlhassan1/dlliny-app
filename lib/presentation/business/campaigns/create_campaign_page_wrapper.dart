import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/request/campaign_creative_payload.dart';
import 'package:hangout/domain/dto/request/create_campaign_request.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/domain/dto/response/post_response.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/business/campaigns/widgets/cc_category_multi_picker.dart';
import 'package:hangout/presentation/business/campaigns/widgets/cc_district_multi_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';

class CreateCampaignPageWrapper extends StatefulWidget {
  final VenueResponse venue;
  const CreateCampaignPageWrapper({super.key, required this.venue});

  static Future<bool?> push(BuildContext context, VenueResponse venue) {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => CreateCampaignPageWrapper(venue: venue),
      ),
    );
  }

  @override
  State<CreateCampaignPageWrapper> createState() =>
      _CreateCampaignPageWrapperState();
}

class _CreateCampaignPageWrapperState extends State<CreateCampaignPageWrapper> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final PageController _pageController = PageController();
  int _step = 0;

  String? _placement;

  String? _sourceType;

  PostResponse? _selectedPost;
  HangoutResponse? _selectedHangout;
  File? _customMediaFile;
  String? _customMediaKey;
  String? _customMediaType;
  bool _uploadingMedia = false;
  final TextEditingController _customCaption = TextEditingController();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _budget = TextEditingController();
  DateTime? _startsAt;
  DateTime? _endsAt;
  Set<String> _targetDistricts = {};
  Set<int> _targetCategories = {};

  final TextEditingController _ctaText = TextEditingController();
  final TextEditingController _ctaUrl = TextEditingController();
  String _ctaScheme = 'https';

  bool _submitting = false;

  @override
  void dispose() {
    _pageController.dispose();
    _customCaption.dispose();
    _name.dispose();
    _budget.dispose();
    _ctaText.dispose();
    _ctaUrl.dispose();
    super.dispose();
  }

  void _goTo(int step) {
    setState(() => _step = step);
    _pageController.animateToPage(
      step,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _placement != null;
      case 1:
        return _sourceType != null;
      case 2:
        switch (_sourceType) {
          case 'POST':
            return _selectedPost != null;
          case 'HANGOUT':
            return _selectedHangout != null;
          case 'CUSTOM':
            return _customMediaKey != null && !_uploadingMedia;
        }
        return false;
      case 3:
        if (_name.text.trim().isEmpty) return false;
        final b = double.tryParse(_budget.text.trim());
        if (b == null || b <= 0) return false;
        if (_sourceType != 'HANGOUT') {
          if (_startsAt == null || _endsAt == null) return false;
          if (!_endsAt!.isAfter(_startsAt!)) return false;
        }
        return true;
      case 4:
        return !_submitting;
    }
    return false;
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    final creative = _buildCreative();
    if (creative == null) {
      setState(() => _submitting = false);
      appToast.error(LocaleKeys.business_campaigns_create_missing_creative_toast.tr());
      return;
    }

    final body = CreateCampaignRequest(
      venueId: widget.venue.id,
      name: _name.text.trim(),
      type: _placement!,
      budget: double.parse(_budget.text.trim()),
      startsAt: _sourceType == 'HANGOUT' ? null : _startsAt!.toUtc().toIso8601String(),
      endsAt: _sourceType == 'HANGOUT' ? null : _endsAt!.toUtc().toIso8601String(),
      targetDistricts:
          _targetDistricts.isEmpty ? null : _targetDistricts.toList(),
      targetCategories:
          _targetCategories.isEmpty ? null : _targetCategories.toList(),
      creative: creative,
    );

    try {
      final res = await _api.createCampaign(body);
      if (!mounted) return;
      if (res.success && res.data != null) {
        appToast.success(LocaleKeys.business_campaigns_create_success_toast.tr());
        Navigator.of(context).pop(true);
        return;
      }
      appToast.error(res.error ?? LocaleKeys.business_campaigns_create_submit_failed_fallback.tr());
    } on DioException catch (e) {
      if (mounted) appToast.error(e.message ?? LocaleKeys.common_connection_failed.tr());
    } catch (e) {
      if (mounted) {
        appToast.error(LocaleKeys.business_campaigns_create_submit_no_response_toast.tr());
        Navigator.of(context).pop(true);
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  CampaignCreativePayload? _buildCreative() {
    final ctaText = _ctaText.text.trim();
    final ctaUrl = _composeCtaUrl();
    final hasCta = ctaText.isNotEmpty && ctaUrl != null && ctaUrl.isNotEmpty;
    final cText = hasCta ? ctaText : null;
    final cUrl = hasCta ? ctaUrl : null;
    switch (_sourceType) {
      case 'POST':
        if (_selectedPost == null) return null;
        return CampaignCreativePayload.boostPost(
          postId: _selectedPost!.id,
          ctaText: cText,
          ctaUrl: cUrl,
        );
      case 'HANGOUT':
        if (_selectedHangout == null) return null;
        return CampaignCreativePayload.boostHangout(
          hangoutId: _selectedHangout!.id,
          ctaText: cText,
          ctaUrl: cUrl,
        );
      case 'CUSTOM':
        if (_customMediaKey == null || _customMediaType == null) return null;
        return CampaignCreativePayload.custom(
          mediaKey: _customMediaKey!,
          mediaType: _customMediaType!,
          caption: _customCaption.text.trim().isEmpty
              ? null
              : _customCaption.text.trim(),
          ctaText: cText,
          ctaUrl: cUrl,
        );
    }
    return null;
  }

  String? _composeCtaUrl() {
    final raw = _ctaUrl.text.trim();
    if (raw.isEmpty) return null;
    if (raw.contains('://') || raw.startsWith('tel:')) return raw;
    return switch (_ctaScheme) {
      'https' => 'https://$raw',
      'hangout' => 'hangout://$raw',
      'tel' => 'tel:$raw',
      'whatsapp' => 'whatsapp://send?phone=$raw',
      _ => raw,
    };
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
        title: Text(
          LocaleKeys.business_campaigns_create_page_title.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            _Stepper(currentStep: _step, totalSteps: 5),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PlacementStep(
                    selected: _placement,
                    isOnlineOnly: widget.venue.onlineOnly,
                    onPicked: (p) => setState(() => _placement = p),
                  ),
                  _CreativeTypeStep(
                    selected: _sourceType,
                    onPicked: (t) => setState(() => _sourceType = t),
                  ),
                  _SourceStep(
                    sourceType: _sourceType,
                    venueId: widget.venue.id,
                    selectedPost: _selectedPost,
                    onPickPost: (p) => setState(() => _selectedPost = p),
                    selectedHangout: _selectedHangout,
                    onPickHangout: (h) => setState(() => _selectedHangout = h),
                    customMediaFile: _customMediaFile,
                    customMediaKey: _customMediaKey,
                    customMediaType: _customMediaType,
                    uploadingMedia: _uploadingMedia,
                    onPickCustomMedia: _pickAndUploadMedia,
                    customCaption: _customCaption,
                  ),
                  _DetailsStep(
                    sourceType: _sourceType,
                    name: _name,
                    budget: _budget,
                    startsAt: _startsAt,
                    endsAt: _endsAt,
                    onPickStart: (d) => setState(() => _startsAt = d),
                    onPickEnd: (d) => setState(() => _endsAt = d),
                    targetDistricts: _targetDistricts,
                    onEditDistricts: () async {
                      final next = await CcDistrictMultiPicker.show(
                        context,
                        initial: _targetDistricts,
                      );
                      if (next != null) {
                        setState(() => _targetDistricts = next);
                      }
                    },
                    targetCategories: _targetCategories,
                    onEditCategories: () async {
                      final next = await CcCategoryMultiPicker.show(
                        context,
                        initial: _targetCategories,
                      );
                      if (next != null) {
                        setState(() => _targetCategories = next);
                      }
                    },
                    ctaText: _ctaText,
                    ctaUrl: _ctaUrl,
                    ctaScheme: _ctaScheme,
                    onPickCtaScheme: (s) => setState(() => _ctaScheme = s),
                  ),
                  _ReviewStep(
                    venue: widget.venue,
                    placement: _placement,
                    sourceType: _sourceType,
                    selectedPost: _selectedPost,
                    selectedHangout: _selectedHangout,
                    customMediaFile: _customMediaFile,
                    customCaption: _customCaption.text,
                    name: _name.text,
                    budget: _budget.text,
                    startsAt: _startsAt,
                    endsAt: _endsAt,
                    targetDistricts: _targetDistricts,
                    targetCategories: _targetCategories,
                    ctaText: _ctaText.text,
                    ctaUrl: _composeCtaUrl(),
                  ),
                ],
              ),
            ),
            _ActionBar(
              step: _step,
              canAdvance: _canAdvance,
              submitting: _submitting,
              onBack: _step == 0
                  ? null
                  : () => _goTo(_step - 1),
              onNext: _step == 4
                  ? _submit
                  : () => _goTo(_step + 1),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadMedia() async {
    final picker = ImagePicker();
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(TablerIcons.photo),
              title: Text(
                LocaleKeys.common_image.tr(),
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
              ),
              onTap: () => Navigator.of(context).pop('image'),
            ),
            ListTile(
              leading: const Icon(TablerIcons.video),
              title: Text(
                LocaleKeys.common_video.tr(),
                style: const TextStyle(fontFamily: 'IBMPlexSansArabic'),
              ),
              onTap: () => Navigator.of(context).pop('video'),
            ),
          ],
        ),
      ),
    );
    if (choice == null) return;

    final picked = choice == 'image'
        ? await picker.pickImage(source: ImageSource.gallery)
        : await picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;

    final file = File(picked.path);
    final mime = lookupMimeType(picked.path) ??
        (choice == 'image' ? 'image/jpeg' : 'video/mp4');

    setState(() {
      _customMediaFile = file;
      _customMediaType = choice;
      _customMediaKey = null;
      _uploadingMedia = true;
    });

    try {
      final presignRes = await _api.getCampaignMediaUploadUrl(mime);
      if (!presignRes.success || presignRes.data == null) {
        throw Exception(presignRes.error ?? LocaleKeys.business_campaigns_create_upload_url_failed.tr());
      }
      final presign = presignRes.data!;

      final dio = Dio();
      final bytes = await file.readAsBytes();
      final put = await dio.put<void>(
        presign.uploadUrl,
        data: Stream.fromIterable([bytes]),
        options: Options(
          headers: {
            'Content-Type': mime,
            'Content-Length': bytes.length.toString(),
          },
        ),
      );
      if (put.statusCode != null &&
          put.statusCode! >= 200 &&
          put.statusCode! < 300) {
        if (!mounted) return;
        setState(() {
          _customMediaKey = presign.key;
          _uploadingMedia = false;
        });
      } else {
        throw Exception('S3 PUT failed: ${put.statusCode}');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingMedia = false);
        appToast.error(LocaleKeys.business_campaigns_create_upload_failed_toast.tr());
      }
    }
  }
}

class _Stepper extends StatelessWidget {
  final int currentStep;
  final int totalSteps;
  const _Stepper({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: Row(
        children: [
          for (var i = 0; i < totalSteps; i++) ...[
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= currentStep ? c.primary : c.surfaceMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (i < totalSteps - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  final int step;
  final bool canAdvance;
  final bool submitting;
  final VoidCallback? onBack;
  final VoidCallback? onNext;

  const _ActionBar({
    required this.step,
    required this.canAdvance,
    required this.submitting,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        child: Row(
          children: [
            if (onBack != null) ...[
              Expanded(
                child: OutlinedButton(
                  onPressed: onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: c.onSurface,
                    side: BorderSide(color: c.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    LocaleKeys.common_previous.tr(),
                    style: const TextStyle(
                      fontFamily: 'IBMPlexSansArabic',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: onBack == null ? 1 : 1,
              child: FilledButton(
                onPressed: canAdvance ? onNext : null,
                style: FilledButton.styleFrom(
                  backgroundColor: c.onSurface,
                  foregroundColor: c.background,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: submitting
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: c.background,
                        ),
                      )
                    : Text(
                        (step == 4
                                ? LocaleKeys.business_campaigns_create_submit_button_create
                                : LocaleKeys.common_next)
                            .tr(),
                        style: const TextStyle(
                          fontFamily: 'IBMPlexSansArabic',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlacementStep extends StatelessWidget {
  final String? selected;
  final bool isOnlineOnly;
  final ValueChanged<String> onPicked;

  const _PlacementStep({
    required this.selected,
    required this.isOnlineOnly,
    required this.onPicked,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step1_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step1_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: TablerIcons.layout_list,
          title: LocaleKeys.business_campaigns_create_step1_feed_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step1_feed_subtitle.tr(),
          selected: selected == 'feed_card',
          onTap: () => onPicked('feed_card'),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: TablerIcons.movie,
          title: LocaleKeys.business_campaigns_create_step1_reels_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step1_reels_subtitle.tr(),
          selected: selected == 'reels_placement',
          onTap: () => onPicked('reels_placement'),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: TablerIcons.map_pin,
          title: LocaleKeys.business_campaigns_create_step1_map_title.tr(),
          subtitle: isOnlineOnly
              ? LocaleKeys.business_campaigns_create_step1_map_unavailable.tr()
              : LocaleKeys.business_campaigns_create_step1_map_subtitle.tr(),
          selected: selected == 'map_pin',
          disabled: isOnlineOnly,
          onTap: () {
            if (isOnlineOnly) return;
            onPicked('map_pin');
          },
        ),
      ],
    );
  }
}

class _CreativeTypeStep extends StatelessWidget {
  final String? selected;
  final ValueChanged<String> onPicked;

  const _CreativeTypeStep({required this.selected, required this.onPicked});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step2_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step2_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        _OptionTile(
          icon: TablerIcons.article,
          title: LocaleKeys.business_campaigns_create_step2_post_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step2_post_subtitle.tr(),
          selected: selected == 'POST',
          onTap: () => onPicked('POST'),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: TablerIcons.calendar_event,
          title: LocaleKeys.business_campaigns_create_step2_hangout_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step2_hangout_subtitle.tr(),
          selected: selected == 'HANGOUT',
          onTap: () => onPicked('HANGOUT'),
        ),
        const SizedBox(height: 10),
        _OptionTile(
          icon: TablerIcons.sparkles,
          title: LocaleKeys.business_campaigns_create_step2_custom_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step2_custom_subtitle.tr(),
          selected: selected == 'CUSTOM',
          onTap: () => onPicked('CUSTOM'),
        ),
      ],
    );
  }
}

class _SourceStep extends StatelessWidget {
  final String? sourceType;
  final String venueId;
  final PostResponse? selectedPost;
  final ValueChanged<PostResponse> onPickPost;
  final HangoutResponse? selectedHangout;
  final ValueChanged<HangoutResponse> onPickHangout;
  final File? customMediaFile;
  final String? customMediaKey;
  final String? customMediaType;
  final bool uploadingMedia;
  final VoidCallback onPickCustomMedia;
  final TextEditingController customCaption;

  const _SourceStep({
    required this.sourceType,
    required this.venueId,
    required this.selectedPost,
    required this.onPickPost,
    required this.selectedHangout,
    required this.onPickHangout,
    required this.customMediaFile,
    required this.customMediaKey,
    required this.customMediaType,
    required this.uploadingMedia,
    required this.onPickCustomMedia,
    required this.customCaption,
  });

  @override
  Widget build(BuildContext context) {
    switch (sourceType) {
      case 'POST':
        return _VenuePostPicker(
          venueId: venueId,
          selected: selectedPost,
          onPick: onPickPost,
        );
      case 'HANGOUT':
        return _VenueHangoutPicker(
          venueId: venueId,
          selected: selectedHangout,
          onPick: onPickHangout,
        );
      case 'CUSTOM':
        return _CustomCreativeForm(
          mediaFile: customMediaFile,
          mediaKey: customMediaKey,
          mediaType: customMediaType,
          uploading: uploadingMedia,
          onPick: onPickCustomMedia,
          caption: customCaption,
        );
    }
    return const SizedBox.shrink();
  }
}

class _VenuePostPicker extends StatefulWidget {
  final String venueId;
  final PostResponse? selected;
  final ValueChanged<PostResponse> onPick;
  const _VenuePostPicker({
    required this.venueId,
    required this.selected,
    required this.onPick,
  });

  @override
  State<_VenuePostPicker> createState() => _VenuePostPickerState();
}

class _VenuePostPickerState extends State<_VenuePostPicker> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<PostResponse>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.listPublicVenuePosts(widget.venueId, size: 50);
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() {
          _items = res.data!.content;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.error ?? LocaleKeys.business_campaigns_create_step3_posts_load_failed.tr();
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? LocaleKeys.common_connection_failed.tr();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      );
    }
    final items = _items!;
    if (items.isEmpty) {
      return _EmptyStep(
        icon: TablerIcons.photo_off,
        title: LocaleKeys.business_campaigns_create_step3_posts_empty_title.tr(),
        subtitle: LocaleKeys.business_campaigns_create_step3_posts_empty_subtitle.tr(),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step3_posts_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step3_posts_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        for (final p in items) ...[
          _PostRow(
            post: p,
            selected: widget.selected?.id == p.id,
            onTap: () => widget.onPick(p),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _PostRow extends StatelessWidget {
  final PostResponse post;
  final bool selected;
  final VoidCallback onTap;
  const _PostRow({
    required this.post,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final thumbUrl = post.media.isNotEmpty ? post.media.first.url : null;
    return Material(
      color: c.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: thumbUrl != null && thumbUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: thumbUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, _, _) => Container(
                            color: c.surfaceMuted,
                            alignment: Alignment.center,
                            child: Icon(
                              TablerIcons.photo,
                              color: c.onSurfaceSecondary,
                            ),
                          ),
                        )
                      : Container(
                          color: c.surfaceMuted,
                          alignment: Alignment.center,
                          child: Icon(
                            TablerIcons.photo,
                            color: c.onSurfaceSecondary,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  post.caption?.isEmpty != false
                      ? '(بدون نص)'
                      : post.caption!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 13,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
              if (selected)
                Icon(TablerIcons.check, color: c.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _VenueHangoutPicker extends StatefulWidget {
  final String venueId;
  final HangoutResponse? selected;
  final ValueChanged<HangoutResponse> onPick;
  const _VenueHangoutPicker({
    required this.venueId,
    required this.selected,
    required this.onPick,
  });

  @override
  State<_VenueHangoutPicker> createState() => _VenueHangoutPickerState();
}

class _VenueHangoutPickerState extends State<_VenueHangoutPicker> {
  final ApiService _api = serviceLocator.get<ApiService>();
  List<HangoutResponse>? _items;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final res = await _api.listVenueHangouts(widget.venueId);
      if (!mounted) return;
      if (res.success && res.data != null) {
        final now = DateTime.now();
        final future = res.data!
            .where((h) {
              final dt = DateTime.tryParse(h.scheduledAt);
              return dt != null && dt.isAfter(now);
            })
            .toList(growable: false);
        setState(() {
          _items = future;
          _loading = false;
        });
      } else {
        setState(() {
          _error = res.error ?? LocaleKeys.business_campaigns_create_step3_hangouts_load_failed.tr();
          _loading = false;
        });
      }
    } on DioException catch (e) {
      if (mounted) {
        setState(() {
          _error = e.message ?? LocaleKeys.common_connection_failed.tr();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(
          color: c.onSurface,
          strokeWidth: 1.5,
        ),
      );
    }
    if (_error != null) {
      return Center(
        child: Text(
          _error!,
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      );
    }
    final items = _items!;
    if (items.isEmpty) {
      return _EmptyStep(
        icon: TablerIcons.calendar_off,
        title: LocaleKeys.business_campaigns_create_step3_hangouts_empty_title.tr(),
        subtitle: LocaleKeys.business_campaigns_create_step3_hangouts_empty_subtitle.tr(),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step3_hangouts_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step3_hangouts_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        for (final h in items) ...[
          _HangoutRow(
            hangout: h,
            selected: widget.selected?.id == h.id,
            onTap: () => widget.onPick(h),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _HangoutRow extends StatelessWidget {
  final HangoutResponse hangout;
  final bool selected;
  final VoidCallback onTap;
  const _HangoutRow({
    required this.hangout,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Material(
      color: c.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: selected ? c.primary : c.border,
              width: selected ? 1.6 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: c.surfaceMuted,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  TablerIcons.calendar_event,
                  color: c.onSurfaceSecondary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hangout.description?.isNotEmpty == true
                          ? hangout.description!
                          : '(بدون وصف)',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: c.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatIso(hangout.scheduledAt),
                      style: TextStyle(
                        color: c.onSurfaceSecondary,
                        fontSize: 11,
                        fontFamily: 'IBMPlexSansArabic',
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(TablerIcons.check, color: c.primary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomCreativeForm extends StatelessWidget {
  final File? mediaFile;
  final String? mediaKey;
  final String? mediaType;
  final bool uploading;
  final VoidCallback onPick;
  final TextEditingController caption;

  const _CustomCreativeForm({
    required this.mediaFile,
    required this.mediaKey,
    required this.mediaType,
    required this.uploading,
    required this.onPick,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step3_custom_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step3_custom_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: uploading ? null : onPick,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: c.border),
            ),
            height: 200,
            alignment: Alignment.center,
            child: uploading
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: c.onSurface,
                        strokeWidth: 1.5,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        LocaleKeys.business_campaigns_create_step3_uploading.tr(),
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontFamily: 'IBMPlexSansArabic',
                          fontSize: 12,
                        ),
                      ),
                    ],
                  )
                : mediaFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: mediaType == 'image'
                            ? Image.file(mediaFile!, fit: BoxFit.cover)
                            : Container(
                                color: Colors.black,
                                alignment: Alignment.center,
                                child: Icon(
                                  TablerIcons.video,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            TablerIcons.upload,
                            color: c.onSurfaceSecondary,
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            LocaleKeys.business_campaigns_create_step3_upload_prompt.tr(),
                            style: TextStyle(
                              color: c.onSurface,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'IBMPlexSansArabic',
                            ),
                          ),
                        ],
                      ),
          ),
        ),
        if (mediaFile != null && !uploading && mediaKey == null) ...[
          const SizedBox(height: 6),
          Text(
            LocaleKeys.business_campaigns_create_step3_upload_failed_tap.tr(),
            style: TextStyle(
              color: c.danger,
              fontSize: 12,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          LocaleKeys.business_campaigns_create_step3_caption_label.tr(),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 12,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: caption,
          maxLines: 3,
          maxLength: 280,
          decoration: InputDecoration(
            hintText: LocaleKeys.business_campaigns_create_step3_caption_hint.tr(),
            filled: true,
            fillColor: c.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailsStep extends StatelessWidget {
  final String? sourceType;
  final TextEditingController name;
  final TextEditingController budget;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final ValueChanged<DateTime> onPickStart;
  final ValueChanged<DateTime> onPickEnd;

  final Set<String> targetDistricts;
  final VoidCallback onEditDistricts;
  final Set<int> targetCategories;
  final VoidCallback onEditCategories;

  final TextEditingController ctaText;
  final TextEditingController ctaUrl;
  final String ctaScheme;
  final ValueChanged<String> onPickCtaScheme;

  const _DetailsStep({
    required this.sourceType,
    required this.name,
    required this.budget,
    required this.startsAt,
    required this.endsAt,
    required this.onPickStart,
    required this.onPickEnd,
    required this.targetDistricts,
    required this.onEditDistricts,
    required this.targetCategories,
    required this.onEditCategories,
    required this.ctaText,
    required this.ctaUrl,
    required this.ctaScheme,
    required this.onPickCtaScheme,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isHangout = sourceType == 'HANGOUT';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step4_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step4_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        _FieldLabel(LocaleKeys.business_campaigns_create_step4_name_label.tr()),
        const SizedBox(height: 6),
        TextField(
          controller: name,
          decoration: InputDecoration(
            hintText: LocaleKeys.business_campaigns_create_step4_name_hint.tr(),
            filled: true,
            fillColor: c.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 18),
        _FieldLabel(LocaleKeys.business_campaigns_create_step4_budget_label.tr()),
        const SizedBox(height: 6),
        TextField(
          controller: budget,
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          decoration: InputDecoration(
            hintText: LocaleKeys.business_campaigns_create_step4_budget_hint.tr(),
            suffixText: LocaleKeys.business_campaigns_create_step4_budget_suffix.tr(),
            filled: true,
            fillColor: c.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          LocaleKeys.business_campaigns_create_step4_pricing_note.tr(),
          style: TextStyle(
            color: c.onSurfaceSecondary,
            fontSize: 11,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        const SizedBox(height: 22),
        if (!isHangout) ...[
          _FieldLabel(LocaleKeys.business_campaigns_create_step4_schedule_label.tr()),
          const SizedBox(height: 6),
          _DateField(
            label: LocaleKeys.business_campaigns_create_step4_schedule_starts.tr(),
            value: startsAt,
            onPick: onPickStart,
          ),
          const SizedBox(height: 8),
          _DateField(
            label: LocaleKeys.business_campaigns_create_step4_schedule_ends.tr(),
            value: endsAt,
            onPick: onPickEnd,
          ),
          const SizedBox(height: 22),
        ] else
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: c.surfaceMuted,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(TablerIcons.info_circle, color: c.onSurfaceSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    LocaleKeys.business_campaigns_create_step4_schedule_auto_from_hangout.tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ),
              ],
            ),
          ),
        _FieldLabel(LocaleKeys.business_campaigns_create_step4_targeting_label.tr()),
        const SizedBox(height: 6),
        _TargetingTile(
          icon: TablerIcons.map_pin,
          label: targetDistricts.isEmpty
              ? LocaleKeys.business_campaigns_create_step4_targeting_no_districts.tr()
              : '${targetDistricts.length} منطقة محدّدة',
          onTap: onEditDistricts,
        ),
        const SizedBox(height: 8),
        _TargetingTile(
          icon: TablerIcons.category,
          label: targetCategories.isEmpty
              ? LocaleKeys.business_campaigns_create_step4_targeting_no_categories.tr()
              : LocaleKeys.business_campaigns_categories_picker_selected_count.tr(
                  namedArgs: {'n': '${targetCategories.length}'},
                ),
          onTap: onEditCategories,
        ),
        const SizedBox(height: 22),
        _FieldLabel(LocaleKeys.business_campaigns_create_step4_cta_label.tr()),
        const SizedBox(height: 6),
        TextField(
          controller: ctaText,
          decoration: InputDecoration(
            hintText: LocaleKeys.business_campaigns_create_step4_cta_hint.tr(),
            filled: true,
            fillColor: c.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _SchemeChip(
              label: LocaleKeys.business_campaigns_create_step4_cta_location.tr(),
              value: 'https',
              selected: ctaScheme == 'https',
              onTap: onPickCtaScheme,
            ),
            const SizedBox(width: 6),
            _SchemeChip(
              label: LocaleKeys.business_campaigns_create_step4_cta_phone.tr(),
              value: 'tel',
              selected: ctaScheme == 'tel',
              onTap: onPickCtaScheme,
            ),
            const SizedBox(width: 6),
            _SchemeChip(
              label: LocaleKeys.business_campaigns_create_step4_cta_whatsapp.tr(),
              value: 'whatsapp',
              selected: ctaScheme == 'whatsapp',
              onTap: onPickCtaScheme,
            ),
            const SizedBox(width: 6),
            _SchemeChip(
              label: LocaleKeys.business_campaigns_create_step4_cta_inapp.tr(),
              value: 'hangout',
              selected: ctaScheme == 'hangout',
              onTap: onPickCtaScheme,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctaUrl,
          keyboardType: ctaScheme == 'tel' || ctaScheme == 'whatsapp'
              ? TextInputType.phone
              : TextInputType.url,
          decoration: InputDecoration(
            hintText: switch (ctaScheme) {
              'https' => 'example.com',
              'tel' => '+9647xxxxxxxxx',
              'whatsapp' => '9647xxxxxxxxx',
              'hangout' => 'venue/abcd-1234',
              _ => '',
            },
            filled: true,
            fillColor: c.surfaceMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  const _DateField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now().add(const Duration(hours: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(value ?? DateTime.now()),
        );
        if (time == null) return;
        onPick(DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        ));
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(TablerIcons.calendar, color: c.onSurfaceSecondary, size: 18),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const Spacer(),
            Text(
              value == null ? LocaleKeys.business_campaigns_create_step4_date_choose.tr() : _formatLocal(value!),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TargetingTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TargetingTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: c.onSurfaceSecondary, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: c.onSurface,
                  fontSize: 13,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
            ),
            Icon(TablerIcons.chevron_left,
                color: c.onSurfaceSecondary, size: 16),
          ],
        ),
      ),
    );
  }
}

class _SchemeChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final ValueChanged<String> onTap;
  const _SchemeChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: () => onTap(value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? c.primary.withValues(alpha: 0.15) : c.surfaceMuted,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? c.primary : c.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? c.primary : c.onSurface,
            fontSize: 12,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
    );
  }
}

class _ReviewStep extends StatelessWidget {
  final VenueResponse venue;
  final String? placement;
  final String? sourceType;
  final PostResponse? selectedPost;
  final HangoutResponse? selectedHangout;
  final File? customMediaFile;
  final String customCaption;
  final String name;
  final String budget;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final Set<String> targetDistricts;
  final Set<int> targetCategories;
  final String ctaText;
  final String? ctaUrl;

  const _ReviewStep({
    required this.venue,
    required this.placement,
    required this.sourceType,
    required this.selectedPost,
    required this.selectedHangout,
    required this.customMediaFile,
    required this.customCaption,
    required this.name,
    required this.budget,
    required this.startsAt,
    required this.endsAt,
    required this.targetDistricts,
    required this.targetCategories,
    required this.ctaText,
    required this.ctaUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      children: [
        _StepHeader(
          title: LocaleKeys.business_campaigns_create_step5_title.tr(),
          subtitle: LocaleKeys.business_campaigns_create_step5_subtitle.tr(),
        ),
        const SizedBox(height: 8),
        _ReviewRow(
          label: LocaleKeys.business_campaigns_create_step5_label_venue.tr(),
          value: context.pickBilingual(ar: venue.nameAr, en: venue.nameEn),
        ),
        _ReviewRow(label: LocaleKeys.business_campaigns_create_step5_label_name.tr(), value: name),
        _ReviewRow(label: LocaleKeys.business_campaigns_create_step5_label_placement.tr(), value: _placementLabel(placement)),
        _ReviewRow(label: LocaleKeys.business_campaigns_create_step5_label_source.tr(), value: _sourceLabel(sourceType)),
        _ReviewRow(label: LocaleKeys.business_campaigns_create_step5_label_budget.tr(), value: '$budget ${LocaleKeys.business_campaigns_create_step4_budget_suffix.tr()}'),
        if (sourceType != 'HANGOUT') ...[
          _ReviewRow(
            label: LocaleKeys.business_campaigns_create_step5_label_start.tr(),
            value: startsAt == null ? '—' : _formatLocal(startsAt!),
          ),
          _ReviewRow(
            label: LocaleKeys.business_campaigns_create_step5_label_end.tr(),
            value: endsAt == null ? '—' : _formatLocal(endsAt!),
          ),
        ] else
          _ReviewRow(
            label: LocaleKeys.business_campaigns_create_step5_label_schedule.tr(),
            value: LocaleKeys.business_campaigns_create_step5_schedule_from_hangout.tr(),
          ),
        _ReviewRow(
          label: LocaleKeys.business_campaigns_create_step5_label_districts.tr(),
          value: targetDistricts.isEmpty
              ? LocaleKeys.business_campaigns_create_step5_all_iraq.tr()
              : targetDistricts.join('، '),
        ),
        _ReviewRow(
          label: LocaleKeys.business_campaigns_create_step5_label_categories.tr(),
          value: targetCategories.isEmpty
              ? LocaleKeys.business_campaigns_create_step5_all_categories.tr()
              : targetCategories.map((id) => '#$id').join('، '),
        ),
        if (ctaText.isNotEmpty && ctaUrl != null)
          _ReviewRow(label: LocaleKeys.business_campaigns_create_step5_label_cta.tr(), value: '$ctaText → $ctaUrl'),
      ],
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final String label;
  final String value;
  const _ReviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const _StepHeader({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: c.onSurface,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 12,
              height: 1.5,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final color = disabled ? c.onSurfaceMuted : c.onSurface;
    return Opacity(
      opacity: disabled ? 0.5 : 1.0,
      child: Material(
        color: c.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: disabled ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected ? c.primary : c.border,
                width: selected ? 1.6 : 1,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: c.surfaceMuted,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  alignment: Alignment.center,
                  child: Icon(icon, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: c.onSurfaceSecondary,
                          fontSize: 12,
                          height: 1.4,
                          fontFamily: 'IBMPlexSansArabic',
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(TablerIcons.check, color: c.primary, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Text(
      text,
      style: TextStyle(
        color: c.onSurfaceSecondary,
        fontSize: 12,
        fontWeight: FontWeight.bold,
        fontFamily: 'IBMPlexSansArabic',
      ),
    );
  }
}

class _EmptyStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyStep({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: c.onSurfaceSecondary),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                color: c.onSurface,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 13,
                height: 1.5,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _placementLabel(String? p) => switch (p) {
      'feed_card' => LocaleKeys.business_campaigns_placement_feed_card.tr(),
      'reels_placement' => LocaleKeys.business_campaigns_placement_reels_placement.tr(),
      'map_pin' => LocaleKeys.business_campaigns_placement_map_pin.tr(),
      _ => '—',
    };

String _sourceLabel(String? s) => switch (s) {
      'POST' => LocaleKeys.business_campaigns_source_post.tr(),
      'HANGOUT' => LocaleKeys.business_campaigns_source_hangout.tr(),
      'CUSTOM' => LocaleKeys.business_campaigns_source_custom.tr(),
      _ => '—',
    };

String _formatLocal(DateTime dt) {
  String pad(int n) => n.toString().padLeft(2, '0');
  final l = dt.toLocal();
  return '${l.year}/${pad(l.month)}/${pad(l.day)} '
      '${pad(l.hour)}:${pad(l.minute)}';
}

String _formatIso(String iso) {
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return _formatLocal(dt);
}
