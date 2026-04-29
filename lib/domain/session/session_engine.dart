// lib/domain/session/session_engine.dart

import 'dart:math' as math;
import '../../core/utils/color_utils.dart';
import '../../core/utils/condition_parser.dart';
import '../../data/models/models.dart';
import 'session_step.dart';

abstract final class SessionEngine {

  static Map<String, double> effectiveWeights(SpinWheel wheel, List<SpinWheel> allWheels) {
    final weights = {for (final o in wheel.options) o.id: o.weight};

    for (final dep in wheel.dependencies) {
      final src = _findWheel(allWheels, dep.sourceWheelId);
      if (src == null || src.result == null) continue;

      final srcOption = src.options.firstWhere(
        (o) => o.name == src.result,
        orElse: () => const WheelOption(id: '', name: '', colorValue: 0x00000000),
      );
      if (srcOption.id.isEmpty) continue;

      final override = dep.weights[srcOption.id];
      if (override != null) {
        for (final e in override.entries) {
          if (weights.containsKey(e.key)) weights[e.key] = e.value;
        }
      }
    }
    return weights;
  }

  static Map<String, int> gradientColorValues(SpinWheel wheel) {
    if (wheel.gradientBaseColorValue == null) return {};
    return ColorUtils.buildGradientMapFromInt(
      wheel.options.map((o) => (id: o.id)).toList(),
      wheel.gradientBaseColorValue!,
    );
  }

  static bool isSkipped(SpinWheel wheel, List<SpinWheel> allWheels) {
    if (wheel.displayCondition != null &&
        wheel.displayCondition!.trim().isNotEmpty) {
      final wheelData = allWheels
          .where((w) => w.id != wheel.id)
          .map((w) => (name: w.name, result: w.result))
          .toList();
      if (!ConditionParser.evaluate(wheel.displayCondition, wheelData)) {
        return true;
      }
    }

    if (wheel.dependencies.isEmpty) return false;
    final weights = effectiveWeights(wheel, allWheels);
    final total = weights.values.fold(0.0, (s, v) => s + v);
    return total == 0.0;
  }

  static int effectiveRepeatCount(SpinWheel wheel, List<SpinWheel> allWheels) {
    if (wheel.repeatSourceWheelId == null) return wheel.repeatCount;
    final src = _findWheel(allWheels, wheel.repeatSourceWheelId!);
    if (src?.result == null) return wheel.repeatCount;
    final parsed = int.tryParse(src!.result!);
    return (parsed != null && parsed > 0) ? parsed : wheel.repeatCount;
  }

  static List<SessionStep> buildInitialSteps(List<SpinWheel> wheels) {
    return [
      for (final w in wheels)
        SessionStep(wheel: w, spinNumber: 1, totalSpins: 1),
    ];
  }

  static List<SessionStep> rebuildSteps(List<SpinWheel> allWheels, List<SessionStep> previousSteps) {
    final rebuilt = <SessionStep>[];

    for (final wheel in allWheels) {
      if (isSkipped(wheel, allWheels)) {
        rebuilt.add(SessionStep(wheel: wheel, spinNumber: 1, totalSpins: 1, skipped: true));
      } else {
        final count = effectiveRepeatCount(wheel, allWheels);
        for (var i = 0; i < count; i++) {
          rebuilt.add(SessionStep(
            wheel: wheel,
            spinNumber: i + 1,
            totalSpins: count,
          ));
        }
      }
    }

    int oldIdx = 0;
    for (int i = 0; i < rebuilt.length && oldIdx < previousSteps.length; i++) {
      while (oldIdx < previousSteps.length &&
          previousSteps[oldIdx].wheel.id != rebuilt[i].wheel.id) {
        oldIdx++;
      }
      if (oldIdx < previousSteps.length) {
        rebuilt[i] = rebuilt[i].copyWith(
          result: previousSteps[oldIdx].result,
          skipped: previousSteps[oldIdx].skipped,
        );
        oldIdx++;
      }
    }

    return rebuilt;
  }

  static WheelOption? resolveWinner(SpinWheel wheel, Map<String, double> weights, double angle) {
    final activeOpts = wheel.options.where((o) => (weights[o.id] ?? 0) > 0).toList();
    if (activeOpts.isEmpty) return null;

    final total = activeOpts.fold(0.0, (s, o) => s + (weights[o.id] ?? 0));
    final finalAngle = angle % (math.pi * 2);
    final pointer = ((math.pi * 2) - finalAngle) % (math.pi * 2);

    double cum = 0;
    for (final opt in activeOpts) {
      cum += (weights[opt.id]! / total) * math.pi * 2;
      if (pointer < cum) return opt;
    }
    return activeOpts.last;
  }

  static SpinWheel? _findWheel(List<SpinWheel> wheels, String id) {
    try {
      return wheels.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }
}