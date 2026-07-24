import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/core/theme/app_theme.dart';
import 'package:popcorn_movie_tracker/shared/widgets/clay_widgets.dart';

const _runGoldens = bool.fromEnvironment('RUN_GOLDENS');

void main() {
  testWidgets(
    'cinematic dark clay components golden',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Popcorn',
                        style: AppTheme.light.textTheme.headlineLarge),
                    const SizedBox(height: 24),
                    const ClayCard(
                      child: Row(
                        children: [
                          ClayIconButton(icon: Icons.movie_rounded),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your Watch Stats',
                                    style:
                                        TextStyle(fontWeight: FontWeight.w900)),
                                SizedBox(height: 6),
                                Text('12 movies watched this month'),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Poster(
                        path: null,
                        title: 'Dune: Part Two',
                        width: 150,
                        height: 220),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/clay_components.png'),
      );
    },
    skip: !_runGoldens,
  );
}
