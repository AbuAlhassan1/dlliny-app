import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/data/data_sources/camera_service.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:hangout/helper/image_picker.dart';
import 'package:hangout/presentation/my_profile/controller/my_profile_controller/my_profile_bloc.dart';

class UserAvatarPickerHeader extends StatelessWidget {
  final double size;
  const UserAvatarPickerHeader({super.key, this.size = 110});

  Future<void> _openPicker(BuildContext context) async {
    final c = context.c;
    final source = await showModalBottomSheet<_AvatarSource>(
      context: context,
      backgroundColor: c.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: c.onSurfaceDisabled,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(TablerIcons.camera, color: c.onSurface),
              title: Text(
                LocaleKeys.profile_avatar_picker_take_photo.tr(),
                style: TextStyle(color: c.onSurface),
              ),
              onTap: () => Navigator.of(sheetContext).pop(_AvatarSource.camera),
            ),
            ListTile(
              leading: Icon(TablerIcons.photo, color: c.onSurface),
              title: Text(
                LocaleKeys.profile_avatar_picker_from_gallery.tr(),
                style: TextStyle(color: c.onSurface),
              ),
              onTap: () =>
                  Navigator.of(sheetContext).pop(_AvatarSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || source == null) return;
    final file = source == _AvatarSource.camera
        ? await CameraService().takePhoto()
        : await pickImage();
    if (file == null || !context.mounted) return;
    _dispatch(context, file);
  }

  void _dispatch(BuildContext context, File file) {
    context.read<MyProfileBloc>().add(EditAvatar(file));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return Center(
      child: GestureDetector(
        onTap: () => _openPicker(context),
        behavior: HitTestBehavior.opaque,
        child: BlocBuilder<MyProfileBloc, ProfileState>(
          buildWhen: (prev, curr) =>
              curr is MyProfileLoaded ||
              curr is AvatarUploadUrlLoading ||
              curr is AvatarUploadUrlLoaded ||
              curr is AvatarUploadUrlError,
          builder: (context, state) {
            final user = context.read<MyProfileBloc>().user;
            final busy = state is AvatarUploadUrlLoading;
            final iconSize = size * 0.36;
            final spinnerSize = size * 0.2;
            return Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.surfaceMuted,
                    border: Border.all(color: c.onSurfaceDisabled, width: 2),
                  ),
                  child: ClipOval(
                    child: busy
                        ? Center(
                            child: SizedBox(
                              width: spinnerSize,
                              height: spinnerSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: c.onSurface,
                              ),
                            ),
                          )
                        : (user?.avatarUrl != null &&
                                user!.avatarUrl!.isNotEmpty)
                            ? CachedNetworkImage(
                                imageUrl: user.avatarUrl!,
                                fit: BoxFit.cover,
                                memCacheWidth: (size * 2.5).round(),
                                errorWidget: (_, _, _) => Icon(
                                  TablerIcons.user,
                                  color: c.onSurfaceSecondary,
                                  size: iconSize,
                                ),
                              )
                            : Icon(
                                TablerIcons.user,
                                color: c.onSurfaceSecondary,
                                size: iconSize,
                              ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: c.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: c.background, width: 2),
                  ),
                  child: Icon(
                    TablerIcons.camera,
                    color: c.onPrimary,
                    size: 16,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

enum _AvatarSource { camera, gallery }
