// lib/domain/group_factory.dart

import 'package:uuid/uuid.dart';
import '../data/models/models.dart';
import '../presentation/theme/app_theme.dart';

const _uuid = Uuid();

abstract final class GroupFactory {
  static WheelGroup remapIds(WheelGroup src) {
    final idMap = <String, String>{};

    List<WheelOption> remapOptions(List<WheelOption> opts) =>
        opts.map((o) {
          final newId = _uuid.v4();
          idMap[o.id] = newId;
          return o.copyWith(id: newId);
        }).toList();

    final newWheels = src.wheels.map((w) {
      final newWheelId = _uuid.v4();
      idMap[w.id] = newWheelId;
      return w.copyWith(id: newWheelId, options: remapOptions(w.options));
    }).toList();

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

  static List<WheelGroup> sampleData() {
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