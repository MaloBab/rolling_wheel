// lib/models/spin_wheel.dart

import 'package:flutter/material.dart';
import 'wheel_option.dart';
import 'dependency.dart';

class SpinWheel {
  final String id;
  String name;
  List<WheelOption> options;
  List<Dependency> dependencies;
  String? result;
  bool removeAfterSpin;

  /// Couleur de base de la roue pour le dégradé (null = couleurs individuelles des options).
  /// Quand défini, les options sont colorées en dégradé : noir → couleur → blanc.
  Color? gradientBaseColor;

  /// Nombre de fois que cette roue doit tourner.
  /// Peut être surchargé dynamiquement via [repeatDependency].
  int repeatCount;

  /// ID de la roue source dont le résultat détermine [repeatCount].
  /// La roue source doit avoir des options dont le nom est un entier (ex: "2", "3").
  String? repeatSourceWheelId;

  SpinWheel({
    required this.id,
    required this.name,
    required this.options,
    List<Dependency>? dependencies,
    this.result,
    this.removeAfterSpin = false,
    this.gradientBaseColor,
    this.repeatCount = 1,
    this.repeatSourceWheelId,
  }) : dependencies = dependencies ?? [];

  /// Calcule les poids effectifs selon les dépendances résolues.
  Map<String, double> effectiveWeights(List<SpinWheel> allWheels) {
    final weights = {for (final o in options) o.id: o.weight};

    for (final dep in dependencies) {
      final srcIdx = allWheels.indexWhere((w) => w.id == dep.sourceWheelId);
      if (srcIdx == -1) continue;
      final src = allWheels[srcIdx];
      if (src.result == null) continue;

      final srcOption = src.options.firstWhere(
        (o) => o.name == src.result,
        orElse: () => WheelOption(id: '', name: '', color: Colors.transparent),
      );
      if (srcOption.id.isEmpty) continue;

      final override = dep.weights[srcOption.id];
      if (override != null) {
        for (final e in override.entries) {
          if (weights.containsKey(e.key)) weights[e.key] = e.value;
        }
      }
    }
    return weights;
  }

  /// Retourne true si tous les poids effectifs sont 0 (roue conditionnellement ignorée).
  bool isSkippedConditionally(List<SpinWheel> allWheels) {
    if (dependencies.isEmpty) return false;
    final weights = effectiveWeights(allWheels);
    final total = weights.values.fold(0.0, (s, v) => s + v);
    return total == 0.0;
  }

  /// Calcule le nombre de tours effectif en lisant le résultat de [repeatSourceWheelId].
  int effectiveRepeatCount(List<SpinWheel> allWheels) {
    if (repeatSourceWheelId == null) return repeatCount;
    final src = allWheels.firstWhere(
      (w) => w.id == repeatSourceWheelId,
      orElse: () => SpinWheel(id: '', name: '', options: []),
    );
    if (src.result == null) return repeatCount;
    final parsed = int.tryParse(src.result!);
    if (parsed != null && parsed > 0) return parsed;
    return repeatCount;
  }

  /// Génère les couleurs en dégradé pour les options selon [gradientBaseColor].
  /// Renvoie une map optionId → Color calculée.
  Map<String, Color> gradientColors() {
    if (gradientBaseColor == null || options.isEmpty) return {};
    final base = gradientBaseColor!;
    final n = options.length;
    return {
      for (int i = 0; i < n; i++)
        options[i].id: _interpolateGradient(base, i, n),
    };
  }

  /// Interpole entre noir → [base] (milieu) → blanc selon la position normalisée.
  static Color _interpolateGradient(Color base, int index, int total) {
    if (total == 1) return base;
    final t = index / (total - 1); // 0.0 → 1.0
    final baseRed = (base.r * 255.0).round().clamp(0, 255);
    final baseGreen = (base.g * 255.0).round().clamp(0, 255);
    final baseBlue = (base.b * 255.0).round().clamp(0, 255);
    if (t <= 0.5) {
      // Noir → base
      final f = t / 0.5;
      return Color.fromARGB(
        255,
        (baseRed * f).round().clamp(0, 255),
        (baseGreen * f).round().clamp(0, 255),
        (baseBlue * f).round().clamp(0, 255),
      );
    } else {
      // Base → blanc
      final f = (t - 0.5) / 0.5;
      return Color.fromARGB(
        255,
        (baseRed + ((255 - baseRed) * f).round()).clamp(0, 255),
        (baseGreen + ((255 - baseGreen) * f).round()).clamp(0, 255),
        (baseBlue + ((255 - baseBlue) * f).round()).clamp(0, 255),
      );
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((o) => o.toJson()).toList(),
        'dependencies': dependencies.map((d) => d.toJson()).toList(),
        'removeAfterSpin': removeAfterSpin,
        'gradientBaseColor': gradientBaseColor?.toARGB32(),
        'repeatCount': repeatCount,
        'repeatSourceWheelId': repeatSourceWheelId,
      };

  factory SpinWheel.fromJson(Map<String, dynamic> json) => SpinWheel(
        id: json['id'] as String,
        name: json['name'] as String,
        options: (json['options'] as List)
            .map((e) => WheelOption.fromJson(e as Map<String, dynamic>))
            .toList(),
        dependencies: (json['dependencies'] as List? ?? [])
            .map((e) => Dependency.fromJson(e as Map<String, dynamic>))
            .toList(),
        removeAfterSpin: json['removeAfterSpin'] as bool? ?? false,
        gradientBaseColor: json['gradientBaseColor'] != null
            ? Color(json['gradientBaseColor'] as int)
            : null,
        repeatCount: (json['repeatCount'] as int?) ?? 1,
        repeatSourceWheelId: json['repeatSourceWheelId'] as String?,
      );
}