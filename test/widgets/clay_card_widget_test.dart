import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

void main() {
  testWidgets('ClayCard renders child content with app card styling', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Center(
            child: ClayCard(
              child: Text('Movie Card'),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Movie Card'), findsOneWidget);
    expect(find.byType(ClayCard), findsOneWidget);
  });

  testWidgets('Poster shows fallback title when image path is absent', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: Poster(path: null, title: 'Fallback Movie'),
        ),
      ),
    );

    expect(find.text('Fallback Movie'), findsOneWidget);
  });
}
