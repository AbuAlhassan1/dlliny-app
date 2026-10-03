import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';

sealed class AuthorIdentity {
  const AuthorIdentity();

  String get displayName;

  String? get imageUrl;
}

class MeAuthor extends AuthorIdentity {
  final String userId;
  @override
  final String displayName;
  @override
  final String? imageUrl;

  const MeAuthor({
    required this.userId,
    required this.displayName,
    this.imageUrl,
  });
}

class VenueAuthor extends AuthorIdentity {
  final String venueId;
  final String name;
  final String? logoUrl;

  const VenueAuthor({
    required this.venueId,
    required this.name,
    this.logoUrl,
  });

  @override
  String get displayName => name;

  @override
  String? get imageUrl => logoUrl;
}

class AuthorPickerSwitcher extends StatefulWidget {
  final AuthorIdentity current;
  final ValueChanged<AuthorIdentity> onChanged;

  const AuthorPickerSwitcher({
    super.key,
    required this.current,
    required this.onChanged,
  });

  @override
  State<AuthorPickerSwitcher> createState() => _AuthorPickerSwitcherState();
}

class _AuthorPickerSwitcherState extends State<AuthorPickerSwitcher> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<VenueAuthor>? _venues;

  MeAuthor? _me;

  @override
  void initState() {
    super.initState();
    if (widget.current is MeAuthor) _me = widget.current as MeAuthor;
    _loadVenues();
  }

  @override
  void didUpdateWidget(AuthorPickerSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.current is MeAuthor) _me = widget.current as MeAuthor;
  }

  Future<void> _loadVenues() async {
    try {
      final res = await _api.getMyAccess();
      if (!mounted) return;
      final access = res.data;
      if (access == null) {
        setState(() => _venues = const []);
        return;
      }
      final venues = <VenueAuthor>[
        for (final b in access.businesses)
          for (final v in b.venues)
            VenueAuthor(venueId: v.venueId, name: v.nameAr, logoUrl: v.logoUrl),
        for (final v in access.orphanVenues)
          VenueAuthor(venueId: v.venueId, name: v.nameAr, logoUrl: v.logoUrl),
      ];
      setState(() => _venues = venues);
    } catch (_) {
      if (!mounted) return;
      setState(() => _venues = const []);
    }
  }

  Future<void> _openPicker(MeAuthor me) async {
    final venues = _venues ?? const <VenueAuthor>[];
    final picked = await showModalBottomSheet<AuthorIdentity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AuthorPickerSheet(
        me: me,
        venues: venues,
        current: widget.current,
      ),
    );
    if (picked != null) widget.onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final current = widget.current;
    final hasOptions = _venues != null && _venues!.isNotEmpty;
    final me = _me;

    return InkWell(
      onTap: hasOptions && me != null ? () => _openPicker(me) : null,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(8, 6, 8, 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _AuthorAvatar(identity: current, size: 32),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (current is VenueAuthor
                            ? LocaleKeys.profile_my_author_picker_post_as_label
                            : LocaleKeys
                                  .profile_my_author_picker_post_as_label_self)
                        .tr(),
                    style: TextStyle(
                      color: c.onSurfaceSecondary,
                      fontSize: 10,
                    ),
                  ),
                  Text(
                    current.displayName,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: c.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            if (hasOptions) ...[
              const SizedBox(width: 4),
              Icon(
                TablerIcons.chevron_down,
                color: c.onSurfaceSecondary,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AuthorAvatar extends StatelessWidget {
  final AuthorIdentity identity;
  final double size;
  const _AuthorAvatar({required this.identity, required this.size});

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final url = identity.imageUrl;
    final isVenue = identity is VenueAuthor;
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        shape: isVenue ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: isVenue ? BorderRadius.circular(6) : null,
        color: c.surfaceMuted,
      ),
      child: url != null
          ? CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => _fallbackIcon(c, isVenue, size),
            )
          : _fallbackIcon(c, isVenue, size),
    );
  }

  Widget _fallbackIcon(AppColors c, bool isVenue, double s) => Icon(
        isVenue ? TablerIcons.building_store : Icons.person,
        color: c.onSurfaceSecondary,
        size: s * 0.55,
      );
}

class _AuthorPickerSheet extends StatelessWidget {
  final MeAuthor me;
  final List<VenueAuthor> venues;
  final AuthorIdentity current;

  const _AuthorPickerSheet({
    required this.me,
    required this.venues,
    required this.current,
  });

  bool _isSelected(AuthorIdentity id) {
    if (id is MeAuthor && current is MeAuthor) {
      return (current as MeAuthor).userId == id.userId;
    }
    if (id is VenueAuthor && current is VenueAuthor) {
      return (current as VenueAuthor).venueId == id.venueId;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final maxHeight = MediaQuery.of(context).size.height * 0.7;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: SizedBox(
                width: double.infinity,
                child: Text(
                  LocaleKeys.profile_my_author_picker_post_as_label.tr(),
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: c.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            Divider(height: 1, color: c.divider),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  _row(context, me),
                  for (final v in venues) _row(context, v),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(BuildContext context, AuthorIdentity id) {
    final c = context.c;
    final selected = _isSelected(id);
    return ListTile(
      onTap: () => Navigator.pop(context, id),
      leading: _AuthorAvatar(identity: id, size: 36),
      title: Text(
        id.displayName,
        style: TextStyle(color: c.onSurface, fontSize: 14),
      ),
      subtitle: id is VenueAuthor
          ? Text(
              LocaleKeys.profile_my_author_picker_as_venue.tr(),
              style: TextStyle(color: c.onSurfaceSecondary, fontSize: 12),
            )
          : null,
      trailing: selected
          ? Icon(TablerIcons.circle_check_filled,
              color: c.onSurface, size: 22)
          : Icon(TablerIcons.circle, color: c.onSurfaceMuted, size: 22),
    );
  }
}
