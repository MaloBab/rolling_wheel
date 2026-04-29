// lib/data/models/wheel_group.dart

import 'spin_wheel.dart';

final class WheelGroup {
  final String id;
  final String name;
  final int colorValue;

  final List<SpinWheel> wheels;
  final String? description;

  const WheelGroup({
    required this.id,
    required this.name,
    required this.colorValue,
    this.wheels = const [],
    this.description,
  });

  WheelGroup copyWith({
    String? id,
    String? name,
    int? colorValue,
    List<SpinWheel>? wheels,
    String? description,
  }) =>
      WheelGroup(
        id: id ?? this.id,
        name: name ?? this.name,
        colorValue: colorValue ?? this.colorValue,
        wheels: wheels ?? this.wheels,
        description: description ?? this.description,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': colorValue,
        'description': description,
        'wheels': wheels.map((w) => w.toJson()).toList(),
      };

  factory WheelGroup.fromJson(Map<String, dynamic> json) => WheelGroup(
        id: json['id'] as String,
        name: json['name'] as String,
        colorValue: json['color'] as int,
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