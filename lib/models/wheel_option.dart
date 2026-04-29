// lib/models/wheel_option.dart

import 'package:flutter/material.dart';

class WheelOption {
  final String id;
  String name;
  Color color;
  double weight; // Poids relatif (probabilité)

  WheelOption({
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
  }) {
    return WheelOption(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      weight: weight ?? this.weight,
    );
  }

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
}