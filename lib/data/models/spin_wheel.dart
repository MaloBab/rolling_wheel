// lib/data/models/spin_wheel.dart

import 'wheel_option.dart';
import 'dependency.dart';

final class SpinWheel {
  final String id;
  final String name;
  final List<WheelOption> options;
  final List<Dependency> dependencies;

  final String? result;
  final bool removeAfterSpin;

  final int? gradientBaseColorValue;

  final int repeatCount;
  final String? repeatSourceWheelId;
  final String? displayCondition;

  const SpinWheel({
    required this.id,
    required this.name,
    required this.options,
    this.dependencies = const [],
    this.result,
    this.removeAfterSpin = false,
    this.gradientBaseColorValue,
    this.repeatCount = 1,
    this.repeatSourceWheelId,
    this.displayCondition,
  });

  SpinWheel copyWith({
    String? id,
    String? name,
    List<WheelOption>? options,
    List<Dependency>? dependencies,
    String? result,
    bool? removeAfterSpin,
    int? gradientBaseColorValue,
    bool clearGradient = false,
    int? repeatCount,
    String? repeatSourceWheelId,
    bool clearRepeatSource = false,
    String? displayCondition,
    bool clearCondition = false,
    bool clearResult = false,
  }) =>
      SpinWheel(
        id: id ?? this.id,
        name: name ?? this.name,
        options: options ?? this.options,
        dependencies: dependencies ?? this.dependencies,
        result: clearResult ? null : result ?? this.result,
        removeAfterSpin: removeAfterSpin ?? this.removeAfterSpin,
        gradientBaseColorValue: clearGradient
            ? null
            : gradientBaseColorValue ?? this.gradientBaseColorValue,
        repeatCount: repeatCount ?? this.repeatCount,
        repeatSourceWheelId: clearRepeatSource
            ? null
            : repeatSourceWheelId ?? this.repeatSourceWheelId,
        displayCondition: clearCondition
            ? null
            : displayCondition ?? this.displayCondition,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'options': options.map((o) => o.toJson()).toList(),
        'dependencies': dependencies.map((d) => d.toJson()).toList(),
        'removeAfterSpin': removeAfterSpin,
        'gradientBaseColor': gradientBaseColorValue,
        'repeatCount': repeatCount,
        'repeatSourceWheelId': repeatSourceWheelId,
        'displayCondition': displayCondition,
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
        gradientBaseColorValue: json['gradientBaseColor'] as int?,
        repeatCount: (json['repeatCount'] as int?) ?? 1,
        repeatSourceWheelId: json['repeatSourceWheelId'] as String?,
        displayCondition: json['displayCondition'] as String?,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SpinWheel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}