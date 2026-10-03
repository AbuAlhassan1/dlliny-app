import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/public_event_response.dart';
import 'package:hangout/presentation/hangout/hangout_details_page_wrapper.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';

class PublicEventDetailPage extends StatefulWidget {
  final PublicEventResponse event;
  const PublicEventDetailPage({super.key, required this.event});

  static Future<void> push(BuildContext context, PublicEventResponse event) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => PublicEventDetailPage(event: event)),
    );
  }

  @override
  State<PublicEventDetailPage> createState() => _PublicEventDetailPageState();
}

class _PublicEventDetailPageState extends State<PublicEventDetailPage> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final PageController _mediaController = PageController();
  late PublicEventResponse _event = widget.event;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _mediaController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final res = await _api.getPublicEvent(_event.id);
      if (mounted && res.success && res.data != null) {
        setState(() => _event = res.data!);
      }
    } catch (_) {}
  }

  Future<void> _toggleInterest() async {
    if (_toggling) return;
    final nowInterested = !_event.interestedByMe;
    setState(() {
      _toggling = true;
      _event = _event.copyWithInterest(
        interestedByMe: nowInterested,
        interestedCount:
            (_event.interestedCount + (nowInterested ? 1 : -1)).clamp(0, 1 << 31),
      );
    });
    try {
      final res = nowInterested
          ? await _api.markEventInterested(_event.id)
          : await _api.unmarkEventInterested(_event.id);
      if (mounted && res.success && res.data != null) {
        setState(() => _event = res.data!);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _event = _event.copyWithInterest(
              interestedByMe: !nowInterested,
              interestedCount: (_event.interestedCount + (nowInterested ? -1 : 1))
                  .clamp(0, 1 << 31),
            ));
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _openExternal() async {
    final url = _event.externalUrl;
    if (url == null || url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      appToast.error(context.pickBilingual(
        ar: 'تعذّر فتح الرابط',
        en: "Couldn't open the link",
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final e = _event;
    final title = context.pickBilingual(ar: e.titleAr, en: e.titleEn);
    final description =
        context.pickBilingual(ar: e.descriptionAr ?? '', en: e.descriptionEn ?? '');
    final venueName = e.venueId == null
        ? null
        : context.pickBilingual(ar: e.venueNameAr ?? '', en: e.venueNameEn ?? '');
    final branchLabel = e.branch == null
        ? null
        : context.pickBilingual(
            ar: e.branch!.labelAr ?? '', en: e.branch!.labelEn ?? '');

    return Scaffold(
      backgroundColor: c.background,
      appBar: AppBar(
        backgroundColor: c.background,
        foregroundColor: c.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 28),
        children: [
          _mediaStrip(c),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: c.onSurface,
                    fontSize: 22,
                    height: 1.25,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
                const SizedBox(height: 12),
                _infoLine(c, TablerIcons.calendar_event, _whenLabel(context)),
                if (venueName != null && venueName.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoLine(
                    c,
                    TablerIcons.map_pin,
                    branchLabel != null && branchLabel.isNotEmpty
                        ? '$venueName · $branchLabel'
                        : venueName,
                  ),
                ] else ...[
                  const SizedBox(height: 8),
                  _infoLine(
                    c,
                    TablerIcons.world,
                    context.pickBilingual(ar: 'فعالية خارجية', en: 'Off-platform'),
                  ),
                ],
                const SizedBox(height: 8),
                _infoLine(
                  c,
                  TablerIcons.heart,
                  context.pickBilingual(
                    ar: '${e.interestedCount} مهتم',
                    en: '${e.interestedCount} interested',
                  ),
                ),
                if (description.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(
                    description.trim(),
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'IBMPlexSansArabic',
                    ),
                  ),
                ],
                if (e.hangoutId != null) ...[
                  const SizedBox(height: 16),
                  _hangoutChip(context, e.hangoutId!),
                ],
                const SizedBox(height: 22),
                _actions(context, c),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _whenLabel(BuildContext context) {
    final start = DateTime.tryParse(_event.startsAt)?.toLocal();
    final locale = context.locale.toString();
    if (start == null) return '';
    final startStr = DateFormat('EEEE d MMM • h:mm a', locale).format(start);
    final end = _event.endsAt == null
        ? null
        : DateTime.tryParse(_event.endsAt!)?.toLocal();
    if (end == null) return startStr;
    return '$startStr → ${DateFormat('h:mm a', locale).format(end)}';
  }

  Widget _mediaStrip(AppColors c) {
    final media = _event.media;
    if (media.isEmpty) {
      return AspectRatio(
        aspectRatio: 16 / 10,
        child: Container(
          color: c.surfaceMuted,
          child: Center(
            child: Icon(TablerIcons.calendar_star,
                color: c.onSurfaceMuted, size: 44),
          ),
        ),
      );
    }
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: Stack(
        children: [
          PageView.builder(
            controller: _mediaController,
            itemCount: media.length,
            itemBuilder: (context, i) {
              final url = media[i].coverUrl;
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (url != null && url.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => ColoredBox(color: c.surfaceMuted),
                    )
                  else
                    ColoredBox(color: c.surfaceMuted),
                  if (media[i].isVideo)
                    const Center(
                      child: Icon(TablerIcons.player_play_filled,
                          color: Colors.white, size: 44),
                    ),
                ],
              );
            },
          ),
          if (media.length > 1)
            PositionedDirectional(
              bottom: 10,
              start: 0,
              end: 0,
              child: Center(
                child: SmoothPageIndicator(
                  controller: _mediaController,
                  count: media.length,
                  effect: const WormEffect(
                    dotColor: Color(0x66FFFFFF),
                    activeDotColor: Colors.white,
                    dotHeight: 7,
                    dotWidth: 7,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoLine(AppColors c, IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: c.onSurfaceSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: c.onSurfaceSecondary,
              fontSize: 13.5,
              height: 1.35,
              fontWeight: FontWeight.w600,
              fontFamily: 'IBMPlexSansArabic',
            ),
          ),
        ),
      ],
    );
  }

  Widget _hangoutChip(BuildContext context, String hangoutId) {
    final c = context.c;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HangoutDetailsPageWrapper(hangoutId: hangoutId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: c.surfaceMuted,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(TablerIcons.calendar_event, size: 18, color: c.primary),
            const SizedBox(width: 8),
            Text(
              context.pickBilingual(ar: 'شوف الطلعة', en: 'See the hangout'),
              style: TextStyle(
                color: c.onSurface,
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            const SizedBox(width: 4),
            Icon(TablerIcons.chevron_right, size: 16, color: c.onSurfaceSecondary),
          ],
        ),
      ),
    );
  }

  Widget _actions(BuildContext context, AppColors c) {
    final interested = _event.interestedByMe;
    final hasUrl = _event.externalUrl != null && _event.externalUrl!.isNotEmpty;
    final ctaLabel = (_event.externalUrlLabel?.trim().isNotEmpty ?? false)
        ? _event.externalUrlLabel!.trim()
        : context.pickBilingual(ar: 'اعرف أكثر', en: 'Learn more');
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: _toggling ? null : _toggleInterest,
            icon: Icon(
              interested ? TablerIcons.heart_filled : TablerIcons.heart,
              size: 18,
            ),
            label: Text(
              interested
                  ? context.pickBilingual(ar: 'مهتم', en: 'Interested')
                  : context.pickBilingual(ar: 'يهمني', en: "I'm interested"),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: interested ? c.surfaceMuted : c.primary,
              foregroundColor: interested ? c.onSurface : c.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        if (hasUrl) ...[
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _openExternal,
              icon: const Icon(TablerIcons.external_link, size: 18),
              label: Text(
                ctaLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: c.onSurface,
                side: BorderSide(color: c.border),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
