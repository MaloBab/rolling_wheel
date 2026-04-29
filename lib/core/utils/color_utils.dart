// lib/core/utils/color_utils.dart

import 'package:flutter/material.dart';

/// Utilitaires de manipulation de couleurs, sans dépendance aux modèles.
abstract final class ColorUtils {
  /// Interpole entre noir → [base] (milieu) → blanc selon la position
  /// normalisée [index] / ([total] - 1).
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

  /// Génère la map optionId → Color pour un dégradé sur [options].
  static Map<String, Color> buildGradientMap(
    List<({String id})> options,
    Color base,
  ) {
    if (options.isEmpty) return {};
    final n = options.length;
    return {
      for (int i = 0; i < n; i++)
        options[i].id: interpolateGradient(base, i, n),
    };
  }

  /// Retourne une couleur de texte contrastée (noir ou blanc) selon la
  /// luminance du fond.
  static Color contrastText(Color background) {
    return background.computeLuminance() > 0.4
        ? Colors.black.withAlpha(204)
        : Colors.white.withAlpha(230);
  }
}