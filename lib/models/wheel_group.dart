// lib/models/wheel_group.dart

import 'package:flutter/material.dart';
import 'spin_wheel.dart';

class WheelGroup {
  final String id;
  String name;
  Color color;
  List<SpinWheel> wheels;
  String? description;

  WheelGroup({
    required this.id,
    required this.name,
    required this.color,
    List<SpinWheel>? wheels,
    this.description,
  }) : wheels = wheels ?? [];

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
}