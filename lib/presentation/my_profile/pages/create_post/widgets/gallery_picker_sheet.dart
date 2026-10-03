import 'dart:io';
import 'dart:typed_data';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hangout/core/theme/colors.dart';
import 'package:hangout/generated/locale_keys.g.dart';
import 'package:photo_manager/photo_manager.dart';

class GalleryPickerSheet extends StatefulWidget {
  final int maxSelection;

  const GalleryPickerSheet({super.key, required this.maxSelection});

  @override
  State<GalleryPickerSheet> createState() => _GalleryPickerSheetState();
}

class _GalleryPickerSheetState extends State<GalleryPickerSheet> {
  List<AssetEntity> _assets = [];
  final List<AssetEntity> _selected = [];
  bool _loading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAssets();
  }

  Future<void> _loadAssets() async {
    final permission = await PhotoManager.requestPermissionExtend();
    if (!permission.hasAccess) {
      if (mounted) {
        setState(() {
          _loading = false;
          _errorMessage = 'Photo library access denied.';
        });
      }
      return;
    }

    final albums = await PhotoManager.getAssetPathList(
      type: RequestType.common,
      filterOption: FilterOptionGroup(
        imageOption: const FilterOption(needTitle: false),
        videoOption: const FilterOption(needTitle: false),
      ),
    );

    if (albums.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    final assets = await albums.first.getAssetListPaged(page: 0, size: 300);
    if (mounted) {
      setState(() {
        _assets = assets;
        _loading = false;
      });
    }
  }

  Future<void> _confirm() async {
    final files = <File>[];
    for (final asset in _selected) {
      final file = await asset.file;
      if (file != null) files.add(file);
    }
    if (mounted) Navigator.of(context).pop(files);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.c;
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(<File>[]),
                    child: Text(
                      LocaleKeys.common_cancel.tr(),
                      style: TextStyle(color: c.danger),
                    ),
                  ),
                  Text(
                    _selected.isEmpty
                        ? LocaleKeys.post_gallery_picker_pick_from_files.tr()
                        : '${_selected.length} / ${widget.maxSelection} selected',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextButton(
                    onPressed: _selected.isEmpty ? null : _confirm,
                    child: Text(
                      LocaleKeys.post_gallery_picker_done.tr(),
                      style: TextStyle(
                        color: _selected.isEmpty
                            ? c.onSurfaceDisabled
                            : c.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: _loading
                  ? Center(
                      child: CircularProgressIndicator(color: c.onSurface),
                    )
                  : _errorMessage != null
                  ? Center(
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: c.danger),
                      ),
                    )
                  : _assets.isEmpty
                  ? const Center(child: Text('No media found'))
                  : GridView.builder(
                      controller: scrollController,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      itemCount: _assets.length,
                      itemBuilder: (context, index) {
                        final asset = _assets[index];
                        final isSelected = _selected.contains(asset);
                        final selectionIndex = isSelected
                            ? _selected.indexOf(asset) + 1
                            : null;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _selected.remove(asset);
                              } else if (_selected.length <
                                  widget.maxSelection) {
                                _selected.add(asset);
                              }
                            });
                          },
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              FutureBuilder<Uint8List?>(
                                future: asset.thumbnailDataWithSize(
                                  const ThumbnailSize.square(200),
                                ),
                                builder: (context, snapshot) {
                                  if (snapshot.data == null) {
                                    return Container(color: c.surfaceMuted);
                                  }
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                              if (asset.type == AssetType.video)
                                Positioned(
                                  bottom: 4,
                                  left: 4,
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.videocam,
                                        color: c.onMediaSurface,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        _formatDuration(asset.duration),
                                        style: TextStyle(
                                          color: c.onMediaSurface,
                                          fontSize: 11,
                                          shadows: const [
                                            Shadow(blurRadius: 2),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (isSelected) Container(color: c.scrimSubtle),
                              Positioned(
                                top: 6,
                                right: 6,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? c.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: c.onMediaSurface,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Center(
                                          child: Text(
                                            '$selectionIndex',
                                            style: TextStyle(
                                              color: c.onPrimary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
