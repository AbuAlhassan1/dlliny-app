import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/search_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/shared/widgets/form/app_form_field.dart';

class InviteePickerField extends StatelessWidget {
  static const int maxInvitees = 99;

  final List<UserSearchResultDto> selected;
  final ValueChanged<List<UserSearchResultDto>> onChanged;

  const InviteePickerField({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  Future<void> _openPicker(BuildContext context) async {
    final updated = await showModalBottomSheet<List<UserSearchResultDto>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => InviteePickerSheet(initial: selected),
    );
    if (updated != null) onChanged(updated);
  }

  void _remove(UserSearchResultDto u) {
    onChanged([
      for (final s in selected)
        if (s.id != u.id) s,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          selected.isEmpty
              ? LocaleKeys.hangout_create_invitees_count_optional.tr()
              : LocaleKeys.hangout_create_invitees_count_with_max.tr(
                  namedArgs: {
                    'n': '${selected.length}',
                    'max': '$maxInvitees',
                  },
                ),
          style: TextStyle(color: c.onSurfaceMuted, fontSize: 12),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => _openPicker(context),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: c.borderStrong,
                width: 1,
              ),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                for (final u in selected) _InviteeChip(user: u, onRemove: () => _remove(u)),
                _AddChip(empty: selected.isEmpty),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InviteeChip extends StatelessWidget {
  final UserSearchResultDto user;
  final VoidCallback onRemove;
  const _InviteeChip({required this.user, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 4, 4),
      decoration: BoxDecoration(
        color: c.onSurface.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.displayName ?? user.username,
            style: TextStyle(color: c.onSurface, fontSize: 12),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            customBorder: const CircleBorder(),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: Icon(Icons.close, size: 14, color: c.onSurfaceSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddChip extends StatelessWidget {
  final bool empty;
  const _AddChip({required this.empty});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.onSurfaceSecondary, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(TablerIcons.plus, size: 14, color: c.onSurfaceSecondary),
          const SizedBox(width: 4),
          Text(
            (empty
                    ? LocaleKeys.hangout_create_invitees_invite_friends
                    : LocaleKeys.hangout_create_invitees_add)
                .tr(),
            style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class InviteePickerSheet extends StatefulWidget {
  final List<UserSearchResultDto> initial;
  const InviteePickerSheet({super.key, required this.initial});

  @override
  State<InviteePickerSheet> createState() => InviteePickerSheetState();
}

class InviteePickerSheetState extends State<InviteePickerSheet> {
  static const Duration _debounce = Duration(milliseconds: 400);

  final ApiService _api = serviceLocator.get<ApiService>();
  final TextEditingController _search = TextEditingController();
  Timer? _timer;

  int _seq = 0;

  List<UserSearchResultDto> _results = [];
  bool _loading = false;

  late final Map<String, UserSearchResultDto> _selected = {
    for (final u in widget.initial) u.id: u,
  };

  @override
  void dispose() {
    _timer?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _timer?.cancel();
    final q = value.trim();
    if (q.length < 2) {
      setState(() {
        _results = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _timer = Timer(_debounce, () => _run(q));
  }

  Future<void> _run(String q) async {
    final seq = ++_seq;
    try {
      final res = await _api.search(q);
      if (!mounted || seq != _seq) return;
      setState(() {
        _results = res.data?.users ?? const [];
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

  void _toggle(UserSearchResultDto u) {
    setState(() {
      if (_selected.containsKey(u.id)) {
        _selected.remove(u.id);
      } else {
        if (_selected.length >= InviteePickerField.maxInvitees) return;
        _selected[u.id] = u;
      }
    });
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
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      LocaleKeys.hangout_create_invitees_invite_friends.tr(),
                      style: TextStyle(
                        color: c.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Text(
                    '${_selected.length}/${InviteePickerField.maxInvitees}',
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onSearchChanged,
                style: TextStyle(color: c.onSurface),
                decoration: appInputDecoration(
                  c,
                  hint: LocaleKeys.hangout_create_invitees_search_hint.tr(),
                  prefixIcon: Icon(
                    TablerIcons.search,
                    color: c.onSurfaceSecondary,
                    size: 18,
                  ),
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
                          color: c.onSurface,
                          strokeWidth: 1,
                        ),
                      ),
                    )
                  : _results.isEmpty
                      ? Center(
                          child: Text(
                            _search.text.trim().length < 2
                                ? LocaleKeys.hangout_create_invitees_search_prompt.tr()
                                : LocaleKeys.common_no_results.tr(),
                            style: TextStyle(color: c.onSurfaceSecondary),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          itemCount: _results.length,
                          itemBuilder: (context, i) {
                            final u = _results[i];
                            final picked = _selected.containsKey(u.id);
                            return _UserRow(
                              user: u,
                              selected: picked,
                              onTap: () => _toggle(u),
                            );
                          },
                        ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () =>
                        Navigator.pop(context, _selected.values.toList()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: c.primary,
                      foregroundColor: c.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(LocaleKeys.hangout_create_invitees_done.tr()),
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

class _UserRow extends StatelessWidget {
  final UserSearchResultDto user;
  final bool selected;
  final VoidCallback onTap;
  const _UserRow({
    required this.user,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: c.surfaceMuted,
        backgroundImage: user.avatarUrl != null
            ? CachedNetworkImageProvider(user.avatarUrl!)
            : null,
        child: user.avatarUrl == null
            ? Icon(Icons.person, color: c.onSurface, size: 18)
            : null,
      ),
      title: Text(
        user.displayName ?? user.username,
        style: TextStyle(color: c.onSurface, fontSize: 14),
      ),
      subtitle: Text(
        '@${user.username}',
        style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
      ),
      trailing: Icon(
        selected ? TablerIcons.circle_check_filled : TablerIcons.circle,
        color: selected ? c.onSurface : c.onSurfaceDisabled,
        size: 22,
      ),
    );
  }
}
