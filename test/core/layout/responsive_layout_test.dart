import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:popcorn_movie_tracker/core/layout/responsive_layout.dart';

void main() {
  group('ResponsiveLayout', () {
    test('classifies layouts from width-to-height ratio', () {
      expect(
        ResponsiveLayout.classOf(const Size(390, 844)),
        DeviceRatioClass.tallPortrait,
      );
      expect(
        ResponsiveLayout.classOf(const Size(768, 1024)),
        DeviceRatioClass.portrait,
      );
      expect(
        ResponsiveLayout.classOf(const Size(1024, 1024)),
        DeviceRatioClass.balanced,
      );
      expect(
        ResponsiveLayout.classOf(const Size(1366, 768)),
        DeviceRatioClass.wide,
      );
    });

    test('derives grid columns from ratio instead of absolute width', () {
      expect(ResponsiveLayout.gridColumns(const Size(390, 844)), 2);
      expect(ResponsiveLayout.gridColumns(const Size(768, 1024)), 3);
      expect(ResponsiveLayout.gridColumns(const Size(1024, 1024)), 4);
      expect(ResponsiveLayout.gridColumns(const Size(1366, 768)), 5);
    });

    test('devices with the same ratio use the same layout class', () {
      const phoneLandscape = Size(800, 450);
      const tabletLandscape = Size(1600, 900);

      expect(
        ResponsiveLayout.classOf(phoneLandscape),
        ResponsiveLayout.classOf(tabletLandscape),
      );
      expect(
        ResponsiveLayout.gridColumns(phoneLandscape),
        ResponsiveLayout.gridColumns(tabletLandscape),
      );
    });
  });
}
