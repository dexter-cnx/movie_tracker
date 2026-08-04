import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/shared/widgets/app_image.dart';

void main() {
  testWidgets('shows the fallback for an empty URL', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppImage.network('', width: 120, height: 180),
        ),
      ),
    );

    expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
  });

  testWidgets('uses a caller-provided error widget for an empty URL',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppImage.network(
            '   ',
            width: 120,
            height: 180,
            errorWidget: Text('image unavailable'),
          ),
        ),
      ),
    );

    expect(find.text('image unavailable'), findsOneWidget);
    expect(find.byIcon(Icons.broken_image_outlined), findsNothing);
  });
}
