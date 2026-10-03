import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import 'package:hangout/presentation/hangout/share/hangout_story_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';

class HangoutStoryPreviewPage extends StatelessWidget {
  final HangoutStoryCard card;
  const HangoutStoryPreviewPage({super.key, required this.card});

  Future<void> _exportPng() async {
    final png = await ScreenshotController().captureFromWidget(
      card,
      pixelRatio: 1,
      targetSize: const Size(HangoutStoryCard.kWidth, HangoutStoryCard.kHeight),
      delay: const Duration(milliseconds: 400),
    );
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/story_preview.png');
    await file.writeAsBytes(png, flush: true);
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          isArabic ? 'معاينة الستوري' : 'Story preview',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            fontFamily: 'IBMPlexSansArabic',
          ),
        ),
        actions: [
          IconButton(
            tooltip: isArabic ? 'تصدير الصورة' : 'Export image',
            icon: const Icon(TablerIcons.download),
            onPressed: _exportPng,
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: HangoutStoryCard.kWidth,
                height: HangoutStoryCard.kHeight,
                child: card,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
