// lib/presentation/providers/groups_provider.dart

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/group_factory.dart';
import '../theme/app_theme.dart';

const _uuid = Uuid();
class GroupsProvider extends ChangeNotifier {
  final GroupRepository _repository;

  GroupsProvider({GroupRepository? repository})
      : _repository = repository ?? SharedPrefsGroupRepository();

  List<WheelGroup> _groups = [];
  bool _loaded = false;

  List<WheelGroup> get groups => List.unmodifiable(_groups);
  bool get isLoaded => _loaded;


  Future<void> load() async {
    final loaded = await _repository.loadAll();
    _groups = loaded.isEmpty ? GroupFactory.sampleData() : loaded;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _repository.saveAll(_groups);

  WheelGroup addGroup({required String name, Color? color, String? description}) {
    final c = color ?? kGroupColors[_groups.length % kGroupColors.length];
    final g = WheelGroup(
      id: _uuid.v4(),
      name: name,
      color: c,
      description: description,
    );
    _groups = [..._groups, g];
    _persist();
    notifyListeners();
    return g;
  }

  void updateGroup(String groupId, {String? name, Color? color, String? description}) {
    _mutateGroup(
        groupId,
        (g) => g.copyWith(
              name: name,
              color: color,
              description: description,
            ));
  }

  void deleteGroup(String groupId) {
    _groups = _groups.where((g) => g.id != groupId).toList();
    _persist();
    notifyListeners();
  }

  void importGroup(WheelGroup group, {bool forceNewId = true}) {
    final toAdd = forceNewId ? GroupFactory.remapIds(group) : group;
    _groups = [..._groups, toAdd];
    _persist();
    notifyListeners();
  }

  void reorderGroups(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final list = [..._groups];
    list.insert(newIndex, list.removeAt(oldIndex));
    _groups = list;
    _persist();
    notifyListeners();
  }

  SpinWheel addWheel(String groupId, {required String name, List<String>? optionNames}) {
    final options = (optionNames ?? [])
        .asMap()
        .entries
        .map((e) => WheelOption(
              id: _uuid.v4(),
              name: e.value,
              color: kWheelColors[e.key % kWheelColors.length],
            ))
        .toList();
    final wheel = SpinWheel(id: _uuid.v4(), name: name, options: options);
    _mutateGroup(groupId, (g) => g.copyWith(wheels: [...g.wheels, wheel]));
    return wheel;
  }

  void updateWheel(String groupId, String wheelId, {String? name, bool? removeAfterSpin}) {
    _mutateWheel(groupId, wheelId,
        (w) => w.copyWith(name: name, removeAfterSpin: removeAfterSpin));
  }

  void updateWheelGradient(String groupId, String wheelId, Color? baseColor) {
    _mutateWheel(
        groupId,
        wheelId,
        (w) => baseColor == null
            ? w.copyWith(clearGradient: true)
            : w.copyWith(gradientBaseColor: baseColor));
  }

  void updateWheelRepeat(String groupId, String wheelId, {int? repeatCount, String? repeatSourceWheelId, bool clearSource = false}) {
    _mutateWheel(
      groupId,
      wheelId,
      (w) => w.copyWith(
        repeatCount: repeatCount,
        repeatSourceWheelId: repeatSourceWheelId,
        clearRepeatSource: clearSource,
      ),
    );
  }

  void updateWheelCondition(String groupId, String wheelId, String? condition) {
    final trimmed =
        (condition == null || condition.trim().isEmpty) ? null : condition.trim();
    _mutateWheel(
        groupId,
        wheelId,
        (w) => trimmed == null
            ? w.copyWith(clearCondition: true)
            : w.copyWith(displayCondition: trimmed));
  }

  void deleteWheel(String groupId, String wheelId) {
    _mutateGroup(
      groupId,
      (g) => g.copyWith(
        wheels: g.wheels.where((w) => w.id != wheelId).toList(),
      ),
    );
  }

  void reorderWheels(String groupId, int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    _mutateGroup(groupId, (g) {
      final list = [...g.wheels];
      list.insert(newIndex, list.removeAt(oldIndex));
      return g.copyWith(wheels: list);
    });
  }

  WheelOption addOption(String groupId, String wheelId, {required String name}) {
    final wheel = _findWheel(groupId, wheelId)!;
    final usedColors = wheel.options.map((o) => o.color).toSet();
    final color = kWheelColors.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => kWheelColors[wheel.options.length % kWheelColors.length],
    );
    final opt = WheelOption(id: _uuid.v4(), name: name, color: color);
    _mutateWheel(
        groupId, wheelId, (w) => w.copyWith(options: [...w.options, opt]));
    return opt;
  }

  void updateOption(String groupId, String wheelId, String optionId, {String? name, Color? color, double? weight}) {
    _mutateWheel(groupId, wheelId, (w) {
      final options = w.options.map((o) {
        if (o.id != optionId) return o;
        return o.copyWith(name: name, color: color, weight: weight);
      }).toList();
      return w.copyWith(options: options);
    });
  }

  void deleteOption(String groupId, String wheelId, String optionId) {
    _mutateWheel(
        groupId,
        wheelId,
        (w) => w.copyWith(
              options: w.options.where((o) => o.id != optionId).toList(),
            ));
  }

  void addDependency(String groupId, String wheelId, Dependency dep) {
    _mutateWheel(groupId, wheelId,
        (w) => w.copyWith(dependencies: [...w.dependencies, dep]));
  }

  void updateDependency(String groupId, String wheelId, int index, Dependency dep) {
    _mutateWheel(groupId, wheelId, (w) {
      final deps = [...w.dependencies];
      if (index >= deps.length) return w;
      deps[index] = dep;
      return w.copyWith(dependencies: deps);
    });
  }

  void removeDependency(String groupId, String wheelId, int index) {
    _mutateWheel(groupId, wheelId, (w) {
      final deps = [...w.dependencies]..removeAt(index);
      return w.copyWith(dependencies: deps);
    });
  }

  void setWheelResult(String groupId, String wheelId, String? result) {
    _mutateWheel(groupId, wheelId, (w) {
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
  }

  void resetGroupResults(String groupId) {
    _mutateGroup(groupId, (g) {
      return g.copyWith(
        wheels: g.wheels.map((w) => w.copyWith(clearResult: true)).toList(),
      );
    });
  }

  WheelGroup? _findGroup(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  SpinWheel? _findWheel(String groupId, String wheelId) {
    try {
      return _findGroup(groupId)?.wheels.firstWhere((w) => w.id == wheelId);
    } catch (_) {
      return null;
    }
  }

  void _mutateGroup(String groupId, WheelGroup Function(WheelGroup) transform) {
    _groups = _groups.map((g) {
      if (g.id != groupId) return g;
      return transform(g);
    }).toList();
    _persist();
    notifyListeners();
  }

  void _mutateWheel(String groupId, String wheelId, SpinWheel Function(SpinWheel) transform) {
    _mutateGroup(groupId, (g) {
      return g.copyWith(
        wheels: g.wheels.map((w) {
          if (w.id != wheelId) return w;
          return transform(w);
        }).toList(),
      );
    });
  }
}