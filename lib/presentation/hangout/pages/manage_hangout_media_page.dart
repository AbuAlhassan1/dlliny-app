import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/di/injection_container.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/core/toast/app_toast_service.dart';
import 'package:hangout/data/api/api_service.dart';
import 'package:hangout/domain/dto/response/hangout_response.dart';
import 'package:hangout/generated/locale_keys.g.dart';

class ManageHangoutMediaPage extends StatefulWidget {
  final String hangoutId;
  const ManageHangoutMediaPage({super.key, required this.hangoutId});

  static Future<void> push(BuildContext context, String hangoutId) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ManageHangoutMediaPage(hangoutId: hangoutId),
      ),
    );
  }

  @override
  State<ManageHangoutMediaPage> createState() => _ManageHangoutMediaPageState();
}

class _ManageHangoutMediaPageState extends State<ManageHangoutMediaPage> {
  final ApiService _api = serviceLocator.get<ApiService>();

  List<HangoutMediaResponse>? _media;
  String? _error;
  bool _loading = true;
  final Set<String> _deleting = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.getHangoutMedia(widget.hangoutId);
      if (!mounted) return;
      if (!res.success || res.data == null) {
        setState(() {
          _loading = false;
          _error = res.error ?? LocaleKeys.hangout_manage_media_load_failed.tr();
        });
        return;
      }
      final items = [...res.data!]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      setState(() {
        _media = items;
        _loading = false;
      });
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = LocaleKeys.hangout_manage_media_load_failed.tr();
      });
    }
  }

  Future<void> _confirmAndDelete(HangoutMediaResponse media) async {
    final c = context.c;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final cc = ctx.c;
        return AlertDialog(
          backgroundColor: cc.surfaceElevated,
          title: Text(
            LocaleKeys.hangout_manage_media_dialog_delete_title.tr(),
            style: TextStyle(color: cc.onSurface),
          ),
          content: Text(
            LocaleKeys.hangout_manage_media_dialog_delete_body.tr(),
            style: TextStyle(color: cc.onSurfaceSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                LocaleKeys.common_cancel.tr(),
                style: TextStyle(color: cc.onSurfaceSecondary),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                LocaleKeys.post_actions_confirm_delete_confirm.tr(),
                style: TextStyle(color: cc.danger),
              ),
            ),
          ],
        );
      },
    );
    if (ok != true || !mounted) return;
    setState(() => _deleting.add(media.id));
    try {
      final res = await _api.deleteHangoutMedia(widget.hangoutId, media.id);
      if (!mounted) return;
      if (!res.success) {
        appToast.error(
          res.error ?? LocaleKeys.hangout_manage_media_delete_failed.tr(),
        );
        setState(() => _deleting.remove(media.id));
        return;
      }
      setState(() {
        _media?.removeWhere((m) => m.id == media.id);
        _deleting.remove(media.id);
      });
      appToast.success(LocaleKeys.hangout_manage_media_delete_success.tr());
    } on DioException catch (_) {
      if (!mounted) return;
      setState(() => _deleting.remove(media.id));
      appToast.error(LocaleKeys.hangout_manage_media_delete_failed.tr());
    }
    c.onSurface;
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
          LocaleKeys.hangout_manage_media_page_title.tr(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _body(c),
    );
  }

  Widget _body(AppColors c) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: c.onSurface, strokeWidth: 1.5),
      );
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                TablerIcons.alert_triangle,
                color: c.onSurfaceDisabled,
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: c.onSurfaceSecondary),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _load,
                child: Text(LocaleKeys.hangout_manage_media_button_retry.tr()),
              ),
            ],
          ),
        ),
      );
    }
    final items = _media ?? const <HangoutMediaResponse>[];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(TablerIcons.photo_off, color: c.onSurfaceDisabled, size: 32),
              const SizedBox(height: 10),
              Text(
                LocaleKeys.hangout_manage_media_empty.tr(),
                style: TextStyle(color: c.onSurfaceSecondary, fontSize: 13),
              ),
            ],
          ),
        ),
      );
    }
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _MediaTile(
        media: items[i],
        deleting: _deleting.contains(items[i].id),
        onDelete: () => _confirmAndDelete(items[i]),
      ),
    );
  }
}

class _MediaTile extends StatelessWidget {
  final HangoutMediaResponse media;
  final bool deleting;
  final VoidCallback onDelete;
  const _MediaTile({
    required this.media,
    required this.deleting,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    final isVideo = media.mediaType.toLowerCase() == 'video';
    final imageUrl = isVideo ? media.thumbnailUrl : media.url;
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(10),
          ),
          child: imageUrl != null && imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Icon(
                    isVideo ? TablerIcons.video : TablerIcons.photo,
                    color: c.onSurfaceDisabled,
                    size: 28,
                  ),
                )
              : Center(
                  child: Icon(
                    isVideo ? TablerIcons.video : TablerIcons.photo,
                    color: c.onSurfaceDisabled,
                    size: 28,
                  ),
                ),
        ),
        if (isVideo)
          PositionedDirectional(
            top: 4,
            start: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Icon(
                TablerIcons.video,
                size: 12,
                color: Colors.white,
              ),
            ),
          ),
        PositionedDirectional(
          top: 4,
          end: 4,
          child: Material(
            color: Colors.black.withValues(alpha: 0.55),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: deleting ? null : onDelete,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: const EdgeInsets.all(6),
                child: deleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 1.5,
                        ),
                      )
                    : const Icon(
                        TablerIcons.trash,
                        color: Colors.white,
                        size: 14,
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
