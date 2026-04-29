// lib/domain/session/session_step.dart

import '../../data/models/spin_wheel.dart';

final class SessionStep {
  final SpinWheel wheel;

  /// Numéro du tour (1-based) pour les roues répétées (ex. "Tour 2/3").
  final int spinNumber;
  final int totalSpins;
  final String? result;
  final bool skipped;

  const SessionStep({
    required this.wheel,
    this.spinNumber = 1,
    this.totalSpins = 1,
    this.result,
    this.skipped = false,
  });

  bool get isRepeated => totalSpins > 1;
  bool get isDone => result != null || skipped;

  SessionStep copyWith({
    SpinWheel? wheel,
    int? spinNumber,
    int? totalSpins,
    String? result,
    bool clearResult = false,
    bool? skipped,
  }) =>
      SessionStep(
        wheel: wheel ?? this.wheel,
        spinNumber: spinNumber ?? this.spinNumber,
        totalSpins: totalSpins ?? this.totalSpins,
        result: clearResult ? null : result ?? this.result,
        skipped: skipped ?? this.skipped,
      );
}