// lib/domain/services/group_service.dart

import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';
import '../../core/constants/app_constants.dart';

const _uuid = Uuid();

typedef ServiceResult<T> = ({T value, List<WheelGroup> updatedGroups});

abstract final class GroupService {

  static ServiceResult<WheelGroup> addGroup(
    List<WheelGroup> groups, {
    required String name,
    int? colorValue,
    String? description,
  }) {
    final color = colorValue ?? kGroupColors[groups.length % kGroupColors.length].toARGB32();
    final group = WheelGroup(
      id: _uuid.v4(),
      name: name,
      colorValue: color,
      description: description,
    );
    return (value: group, updatedGroups: [...groups, group]);
  }

  static List<WheelGroup> updateGroup(
    List<WheelGroup> groups,
    String groupId, {
    String? name,
    int? colorValue,
    String? description,
  }) =>
      _mutateGroup(
        groups,
        groupId,
        (g) => g.copyWith(name: name, colorValue: colorValue, description: description),
      );

  static List<WheelGroup> deleteGroup(
    List<WheelGroup> groups,
    String groupId,
  ) =>
      groups.where((g) => g.id != groupId).toList();

  static List<WheelGroup> reorderGroups(
    List<WheelGroup> groups,
    int oldIndex,
    int newIndex,
  ) {
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final list = [...groups];
    list.insert(adjusted, list.removeAt(oldIndex));
    return list;
  }

  static ServiceResult<SpinWheel> addWheel(
    List<WheelGroup> groups,
    String groupId, {
    required String name,
    List<String>? optionNames,
  }) {
    final options = (optionNames ?? [])
        .asMap()
        .entries
        .map((e) => WheelOption(
              id: _uuid.v4(),
              name: e.value,
              colorValue: kWheelColors[e.key % kWheelColors.length].toARGB32(),
            ))
        .toList();
    final wheel = SpinWheel(id: _uuid.v4(), name: name, options: options);
    final updated = _mutateGroup(
      groups,
      groupId,
      (g) => g.copyWith(wheels: [...g.wheels, wheel]),
    );
    return (value: wheel, updatedGroups: updated);
  }

  static List<WheelGroup> updateWheel(
    List<WheelGroup> groups,
    String groupId,
    String wheelId, {
    String? name,
    bool? removeAfterSpin,
  }) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) => w.copyWith(name: name, removeAfterSpin: removeAfterSpin),
      );

  static List<WheelGroup> updateWheelGradient(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    int? baseColorValue,
  ) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) => baseColorValue == null
            ? w.copyWith(clearGradient: true)
            : w.copyWith(gradientBaseColorValue: baseColorValue),
      );

  static List<WheelGroup> updateWheelRepeat(
    List<WheelGroup> groups,
    String groupId,
    String wheelId, {
    int? repeatCount,
    String? repeatSourceWheelId,
    bool clearSource = false,
  }) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) => w.copyWith(
          repeatCount: repeatCount,
          repeatSourceWheelId: repeatSourceWheelId,
          clearRepeatSource: clearSource,
        ),
      );

  static List<WheelGroup> updateWheelCondition(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    String? condition,
  ) {
    final trimmed =
        (condition == null || condition.trim().isEmpty) ? null : condition.trim();
    return _mutateWheel(
      groups,
      groupId,
      wheelId,
      (w) => trimmed == null
          ? w.copyWith(clearCondition: true)
          : w.copyWith(displayCondition: trimmed),
    );
  }

  static List<WheelGroup> deleteWheel(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
  ) =>
      _mutateGroup(
        groups,
        groupId,
        (g) => g.copyWith(
          wheels: g.wheels.where((w) => w.id != wheelId).toList(),
        ),
      );

  static List<WheelGroup> reorderWheels(
    List<WheelGroup> groups,
    String groupId,
    int oldIndex,
    int newIndex,
  ) {
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    return _mutateGroup(groups, groupId, (g) {
      final list = [...g.wheels];
      list.insert(adjusted, list.removeAt(oldIndex));
      return g.copyWith(wheels: list);
    });
  }

  static ServiceResult<WheelOption> addOption(
    List<WheelGroup> groups,
    String groupId,
    String wheelId, {
    required String name,
  }) {
    final wheel = _findWheel(groups, groupId, wheelId)!;
    final usedColors = wheel.options.map((o) => o.colorValue).toSet();
    final colorValue = kWheelColors
        .firstWhere(
          (c) => !usedColors.contains(c.toARGB32()),
          orElse: () => kWheelColors[wheel.options.length % kWheelColors.length],
        )
        .toARGB32();

    final opt = WheelOption(id: _uuid.v4(), name: name, colorValue: colorValue);
    final updated = _mutateWheel(
      groups,
      groupId,
      wheelId,
      (w) => w.copyWith(options: [...w.options, opt]),
    );
    return (value: opt, updatedGroups: updated);
  }

  static List<WheelGroup> updateOption(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    String optionId, {
    String? name,
    int? colorValue,
    double? weight,
  }) =>
      _mutateWheel(groups, groupId, wheelId, (w) {
        final options = w.options.map((o) {
          if (o.id != optionId) return o;
          return o.copyWith(name: name, colorValue: colorValue, weight: weight);
        }).toList();
        return w.copyWith(options: options);
      });

  static List<WheelGroup> deleteOption(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    String optionId,
  ) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) => w.copyWith(
          options: w.options.where((o) => o.id != optionId).toList(),
        ),
      );

  static List<WheelGroup> addDependency(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    Dependency dep,
  ) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) => w.copyWith(dependencies: [...w.dependencies, dep]),
      );

  static List<WheelGroup> updateDependency(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    int index,
    Dependency dep,
  ) =>
      _mutateWheel(groups, groupId, wheelId, (w) {
        final deps = [...w.dependencies];
        if (index >= deps.length) return w;
        deps[index] = dep;
        return w.copyWith(dependencies: deps);
      });

  static List<WheelGroup> removeDependency(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    int index,
  ) =>
      _mutateWheel(
        groups,
        groupId,
        wheelId,
        (w) {
          final deps = [...w.dependencies]..removeAt(index);
          return w.copyWith(dependencies: deps);
        },
      );

  static List<WheelGroup> setWheelResult(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    String? result,
  ) =>
      _mutateWheel(groups, groupId, wheelId, (w) {
        final updated = w.copyWith(
          result: result,
          clearResult: result == null,
        );
        if (result != null && w.removeAfterSpin) {
          return updated.copyWith(
            options: updated.options.where((o) => o.name != result).toList(),
          );
        }
        return updated;
      });

  static List<WheelGroup> resetGroupResults(
    List<WheelGroup> groups,
    String groupId,
  ) =>
      _mutateGroup(
        groups,
        groupId,
        (g) => g.copyWith(
          wheels: g.wheels.map((w) => w.copyWith(clearResult: true)).toList(),
        ),
      );

  static List<WheelGroup> _mutateGroup(
    List<WheelGroup> groups,
    String groupId,
    WheelGroup Function(WheelGroup) transform,
  ) =>
      groups.map((g) => g.id == groupId ? transform(g) : g).toList();

  static List<WheelGroup> _mutateWheel(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
    SpinWheel Function(SpinWheel) transform,
  ) =>
      _mutateGroup(groups, groupId, (g) {
        return g.copyWith(
          wheels: g.wheels
              .map((w) => w.id == wheelId ? transform(w) : w)
              .toList(),
        );
      });

  static SpinWheel? _findWheel(
    List<WheelGroup> groups,
    String groupId,
    String wheelId,
  ) {
    try {
      return groups
          .firstWhere((g) => g.id == groupId)
          .wheels
          .firstWhere((w) => w.id == wheelId);
    } catch (_) {
      return null;
    }
  }
}