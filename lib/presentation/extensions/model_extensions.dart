// lib/presentation/extensions/model_extensions.dart

import 'package:flutter/material.dart';
import '../../data/models/models.dart';

extension WheelOptionX on WheelOption {
  Color get color => Color(colorValue);

  WheelOption copyWithColor(Color color) =>
      copyWith(colorValue: color.toARGB32());
}

extension SpinWheelX on SpinWheel {
  Color? get gradientBaseColor => gradientBaseColorValue != null
      ? Color(gradientBaseColorValue!)
      : null;

  SpinWheel copyWithGradientColor(Color? color) => color == null
      ? copyWith(clearGradient: true)
      : copyWith(gradientBaseColorValue: color.toARGB32());
}

extension WheelGroupX on WheelGroup {
  Color get color => Color(colorValue);

  WheelGroup copyWithColor(Color color) =>
      copyWith(colorValue: color.toARGB32());
}

extension ColorX on Color {
  int toColorValue() => toARGB32();
}