// lib/data/models/wheel_option.dart

import 'package:flutter/material.dart';

/// Option d'une roue. Data class immuable.
final class WheelOption {
  final String id;
  final String name;
  final Color color;
  final double weight;

  const WheelOption({
    required this.id,
    required this.name,
    required this.color,
    this.weight = 1.0,
  });

  WheelOption copyWith({
    String? id,
    String? name,
    Color? color,
    double? weight,
  }) =>
      WheelOption(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        weight: weight ?? this.weight,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'weight': weight,
      };

  factory WheelOption.fromJson(Map<String, dynamic> json) => WheelOption(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WheelOption &&
          id == other.id &&
          name == other.name &&
          weight == other.weight;

  @override
  int get hashCode => Object.hash(id, name, weight);
}