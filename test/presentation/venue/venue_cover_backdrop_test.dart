import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hangout/core/theme/theme_data.dart';
import 'package:hangout/presentation/venue/widgets/venue_cover_backdrop.dart';

void main() {
  Future<void> pumpBackdrop(WidgetTester tester, ThemeData theme) {
    return tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: SizedBox(
            width: 390,
            height: 600,
            child: VenueCoverBackdrop(
              coverUrl: null,
              coverMediaType: null,
              coverThumbnailUrl: null,
            ),
          ),
        ),
      ),
    );
  }

  for (final (name, theme) in [
    ('light', Themes.lightTheme),
    ('dark', Themes.darkTheme),
  ]) {
    testWidgets('venue without a cover gets the blurred brand gradient ($name)',
        (tester) async {
      await pumpBackdrop(tester, theme);

      expect(find.byType(ImageFiltered), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('a video cover without a poster never loads the video URL',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: Themes.darkTheme,
        home: const Scaffold(
          body: VenueCoverBackdrop(
            coverUrl: 'https://cdn.example.com/cover.mp4',
            coverMediaType: 'video',
            coverThumbnailUrl: null,
          ),
        ),
      ),
    );

    expect(find.byType(ImageFiltered), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
