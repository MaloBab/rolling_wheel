// lib/presentation/providers/groups_provider.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import '../../data/models/models.dart';
import '../../data/repositories/group_repository.dart';
import '../../domain/group_factory.dart';
import '../../domain/services/group_service.dart';

class GroupsProvider extends ChangeNotifier {
  final GroupRepository _repository;

  GroupsProvider({GroupRepository? repository})
      : _repository = repository ?? SharedPrefsGroupRepository();

  List<WheelGroup> _groups = [];
  bool _loaded = false;
  String? _persistenceError;

  List<WheelGroup> get groups => List.unmodifiable(_groups);
  bool get isLoaded => _loaded;
  String? get persistenceError => _persistenceError;

  Future<void> load() async {
    final loaded = await _repository.loadAll();
    _groups = loaded.isEmpty ? GroupFactory.sampleData() : loaded;
    _loaded = true;
    notifyListeners();
  }

  Future<WheelGroup> addGroup({required String name, Color? color, String? description}) async {
    final result = GroupService.addGroup(
      _groups,
      name: name,
      colorValue: color?.toARGB32(),
      description: description,
    );
    await _apply(result.updatedGroups);
    return result.value;
  }

  Future<void> updateGroup(String groupId, {String? name, Color? color, String? description}) async {
    await _apply(GroupService.updateGroup(
      _groups,
      groupId,
      name: name,
      colorValue: color?.toARGB32(),
      description: description,
    ));
  }

  Future<void> deleteGroup(String groupId) async {
    await _apply(GroupService.deleteGroup(_groups, groupId));
  }

  Future<void> importGroup(WheelGroup group, {bool forceNewId = true}) async {
    final toAdd = forceNewId ? GroupFactory.remapIds(group) : group;
    await _apply([..._groups, toAdd]);
  }

  Future<void> reorderGroups(int oldIndex, int newIndex) async {
    await _apply(GroupService.reorderGroups(_groups, oldIndex, newIndex));
  }


  Future<SpinWheel> addWheel(String groupId, {required String name, List<String>? optionNames}) async {
    final result = GroupService.addWheel(
      _groups,
      groupId,
      name: name,
      optionNames: optionNames,
    );
    await _apply(result.updatedGroups);
    return result.value;
  }

  Future<void> updateWheel(String groupId, String wheelId, {String? name, bool? removeAfterSpin}) async {
    await _apply(GroupService.updateWheel(_groups, groupId, wheelId, name: name, removeAfterSpin: removeAfterSpin));
  }

  Future<void> updateWheelGradient(String groupId, String wheelId, Color? baseColor) async {
    await _apply(GroupService.updateWheelGradient(_groups, groupId, wheelId, baseColor?.toARGB32()));
  }

  Future<void> updateWheelRepeat(String groupId, String wheelId, {int? repeatCount, String? repeatSourceWheelId, bool clearSource = false}) async {
    await _apply(GroupService.updateWheelRepeat(
      _groups, groupId, wheelId, repeatCount: repeatCount, repeatSourceWheelId: repeatSourceWheelId, clearSource: clearSource));
  }

  Future<void> updateWheelCondition(String groupId, String wheelId, String? condition) async {
    await _apply(GroupService.updateWheelCondition(_groups, groupId, wheelId, condition));
  }

  Future<void> deleteWheel(String groupId, String wheelId) async {
    await _apply(GroupService.deleteWheel(_groups, groupId, wheelId));
  }

  Future<void> reorderWheels(String groupId, int oldIndex, int newIndex) async {
    await _apply(
        GroupService.reorderWheels(_groups, groupId, oldIndex, newIndex));
  }

  Future<WheelOption> addOption(String groupId, String wheelId, {required String name}) async {
    final result = GroupService.addOption(_groups, groupId, wheelId, name: name);
    await _apply(result.updatedGroups);
    return result.value;
  }

  Future<void> updateOption(String groupId, String wheelId, String optionId, {String? name, Color? color, double? weight}) async {
    await _apply(GroupService.updateOption(_groups, groupId, wheelId, optionId, name: name, colorValue: color?.toARGB32(), weight: weight));
  }

  Future<void> deleteOption(String groupId, String wheelId, String optionId) async {
    await _apply(GroupService.deleteOption(_groups, groupId, wheelId, optionId));
  }

  Future<void> addDependency(String groupId, String wheelId, Dependency dep) async {
    await _apply(GroupService.addDependency(_groups, groupId, wheelId, dep));
  }

  Future<void> updateDependency(String groupId, String wheelId, int index, Dependency dep) async {
    await _apply(GroupService.updateDependency(_groups, groupId, wheelId, index, dep));
  }

  Future<void> removeDependency(String groupId, String wheelId, int index) async {
    await _apply(GroupService.removeDependency(_groups, groupId, wheelId, index));
  }

  Future<void> setWheelResult(String groupId, String wheelId, String? result) async {
    await _apply(GroupService.setWheelResult(_groups, groupId, wheelId, result));
  }

  Future<void> resetGroupResults(String groupId) async {
    await _apply(GroupService.resetGroupResults(_groups, groupId));
  }

  Future<void> _apply(List<WheelGroup> updated) async {
    _groups = updated;
    _persistenceError = null;
    notifyListeners();
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _repository.saveAll(_groups);
    } catch (e, stack) {
      _persistenceError = 'Sauvegarde échouée : $e';
      notifyListeners();
      debugPrintStack(stackTrace: stack, label: 'GroupsProvider._persist');
    }
  }
}