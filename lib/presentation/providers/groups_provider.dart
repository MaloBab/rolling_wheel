// lib/presentation/providers/groups_provider.dart
//
// Provider mince : orchestre le repository et expose l'état à l'UI.
// Pas de logique métier ici — tout est délégué au repository ou au domain.

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/models.dart';
import '../../data/repositories/group_repository.dart';
import '../../presentation/theme/app_theme.dart';

const _uuid = Uuid();

class GroupsProvider extends ChangeNotifier {
  final GroupRepository _repository;

  GroupsProvider({GroupRepository? repository})
      : _repository = repository ?? SharedPrefsGroupRepository();

  List<WheelGroup> _groups = [];
  bool _loaded = false;

  List<WheelGroup> get groups => List.unmodifiable(_groups);
  bool get isLoaded => _loaded;

  // ── Persistence ────────────────────────────────────────────────────────────

  Future<void> load() async {
    final loaded = await _repository.loadAll();
    _groups = loaded.isEmpty ? _sampleGroups() : loaded;
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() => _repository.saveAll(_groups);

  // ── Groups ─────────────────────────────────────────────────────────────────

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
    _groups = [..._groups, g];
    _persist();
    notifyListeners();
    return g;
  }

  void updateGroup(
    String groupId, {
    String? name,
    Color? color,
    String? description,
  }) {
    _mutateGroup(groupId, (g) => g.copyWith(
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
    final toAdd = forceNewId ? _remapIds(group) : group;
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

  // ── Wheels ─────────────────────────────────────────────────────────────────

  SpinWheel addWheel(
    String groupId, {
    required String name,
    List<String>? optionNames,
  }) {
    final options = (optionNames ?? ['Option A', 'Option B', 'Option C'])
        .asMap()
        .entries
        .map((e) => WheelOption(
              id: _uuid.v4(),
              name: e.value,
              color: kWheelColors[e.key % kWheelColors.length],
            ))
        .toList();
    final wheel = SpinWheel(id: _uuid.v4(), name: name, options: options);
    _mutateGroup(groupId,
        (g) => g.copyWith(wheels: [...g.wheels, wheel]));
    return wheel;
  }

  void updateWheel(
    String groupId,
    String wheelId, {
    String? name,
    bool? removeAfterSpin,
  }) {
    _mutateWheel(groupId, wheelId,
        (w) => w.copyWith(name: name, removeAfterSpin: removeAfterSpin));
  }

  void updateWheelGradient(
    String groupId,
    String wheelId,
    Color? baseColor,
  ) {
    _mutateWheel(groupId, wheelId, (w) => baseColor == null
        ? w.copyWith(clearGradient: true)
        : w.copyWith(gradientBaseColor: baseColor));
  }

  void updateWheelRepeat(
    String groupId,
    String wheelId, {
    int? repeatCount,
    String? repeatSourceWheelId,
    bool clearSource = false,
  }) {
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

  void updateWheelCondition(
    String groupId,
    String wheelId,
    String? condition,
  ) {
    final trimmed =
        (condition == null || condition.trim().isEmpty) ? null : condition.trim();
    _mutateWheel(groupId, wheelId, (w) => trimmed == null
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

  // ── Options ────────────────────────────────────────────────────────────────

  WheelOption addOption(String groupId, String wheelId, {required String name}) {
    final wheel = _findWheel(groupId, wheelId)!;
    final usedColors = wheel.options.map((o) => o.color).toSet();
    final color = kWheelColors.firstWhere(
      (c) => !usedColors.contains(c),
      orElse: () => kWheelColors[wheel.options.length % kWheelColors.length],
    );
    final opt = WheelOption(id: _uuid.v4(), name: name, color: color);
    _mutateWheel(groupId, wheelId,
        (w) => w.copyWith(options: [...w.options, opt]));
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
    _mutateWheel(groupId, wheelId, (w) {
      final options = w.options.map((o) {
        if (o.id != optionId) return o;
        return o.copyWith(name: name, color: color, weight: weight);
      }).toList();
      return w.copyWith(options: options);
    });
  }

  void deleteOption(String groupId, String wheelId, String optionId) {
    _mutateWheel(groupId, wheelId, (w) => w.copyWith(
          options: w.options.where((o) => o.id != optionId).toList(),
        ));
  }

  // ── Dependencies ───────────────────────────────────────────────────────────

  void addDependency(String groupId, String wheelId, Dependency dep) {
    _mutateWheel(groupId, wheelId,
        (w) => w.copyWith(dependencies: [...w.dependencies, dep]));
  }

  void updateDependency(
    String groupId,
    String wheelId,
    int index,
    Dependency dep,
  ) {
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

  // ── Session / résultats ────────────────────────────────────────────────────

  /// Enregistre le résultat d'un tirage. Si [removeAfterSpin] est activé,
  /// l'option est retirée de la roue.
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

  /// Réinitialise tous les résultats d'un groupe (début de session).
  void resetGroupResults(String groupId) {
    _mutateGroup(groupId, (g) {
      return g.copyWith(
        wheels: g.wheels
            .map((w) => w.copyWith(clearResult: true))
            .toList(),
      );
    });
  }

  // ── Helpers privés ─────────────────────────────────────────────────────────

  WheelGroup? _findGroup(String id) {
    try {
      return _groups.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }

  SpinWheel? _findWheel(String groupId, String wheelId) {
    try {
      return _findGroup(groupId)
          ?.wheels
          .firstWhere((w) => w.id == wheelId);
    } catch (_) {
      return null;
    }
  }

  /// Applique [transform] sur le groupe trouvé et notifie.
  void _mutateGroup(String groupId, WheelGroup Function(WheelGroup) transform) {
    _groups = _groups.map((g) {
      if (g.id != groupId) return g;
      return transform(g);
    }).toList();
    _persist();
    notifyListeners();
  }

  /// Applique [transform] sur la roue trouvée et notifie.
  void _mutateWheel(
    String groupId,
    String wheelId,
    SpinWheel Function(SpinWheel) transform,
  ) {
    _mutateGroup(groupId, (g) {
      return g.copyWith(
        wheels: g.wheels.map((w) {
          if (w.id != wheelId) return w;
          return transform(w);
        }).toList(),
      );
    });
  }

  // ── Remappage d'IDs à l'import ────────────────────────────────────────────

  WheelGroup _remapIds(WheelGroup src) {
    final idMap = <String, String>{};

    List<WheelOption> remapOptions(List<WheelOption> opts) =>
        opts.map((o) {
          final newId = _uuid.v4();
          idMap[o.id] = newId;
          return o.copyWith(id: newId);
        }).toList();

    // Première passe : nouveaux IDs pour roues et options
    final newWheels = src.wheels.map((w) {
      final newWheelId = _uuid.v4();
      idMap[w.id] = newWheelId;
      return w.copyWith(id: newWheelId, options: remapOptions(w.options));
    }).toList();

    // Deuxième passe : remapper les références dans dépendances et repeatSource
    final remapped = src.wheels.asMap().entries.map((entry) {
      final oldWheel = entry.value;
      final newWheel = newWheels[entry.key];

      final newDeps = oldWheel.dependencies.map((dep) {
        return Dependency(
          sourceWheelId: idMap[dep.sourceWheelId] ?? dep.sourceWheelId,
          weights: dep.weights.map((srcOptId, tgtMap) {
            return MapEntry(
              idMap[srcOptId] ?? srcOptId,
              tgtMap.map(
                (tgtOptId, val) => MapEntry(idMap[tgtOptId] ?? tgtOptId, val),
              ),
            );
          }),
        );
      }).toList();

      final newRepeatSrc = oldWheel.repeatSourceWheelId != null
          ? idMap[oldWheel.repeatSourceWheelId] ?? oldWheel.repeatSourceWheelId
          : null;

      return newWheel.copyWith(
        dependencies: newDeps,
        repeatSourceWheelId: newRepeatSrc,
        // displayCondition référence les noms, pas les IDs → copie directe
        displayCondition: oldWheel.displayCondition,
      );
    }).toList();

    return WheelGroup(
      id: _uuid.v4(),
      name: src.name,
      color: src.color,
      description: src.description,
      wheels: remapped,
    );
  }

  // ── Données d'exemple ──────────────────────────────────────────────────────

  List<WheelGroup> _sampleGroups() {
    final raceOptElf = WheelOption(
        id: _uuid.v4(), name: 'Elfe', color: kWheelColors[2], weight: 1);
    final raceOptHuman = WheelOption(
        id: _uuid.v4(), name: 'Humain', color: kWheelColors[0], weight: 2);
    final raceOptDwarf = WheelOption(
        id: _uuid.v4(), name: 'Nain', color: kWheelColors[5], weight: 1);
    final raceOptOrc = WheelOption(
        id: _uuid.v4(), name: 'Orc', color: kWheelColors[3], weight: 1);

    final raceWheel = SpinWheel(
      id: _uuid.v4(),
      name: 'Race',
      options: [raceOptElf, raceOptHuman, raceOptDwarf, raceOptOrc],
    );

    final classOptMage = WheelOption(
        id: _uuid.v4(), name: 'Mage', color: kWheelColors[0], weight: 1);
    final classOptWarrior = WheelOption(
        id: _uuid.v4(), name: 'Guerrier', color: kWheelColors[3], weight: 1);
    final classOptRogue = WheelOption(
        id: _uuid.v4(), name: 'Voleur', color: kWheelColors[1], weight: 1);
    final classOptDruid = WheelOption(
        id: _uuid.v4(), name: 'Druide', color: kWheelColors[2], weight: 1);

    final classWheel = SpinWheel(
      id: _uuid.v4(),
      name: 'Classe',
      options: [classOptMage, classOptWarrior, classOptRogue, classOptDruid],
      dependencies: [
        Dependency(
          sourceWheelId: raceWheel.id,
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

    final origineWheel = SpinWheel(
      id: _uuid.v4(),
      name: 'Origine',
      options: [
        WheelOption(
            id: _uuid.v4(), name: 'Noble', color: kWheelColors[1], weight: 1),
        WheelOption(
            id: _uuid.v4(),
            name: 'Orphelin',
            color: kWheelColors[5],
            weight: 2),
        WheelOption(
            id: _uuid.v4(),
            name: 'Érudit',
            color: kWheelColors[6],
            weight: 1),
        WheelOption(
            id: _uuid.v4(),
            name: 'Soldat',
            color: kWheelColors[3],
            weight: 2),
        WheelOption(
            id: _uuid.v4(),
            name: 'Marchand',
            color: kWheelColors[4],
            weight: 1),
      ],
    );

    return [
      WheelGroup(
        id: _uuid.v4(),
        name: 'Création de personnage',
        color: kGroupColors[0],
        description: 'Génération aléatoire de personnage RPG',
        wheels: [raceWheel, classWheel, origineWheel],
      ),
    ];
  }
}