// lib/data/models/wheel_group.dart

import 'package:flutter/material.dart';
import 'spin_wheel.dart';

final class WheelGroup {
  final String id;
  final String name;
  final Color color;
  final List<SpinWheel> wheels;
  final String? description;

  const WheelGroup({
    required this.id,
    required this.name,
    required this.color,
    this.wheels = const [],
    this.description,
  });

  WheelGroup copyWith({
    String? id,
    String? name,
    Color? color,
    List<SpinWheel>? wheels,
    String? description,
  }) =>
      WheelGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        color: color ?? this.color,
        wheels: wheels ?? this.wheels,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color.toARGB32(),
        'description': description,
        'wheels': wheels.map((w) => w.toJson()).toList(),
      };

  factory WheelGroup.fromJson(Map<String, dynamic> json) => WheelGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        color: Color(json['color'] as int),
        description: json['description'] as String?,
        wheels: (json['wheels'] as List? ?? [])
            .map((e) => SpinWheel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is WheelGroup && id == other.id;

  @override
  int get hashCode => id.hashCode;
}