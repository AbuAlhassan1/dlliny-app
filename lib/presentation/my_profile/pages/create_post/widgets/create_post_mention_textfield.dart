// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';
import 'package:mention_tag_text_field/mention_tag_text_field.dart';

class CreatePostMentionTextfield extends StatefulWidget {
  final MentionTagTextEditingController controller;
  const CreatePostMentionTextfield({super.key, required this.controller});

  @override
  State<CreatePostMentionTextfield> createState() =>
      _CreatePostMentionTextfieldState();
}

class _CreatePostMentionTextfieldState
    extends State<CreatePostMentionTextfield> {
  
  static const Duration _debounceDuration = Duration(milliseconds: 500);
  final ApiService _api = serviceLocator.get<ApiService>();
  Timer? _debounce;
  int _searchSeq = 0;
  List<MentionItem> _searchResults = [];

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onMentionTokenChanged(String? value) {
    if (value != null && value.length > 2) {
      _scheduleSearch(value.substring(1));
    } else {
      _debounce?.cancel();
      if (_searchResults.isNotEmpty) {
        setState(() => _searchResults = []);
      }
    }
  }

  void _scheduleSearch(String query) {
    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    final seq = ++_searchSeq;
    try {
      final res = await _api.search(query);
      if (!mounted || seq != _searchSeq) return;
      final data = res.data;
      final items = <MentionItem>[
        if (data != null) ...[
          for (final u in data.users)
            MentionItem(
              id: u.id,
              name: u.displayName ?? u.username,
              username: u.username,
              type: _typeUser,
              avatarUrl: u.avatarUrl,
            ),
          for (final v in data.venues)
            MentionItem(
              id: v.id,
              name: v.nameAr.isNotEmpty ? v.nameAr : v.nameEn,
              type: _typeVenue,
            ),
        ],
      ];
      setState(() => _searchResults = items);
    } catch (_) {
      if (!mounted || seq != _searchSeq) return;
      setState(() => _searchResults = []);
    }
  }

  void _onSuggestionPicked(MentionItem item) {
    final wireLabel = item.isVenue ? item.name : (item.username ?? item.name);
    widget.controller.addMention(
      label: wireLabel,
      data: item,
      stylingWidget: _InlineMentionChip(label: item.name, type: item.type),
    );
    _debounce?.cancel();
    setState(() => _searchResults = []);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      children: [
        _SuggestionsRow(
          results: _searchResults,
          onPick: _onSuggestionPicked,
        ),
        MentionTagTextFormField(
          controller: widget.controller,
          maxLines: 3,
          decoration: appInputDecoration(
            c,
            hint: LocaleKeys.post_create_caption_hint.tr(),
          ).copyWith(
            helperText: LocaleKeys.post_create_mention_helper.tr(),
            helperStyle: TextStyle(color: c.onSurfaceMuted),
          ),
          style: TextStyle(color: c.onSurface),
          enableSuggestions: true,
          onMention: _onMentionTokenChanged,
        ),
      ],
    );
  }
}

class _SuggestionsRow extends StatelessWidget {
  final List<MentionItem> results;
  final ValueChanged<MentionItem> onPick;

  const _SuggestionsRow({required this.results, required this.onPick});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        child: Row(
          children: [
            for (final r in results)
              Padding(
                padding: const EdgeInsetsDirectional.only(end: 8),
                child: _SuggestionChip(item: r, onTap: () => onPick(r)),
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final MentionItem item;
  final VoidCallback onTap;

  const _SuggestionChip({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.border, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.isVenue ? TablerIcons.map_pin : TablerIcons.at,
              size: 14,
              color: c.onSurfaceSecondary,
            ),
            const SizedBox(width: 6),
            Text(item.name, style: TextStyle(color: c.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _InlineMentionChip extends StatelessWidget {
  final String label;
  final String type;

  const _InlineMentionChip({required this.label, required this.type});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: c.border,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            type == _typeVenue ? TablerIcons.map_pin : TablerIcons.at,
            size: 12,
            color: c.onSurface,
          ),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: c.onSurface)),
        ],
      ),
    );
  }
}

const String _typeUser = 'user';
const String _typeVenue = 'venue';

class MentionItem {
  final String id;
  final String name;
  final String? username;
  final String type;
  final String? avatarUrl;

  MentionItem({
    required this.id,
    required this.name,
    required this.type,
    this.username,
    this.avatarUrl,
  });

  bool get isVenue => type == _typeVenue;
}
