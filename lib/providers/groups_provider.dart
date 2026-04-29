// lib/providers/groups_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/models.dart';
import '../utils/app_theme.dart';

const _kPrefsKey = 'spingroups_v1';
const _uuid = Uuid();

class GroupsProvider extends ChangeNotifier {
  List<WheelGroup> _groups = [];
  bool _loaded = false;

  List<WheelGroup> get groups => List.unmodifiable(_groups);
  bool get isLoaded => _loaded;

  // ──────────────────────────────────────────────
  // Persistence
  // ──────────────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_kPrefsKey);
    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List;
        _groups = list
            .map((e) => WheelGroup.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        _groups = _sampleGroups();
      }
    } else {
      _groups = _sampleGroups();
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_groups.map((g) => g.toJson()).toList());
    await prefs.setString(_kPrefsKey, raw);
  }

  // ──────────────────────────────────────────────
  // Groups CRUD
  // ──────────────────────────────────────────────

  WheelGroup addGroup({
    required String name,
    Color? color,
    String? description,
  }) {
    final c = color ?? kGroupColors[_groups.length % kGroupColors.length];
    final g = WheelGroup(
      id: _uuid.v4(),
      name: name,
      color: c,
      description: description,
    );
    _groups.add(g);
    _save();
    notifyListeners();
    return g;
  }

  void updateGroup(
    String groupId, {
    String? name,
    Color? color,
    String? description,
  }) {
    final g = _findGroup(groupId);
    if (g == null) return;
    if (name != null) g.name = name;
    if (color != null) g.color = color;
    if (description != null) g.description = description;
    _save();
    notifyListeners();
  }

  void deleteGroup(String groupId) {
    _groups.removeWhere((g) => g.id == groupId);
    _save();
    notifyListeners();
  }

  /// Importe un groupe (depuis fichier ou JSON). Génère un nouvel ID pour éviter
  /// les conflits si le groupe est déjà présent.
  void importGroup(WheelGroup group, {bool forceNewId = true}) {
    if (forceNewId) {
      final newGroup = _remapIds(group);
      _groups.add(newGroup);
    } else {
      _groups.add(group);
    }
    _save();
    notifyListeners();
  }

  void reorderGroups(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    final g = _groups.removeAt(oldIndex);
    _groups.insert(newIndex, g);
    _save();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Wheels CRUD
  // ──────────────────────────────────────────────

  SpinWheel addWheel(String groupId, {required String name, List<String>? optionNames}) {
    final g = _findGroup(groupId)!;
    final options = (optionNames ?? ['Option A', 'Option B', 'Option C'])
        .asMap()
        .entries
        .map((e) => WheelOption(
              id: _uuid.v4(),
              name: e.value,
              color: kWheelColors[e.key % kWheelColors.length],
              weight: 1.0,
            ))
        .toList();
    final w = SpinWheel(id: _uuid.v4(), name: name, options: options);
    g.wheels.add(w);
    _save();
    notifyListeners();
    return w;
  }

  void updateWheel(String groupId, String wheelId, {String? name, bool? removeAfterSpin}) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    if (name != null) w.name = name;
    if (removeAfterSpin != null) w.removeAfterSpin = removeAfterSpin;
    _save();
    notifyListeners();
  }

  /// Met à jour la couleur de base du dégradé d'une roue.
  /// Passer [null] pour désactiver le mode dégradé.
  void updateWheelGradient(String groupId, String wheelId, Color? baseColor) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    w.gradientBaseColor = baseColor;
    _save();
    notifyListeners();
  }

  /// Met à jour les paramètres de répétition d'une roue.
  void updateWheelRepeat(
    String groupId,
    String wheelId, {
    int? repeatCount,
    String? repeatSourceWheelId,
    bool clearSource = false,
  }) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    if (repeatCount != null) w.repeatCount = repeatCount;
    if (clearSource) {
      w.repeatSourceWheelId = null;
    } else if (repeatSourceWheelId != null) {
      w.repeatSourceWheelId = repeatSourceWheelId;
    }
    _save();
    notifyListeners();
  }

  void deleteWheel(String groupId, String wheelId) {
    final g = _findGroup(groupId);
    if (g == null) return;
    g.wheels.removeWhere((w) => w.id == wheelId);
    _save();
    notifyListeners();
  }

  void reorderWheels(String groupId, int oldIndex, int newIndex) {
    final g = _findGroup(groupId);
    if (g == null) return;
    if (newIndex > oldIndex) newIndex--;
    final w = g.wheels.removeAt(oldIndex);
    g.wheels.insert(newIndex, w);
    _save();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Options CRUD
  // ──────────────────────────────────────────────

  WheelOption addOption(String groupId, String wheelId, {required String name}) {
    final w = _findWheel(groupId, wheelId)!;
    final usedColors = w.options.map((o) => o.color).toSet();
    final color = kWheelColors.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => kWheelColors[w.options.length % kWheelColors.length],
    );
    final opt = WheelOption(id: _uuid.v4(), name: name, color: color);
    w.options.add(opt);
    _save();
    notifyListeners();
    return opt;
  }

  void updateOption(
    String groupId,
    String wheelId,
    String optionId, {
    String? name,
    Color? color,
    double? weight,
  }) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    final idx = w.options.indexWhere((o) => o.id == optionId);
    if (idx == -1) return;
    final o = w.options[idx];
    w.options[idx] = WheelOption(
      id: o.id,
      name: name ?? o.name,
      color: color ?? o.color,
      weight: weight ?? o.weight,
    );
    _save();
    notifyListeners();
  }

  void deleteOption(String groupId, String wheelId, String optionId) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    w.options.removeWhere((o) => o.id == optionId);
    _save();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Dependencies CRUD
  // ──────────────────────────────────────────────

  void addDependency(String groupId, String wheelId, Dependency dep) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    w.dependencies.add(dep);
    _save();
    notifyListeners();
  }

  void updateDependency(String groupId, String wheelId, int depIndex, Dependency dep) {
    final w = _findWheel(groupId, wheelId);
    if (w == null || depIndex >= w.dependencies.length) return;
    w.dependencies[depIndex] = dep;
    _save();
    notifyListeners();
  }

  void removeDependency(String groupId, String wheelId, int depIndex) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    w.dependencies.removeAt(depIndex);
    _save();
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Session (résultats de tirage)
  // ──────────────────────────────────────────────

  void setWheelResult(String groupId, String wheelId, String? result) {
    final w = _findWheel(groupId, wheelId);
    if (w == null) return;
    w.result = result;
    if (result != null && w.removeAfterSpin) {
      w.options.removeWhere((o) => o.name == result);
    }
    _save();
    notifyListeners();
  }

  void resetGroupResults(String groupId) {
    final g = _findGroup(groupId);
    if (g == null) return;
    for (final w in g.wheels) {
      w.result = null;
    }
    notifyListeners();
  }

  // ──────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────

  WheelGroup? _findGroup(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  SpinWheel? _findWheel(String groupId, String wheelId) {
    final g = _findGroup(groupId);
    if (g == null) return null;
    try {
      return g.wheels.firstWhere((w) => w.id == wheelId);
    } catch (_) {
      return null;
    }
  }

  /// Génère de nouveaux IDs pour tout le groupe (import sans collision).
  WheelGroup _remapIds(WheelGroup src) {
    final idMap = <String, String>{};

    List<WheelOption> remapOptions(List<WheelOption> opts) =>
        opts.map((o) {
          final newId = _uuid.v4();
          idMap[o.id] = newId;
          return WheelOption(id: newId, name: o.name, color: o.color, weight: o.weight);
        }).toList();

    final newWheels = src.wheels.map((w) {
      final newWheelId = _uuid.v4();
      idMap[w.id] = newWheelId;
      return SpinWheel(
        id: newWheelId,
        name: w.name,
        options: remapOptions(w.options),
        removeAfterSpin: w.removeAfterSpin,
        gradientBaseColor: w.gradientBaseColor,
        repeatCount: w.repeatCount,
      );
    }).toList();

    for (int i = 0; i < src.wheels.length; i++) {
      final oldWheel = src.wheels[i];
      final newWheel = newWheels[i];
      newWheel.dependencies = oldWheel.dependencies.map((dep) {
        final newSrcId = idMap[dep.sourceWheelId] ?? dep.sourceWheelId;
        final newWeights = dep.weights.map((srcOptId, tgtMap) {
          final newSrcOptId = idMap[srcOptId] ?? srcOptId;
          final newTgtMap = tgtMap.map((tgtOptId, val) {
            final newTgtOptId = idMap[tgtOptId] ?? tgtOptId;
            return MapEntry(newTgtOptId, val);
          });
          return MapEntry(newSrcOptId, newTgtMap);
        });
        return Dependency(sourceWheelId: newSrcId, weights: newWeights);
      }).toList();

      // Remap repeatSourceWheelId si présent
      if (oldWheel.repeatSourceWheelId != null) {
        newWheel.repeatSourceWheelId = idMap[oldWheel.repeatSourceWheelId] ?? oldWheel.repeatSourceWheelId;
      }
    }

    return WheelGroup(
      id: _uuid.v4(),
      name: src.name,
      color: src.color,
      description: src.description,
      wheels: newWheels,
    );
  }

  // ──────────────────────────────────────────────
  // Sample data
  // ──────────────────────────────────────────────

  List<WheelGroup> _sampleGroups() {
    final raceId = _uuid.v4();
    final classId = _uuid.v4();
    final bgId = _uuid.v4();

    final raceOptElf = WheelOption(id: _uuid.v4(), name: 'Elfe', color: kWheelColors[2], weight: 1);
    final raceOptHuman = WheelOption(id: _uuid.v4(), name: 'Humain', color: kWheelColors[0], weight: 2);
    final raceOptDwarf = WheelOption(id: _uuid.v4(), name: 'Nain', color: kWheelColors[5], weight: 1);
    final raceOptOrc = WheelOption(id: _uuid.v4(), name: 'Orc', color: kWheelColors[3], weight: 1);

    final raceWheel = SpinWheel(
      id: raceId,
      name: 'Race',
      options: [raceOptElf, raceOptHuman, raceOptDwarf, raceOptOrc],
    );

    final classOptMage = WheelOption(id: _uuid.v4(), name: 'Mage', color: kWheelColors[0], weight: 1);
    final classOptWarrior = WheelOption(id: _uuid.v4(), name: 'Guerrier', color: kWheelColors[3], weight: 1);
    final classOptRogue = WheelOption(id: _uuid.v4(), name: 'Voleur', color: kWheelColors[1], weight: 1);
    final classOptDruid = WheelOption(id: _uuid.v4(), name: 'Druide', color: kWheelColors[2], weight: 1);

    final classWheel = SpinWheel(
      id: classId,
      name: 'Classe',
      options: [classOptMage, classOptWarrior, classOptRogue, classOptDruid],
      dependencies: [
        Dependency(
          sourceWheelId: raceId,
          weights: {
            raceOptElf.id: {
              classOptMage.id: 4.0,
              classOptWarrior.id: 1.0,
              classOptRogue.id: 2.0,
              classOptDruid.id: 3.0,
            },
            raceOptOrc.id: {
              classOptMage.id: 0.5,
              classOptWarrior.id: 5.0,
              classOptRogue.id: 1.0,
              classOptDruid.id: 0.5,
            },
            raceOptDwarf.id: {
              classOptMage.id: 1.0,
              classOptWarrior.id: 3.0,
              classOptRogue.id: 2.0,
              classOptDruid.id: 1.0,
            },
            raceOptHuman.id: {
              classOptMage.id: 2.0,
              classOptWarrior.id: 2.0,
              classOptRogue.id: 2.0,
              classOptDruid.id: 2.0,
            },
          },
        ),
      ],
    );

    final bgWheel = SpinWheel(
      id: bgId,
      name: 'Origine',
      options: [
        WheelOption(id: _uuid.v4(), name: 'Noble', color: kWheelColors[1], weight: 1),
        WheelOption(id: _uuid.v4(), name: 'Orphelin', color: kWheelColors[5], weight: 2),
        WheelOption(id: _uuid.v4(), name: 'Érudit', color: kWheelColors[6], weight: 1),
        WheelOption(id: _uuid.v4(), name: 'Soldat', color: kWheelColors[3], weight: 2),
        WheelOption(id: _uuid.v4(), name: 'Marchand', color: kWheelColors[4], weight: 1),
      ],
    );

    final group = WheelGroup(
      id: _uuid.v4(),
      name: 'Création de personnage',
      color: kGroupColors[0],
      description: 'Génération aléatoire de personnage RPG',
      wheels: [raceWheel, classWheel, bgWheel],
    );

    return [group];
  }
}