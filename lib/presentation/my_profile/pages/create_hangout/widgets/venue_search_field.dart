import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:hangout/domain/dto/response/search_response.dart';

class VenueSearchField extends StatefulWidget {
  final void Function(VenueSearchResultDto venue) onVenueSelected;
  final VenueSearchResultDto? selectedVenue;

  const VenueSearchField({
    super.key,
    required this.onVenueSelected,
    this.selectedVenue,
  });

  @override
  State<VenueSearchField> createState() => _VenueSearchFieldState();
}

class _VenueSearchFieldState extends State<VenueSearchField> {
  final ApiService _api = serviceLocator.get<ApiService>();
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;
  List<VenueSearchResultDto> _results = [];
  bool _showResults = false;

  @override
  void initState() {
    super.initState();
    if (widget.selectedVenue != null) {
      _controller.text = widget.selectedVenue!.nameAr;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    if (value.length < 2) {
      setState(() {
        _results = [];
        _showResults = false;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final res = await _api.search(value);
        if (mounted) {
          setState(() {
            _results = res.data?.venues ?? [];
            _showResults = _results.isNotEmpty;
          });
        }
      } catch (_) {}
    });
  }

  void _select(VenueSearchResultDto venue) {
    _controller.text = venue.nameAr;
    setState(() {
      _results = [];
      _showResults = false;
    });
    widget.onVenueSelected(venue);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppLabeledField(
          label: LocaleKeys.hangout_create_venue_label.tr(),
          child: TextField(
            controller: _controller,
            onChanged: _onChanged,
            style: TextStyle(color: c.onSurface),
            decoration: appInputDecoration(
              c,
              hint: LocaleKeys.hangout_create_venue_search_hint.tr(),
              suffixIcon: widget.selectedVenue != null
                  ? Icon(Icons.check_circle, color: c.success, size: 18)
                  : null,
            ),
          ),
        ),
        if (_showResults)
          Container(
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: c.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: c.border),
            ),
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _results.length,
              separatorBuilder: (_, _) => Divider(
                height: 1,
                color: c.divider,
              ),
              itemBuilder: (context, index) {
                final venue = _results[index];
                return ListTile(
                  dense: true,
                  onTap: () => _select(venue),
                  title: Text(
                    venue.nameAr,
                    style: TextStyle(color: c.onSurface, fontSize: 13),
                  ),
                  subtitle: venue.district != null
                      ? Text(
                          venue.district!,
                          style: TextStyle(
                            color: c.onSurfaceSecondary,
                            fontSize: 11,
                          ),
                        )
                      : null,
                );
              },
            ),
          ),
      ],
    );
  }
}
