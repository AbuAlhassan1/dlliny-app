import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/venue_response.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

typedef QuickVenue = ({String id, String name});

class VenuePickerSheet extends StatefulWidget {
  final String? selectedId;

  const VenuePickerSheet({super.key, this.selectedId});

  @override
  State<VenuePickerSheet> createState() => _VenuePickerSheetState();
}

class _VenuePickerSheetState extends State<VenuePickerSheet> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final TextEditingController _search = TextEditingController();
  Timer? _timer;
  int _seq = 0;

  List<VenueSummaryResponse> _results = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _run('');
  }

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _timer?.cancel();
    final q = value.trim();
    setState(() => _loading = true);
    _timer = Timer(const Duration(milliseconds: 400), () => _run(q));
  }

  Future<void> _run(String q) async {
    final seq = ++_seq;
    try {
      final res = await _api.getVenues(q: q.isEmpty ? null : q, size: 20);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = res.data?.content ?? const [];
        _loading = false;
      });
    } catch (_) {
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = const [];
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Padding(
        padding: EdgeInsets.only(bottom: viewInsets),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: false,
                onChanged: _onChanged,
                style: TextStyle(color: c.onSurface),
                decoration: appInputDecoration(
                  c,
                  hint: context.pickBilingual(
                      ar: 'ابحث عن مكان', en: 'Search for a venue'),
                  prefixIcon:
                      Icon(TablerIcons.search, color: c.onSurfaceSecondary, size: 18),
                ),
              ),
            ),
            Divider(height: 16, color: c.divider),
            Expanded(
              child: _loading
                  ? Center(
                      child: SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            color: c.onSurface, strokeWidth: 1),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            context.pickBilingual(
                                ar: 'لا توجد نتائج', en: 'No results'),
                            style: TextStyle(color: c.onSurfaceSecondary),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final v = _results[i];
                            return _VenueRow(
                              venue: v,
                              selected: v.id == widget.selectedId,
                              onTap: () => Navigator.pop(
                                  context, (id: v.id, name: v.nameAr)),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VenueRow extends StatelessWidget {
  final VenueSummaryResponse venue;
  final bool selected;
  final VoidCallback onTap;

  const _VenueRow({
    required this.venue,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final where = [venue.districtNameAr, venue.cityNameAr]
        .where((s) => s != null && s.isNotEmpty)
        .join('، ');
    return ListTile(
      onTap: onTap,
      leading: VenueLogoAvatar(url: venue.logoUrl, size: 40),
      title: Text(
        venue.nameAr,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 14,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
      subtitle: where.isEmpty
          ? null
          : Text(
              where,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
      trailing: selected
          ? Icon(TablerIcons.circle_check_filled, color: c.primary)
          : null,
    );
  }
}

class VenueLogoAvatar extends StatelessWidget {
  final String? url;
  final double size;

  const VenueLogoAvatar({super.key, required this.url, required this.size});

  @override
  Widget build(BuildContext context) {
    final hasUrl = url != null && url!.isNotEmpty;
    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: hasUrl
            ? CachedNetworkImage(
                imageUrl: url!,
                fit: BoxFit.cover,
                memCacheWidth: (size * 3).round(),
                memCacheHeight: (size * 3).round(),
                placeholder: (_, _) => _fallback(),
                errorWidget: (_, _, _) => _fallback(),
              )
            : _fallback(),
      ),
    );
  }

  Widget _fallback() => DecoratedBox(
        decoration: const BoxDecoration(
          color: Color(0x33FFFFFF),
          shape: BoxShape.circle,
        ),
        child: Icon(TablerIcons.building,
            size: size * 0.5, color: Colors.white.withValues(alpha: 0.8)),
      );
}
