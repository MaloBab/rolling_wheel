// lib/presentation/providers/session_provider.dart

import 'package:flutter/foundation.dart';
import '../../data/models/models.dart';
import '../../domain/session/session_engine.dart';
import '../../domain/session/session_step.dart';
import 'groups_provider.dart';

class SessionProvider extends ChangeNotifier {
  final GroupsProvider _groupsProvider;
  final String groupId;

  SessionProvider({
    required GroupsProvider groupsProvider,
    required this.groupId,
  }) : _groupsProvider = groupsProvider;


  List<SessionStep> _steps = [];
  int _currentStepIndex = 0;
  bool _finished = false;
  bool _initialized = false;

  List<SessionStep> get steps => List.unmodifiable(_steps);
  int get currentStepIndex => _currentStepIndex;
  bool get finished => _finished;
  bool get initialized => _initialized;

  SessionStep? get currentStep =>
      _initialized && _currentStepIndex < _steps.length
          ? _steps[_currentStepIndex]
          : null;

  void initialize() {
    _groupsProvider.resetGroupResults(groupId);
    final group = _currentGroup;
    _steps = SessionEngine.buildInitialSteps(group.wheels);
    _currentStepIndex = 0;
    _finished = false;
    _initialized = true;
    notifyListeners();
  }

  void restart() {
    _initialized = false;
    notifyListeners();
    initialize();
  }

  void onSpinEnd(double finalAngle) {
    final step = currentStep;
    if (step == null) return;

    final group = _currentGroup;
    final weights = SessionEngine.effectiveWeights(step.wheel, group.wheels);
    final winner = SessionEngine.resolveWinner(step.wheel, weights, finalAngle);
    if (winner == null) return;

    _steps = [
      for (int i = 0; i < _steps.length; i++)
        i == _currentStepIndex
            ? _steps[i].copyWith(result: winner.name)
            : _steps[i],
    ];

    if (step.spinNumber == step.totalSpins) {
      _groupsProvider.setWheelResult(groupId, step.wheel.id, winner.name);
    }

    _rebuildSteps();
    notifyListeners();
  }

  void retryCurrentStep() {
    final step = currentStep;
    if (step == null) return;

    _steps = [
      for (int i = 0; i < _steps.length; i++)
        i == _currentStepIndex
            ? _steps[i].copyWith(clearResult: true)
            : _steps[i],
    ];
    _groupsProvider.setWheelResult(groupId, step.wheel.id, null);
    _rebuildSteps();
    notifyListeners();
  }

  void advanceStep() {
    if (_currentStepIndex < _steps.length - 1) {
      _currentStepIndex++;
      _skipConditionalSteps();
    } else {
      _finished = true;
    }
    notifyListeners();
  }

  void _rebuildSteps() {
    final group = _currentGroup;
    final rebuilt = SessionEngine.rebuildSteps(group.wheels, _steps);
    _currentStepIndex = _currentStepIndex.clamp(0, rebuilt.length - 1);
    _steps = rebuilt;
  }

  void _skipConditionalSteps() {
    while (_currentStepIndex < _steps.length) {
      if (_steps[_currentStepIndex].skipped) {
        if (_currentStepIndex < _steps.length - 1) {
          _currentStepIndex++;
        } else {
          _finished = true;
          return;
        }
      } else {
        break;
      }
    }
  }

  WheelGroup get _currentGroup =>
      _groupsProvider.groups.firstWhere((g) => g.id == groupId);
}