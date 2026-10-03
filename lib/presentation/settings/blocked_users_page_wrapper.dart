import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/services/bilingual_text.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/auth_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/presentation/profile/profile_page_wrapper.dart';

class BlockedUsersPageWrapper extends StatefulWidget {
  const BlockedUsersPageWrapper({super.key});

  static Future<void> push(BuildContext context) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const BlockedUsersPageWrapper()),
    );
  }

  @override
  State<BlockedUsersPageWrapper> createState() =>
      _BlockedUsersPageWrapperState();
}

class _BlockedUsersPageWrapperState extends State<BlockedUsersPageWrapper> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<UserDto>? _users;
  bool _failed = false;
  final Set<String> _unblocking = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _failed = false);
    try {
      final res = await _api.getBlockedUsers();
      if (!mounted) return;
      if (res.success && res.data != null) {
        setState(() => _users = res.data!);
      } else {
        setState(() => _failed = true);
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _unblock(UserDto user) async {
    if (_unblocking.contains(user.id)) return;
    setState(() => _unblocking.add(user.id));
    try {
      final res = await _api.unblockUser(user.id);
      if (!mounted) return;
      if (res.success) {
        setState(() => _users = _users?.where((u) => u.id != user.id).toList());
        appToast.success(context.pickBilingual(
          ar: 'تم إلغاء الحظر',
          en: 'Unblocked',
        ));
      } else {
        appToast.error(context.pickBilingual(
          ar: 'تعذّر إلغاء الحظر',
          en: "Couldn't unblock",
        ));
      }
    } catch (_) {
      if (mounted) {
        appToast.error(context.pickBilingual(
          ar: 'تعذّر إلغاء الحظر',
          en: "Couldn't unblock",
        ));
      }
    } finally {
      if (mounted) setState(() => _unblocking.remove(user.id));
    }
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
          LocaleKeys.settings_blocked_accounts.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    final c = context.c;
    if (_users == null && !_failed) {
      return Center(
        child: CircularProgressIndicator(color: c.primary, strokeWidth: 2),
      );
    }
    if (_failed) {
      return _Message(
        icon: TablerIcons.alert_triangle,
        text: context.pickBilingual(
          ar: 'تعذّر تحميل القائمة',
          en: 'Could not load the list',
        ),
        actionLabel: context.pickBilingual(ar: 'إعادة المحاولة', en: 'Retry'),
        onAction: _load,
      );
    }
    final users = _users ?? const [];
    if (users.isEmpty) {
      return _Message(
        icon: TablerIcons.forbid_2,
        text: context.pickBilingual(
          ar: 'لا يوجد حسابات محظورة',
          en: 'No blocked accounts',
        ),
      );
    }
    return RefreshIndicator(
      color: c.primary,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, _) => Divider(color: c.divider, height: 1),
        itemBuilder: (_, i) => _BlockedRow(
          user: users[i],
          unblocking: _unblocking.contains(users[i].id),
          onUnblock: () => _unblock(users[i]),
        ),
      ),
    );
  }
}

class _BlockedRow extends StatelessWidget {
  final UserDto user;
  final bool unblocking;
  final VoidCallback onUnblock;

  const _BlockedRow({
    required this.user,
    required this.unblocking,
    required this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : (user.username ?? '');
    final username = user.username;
    return ListTile(
      onTap: username == null || username.isEmpty
          ? null
          : () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ProfilePageWrapper(username: username),
                ),
              ),
      leading: ClipOval(
        child: SizedBox(
          width: 44,
          height: 44,
          child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: user.avatarUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 132,
                  errorWidget: (_, _, _) => _avatarFallback(c),
                )
              : _avatarFallback(c),
        ),
      ),
      title: Text(
        name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: c.onSurface,
          fontSize: 15,
          fontWeight: FontWeight.w700,
          fontFamily: 'IBMPlexSansArabic',
        ),
      ),
      subtitle: username == null
          ? null
          : Text(
              '@$username',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 12.5,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
      trailing: OutlinedButton(
        onPressed: unblocking ? null : onUnblock,
        style: OutlinedButton.styleFrom(
          foregroundColor: c.onSurface,
          side: BorderSide(color: c.border),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        ),
        child: unblocking
            ? SizedBox(
                width: 16,
                height: 16,
                child:
                    CircularProgressIndicator(strokeWidth: 2, color: c.onSurface),
              )
            : Text(
                context.pickBilingual(ar: 'إلغاء الحظر', en: 'Unblock'),
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFamily: 'IBMPlexSansArabic',
                ),
              ),
      ),
    );
  }

  Widget _avatarFallback(AppColors c) => Container(
        color: c.surfaceMuted,
        alignment: Alignment.center,
        child: Icon(TablerIcons.user, color: c.onSurfaceSecondary, size: 22),
      );
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: c.onSurfaceMuted, size: 44),
            const SizedBox(height: 12),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: c.onSurfaceSecondary,
                fontSize: 14,
                fontFamily: 'IBMPlexSansArabic',
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 12),
              TextButton(
                onPressed: onAction,
                child: Text(
                  actionLabel!,
                  style: TextStyle(
                    color: c.primary,
                    fontFamily: 'IBMPlexSansArabic',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
