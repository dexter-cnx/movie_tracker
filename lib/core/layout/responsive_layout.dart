import 'package:flutter/widgets.dart';

enum DeviceRatioClass { tallPortrait, portrait, balanced, wide }

abstract final class ResponsiveLayout {
  static double ratioOf(Size size) {
    if (size.height == 0) return 1;
    return size.width / size.height;
  }

  static DeviceRatioClass classOf(Size size) {
    final ratio = ratioOf(size);
    if (ratio < 0.62) return DeviceRatioClass.tallPortrait;
    if (ratio < 0.90) return DeviceRatioClass.portrait;
    if (ratio < 1.35) return DeviceRatioClass.balanced;
    return DeviceRatioClass.wide;
  }

  static int gridColumns(Size size) {
    switch (classOf(size)) {
      case DeviceRatioClass.tallPortrait:
        return 2;
      case DeviceRatioClass.portrait:
        return 3;
      case DeviceRatioClass.balanced:
        return 4;
      case DeviceRatioClass.wide:
        return 5;
    }
  }

  static double horizontalPadding(Size size) {
    switch (classOf(size)) {
      case DeviceRatioClass.tallPortrait:
        return 16;
      case DeviceRatioClass.portrait:
        return 20;
      case DeviceRatioClass.balanced:
        return 28;
      case DeviceRatioClass.wide:
        return 36;
    }
  }

  static bool useTwoPane(Size size) => classOf(size) == DeviceRatioClass.wide;
}
