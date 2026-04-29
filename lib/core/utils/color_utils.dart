// lib/core/utils/color_utils.dart

import 'package:flutter/material.dart';

abstract final class ColorUtils {
  static Color interpolateGradient(Color base, int index, int total) {
    if (total == 1) return base;
    final t = index / (total - 1);
    final r = (base.r * 255.0).round().clamp(0, 255);
    final g = (base.g * 255.0).round().clamp(0, 255);
    final b = (base.b * 255.0).round().clamp(0, 255);

    if (t <= 0.5) {
      final f = t / 0.5;
      return Color.fromARGB(
        255,
        (r * f).round().clamp(0, 255),
        (g * f).round().clamp(0, 255),
        (b * f).round().clamp(0, 255),
      );
    } else {
      final f = (t - 0.5) / 0.5;
      return Color.fromARGB(
        255,
        (r + ((255 - r) * f).round()).clamp(0, 255),
        (g + ((255 - g) * f).round()).clamp(0, 255),
        (b + ((255 - b) * f).round()).clamp(0, 255),
      );
    }
  }

  static Map<String, Color> buildGradientMap(List<({String id})> options, Color base) {
    if (options.isEmpty) return {};
    final n = options.length;
    return {
      for (int i = 0; i < n; i++)
        options[i].id: interpolateGradient(base, i, n),
    };
  }

  static Color contrastText(Color background) {
    return background.computeLuminance() > 0.4
        ? Colors.black.withAlpha(204)
        : Colors.white.withAlpha(230);
  }

  static int interpolateGradientInt(int baseArgb, int index, int total) {
    if (total == 1) return baseArgb;
    final t = index / (total - 1);
    final r = (baseArgb >> 16) & 0xFF;
    final g = (baseArgb >> 8) & 0xFF;
    final b = baseArgb & 0xFF;

    int nr, ng, nb;
    if (t <= 0.5) {
      final f = t / 0.5;
      nr = (r * f).round().clamp(0, 255);
      ng = (g * f).round().clamp(0, 255);
      nb = (b * f).round().clamp(0, 255);
    } else {
      final f = (t - 0.5) / 0.5;
      nr = (r + ((255 - r) * f).round()).clamp(0, 255);
      ng = (g + ((255 - g) * f).round()).clamp(0, 255);
      nb = (b + ((255 - b) * f).round()).clamp(0, 255);
    }
    return (0xFF << 24) | (nr << 16) | (ng << 8) | nb;
  }

  static Map<String, int> buildGradientMapFromInt(List<({String id})> options, int baseArgb) {
    if (options.isEmpty) return {};
    final n = options.length;
    return {
      for (int i = 0; i < n; i++)
        options[i].id: interpolateGradientInt(baseArgb, i, n),
    };
  }

  static int contrastTextInt(int backgroundArgb) {
    final r = (backgroundArgb >> 16) & 0xFF;
    final g = (backgroundArgb >> 8) & 0xFF;
    final b = backgroundArgb & 0xFF;
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.4
        ? (0xCC << 24) | 0x000000
        : (0xE6 << 24) | 0xFFFFFF;
  }
}