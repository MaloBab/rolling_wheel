// lib/screens/session_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/groups_provider.dart';
import '../utils/app_theme.dart';
import '../widgets/common_widgets.dart';
import '../widgets/wheel_painter.dart';

// ──────────────────────────────────────────────
// Modèle interne : un "step" de session
// Peut représenter un tour normal ou un tour répété.
// ──────────────────────────────────────────────

class _SessionStep {
  final SpinWheel wheel;
  final int spinNumber;   // 1-based, pour les roues répétées (ex: "Tour 2/3")
  final int totalSpins;   // nombre total de tours pour cette roue
  String? result;
  bool skipped;

  _SessionStep({
    required this.wheel,
    this.spinNumber = 1,
    this.totalSpins = 1,
    this.skipped = false,
  });

  bool get isRepeatedWheel => totalSpins > 1;
}

// ──────────────────────────────────────────────
// SessionScreen
// ──────────────────────────────────────────────

class SessionScreen extends StatefulWidget {
  final String groupId;

  const SessionScreen({super.key, required this.groupId});

  @override
  State<SessionScreen> createState() => _SessionScreenState();
}

class _SessionScreenState extends State<SessionScreen> {
  int _currentStepIndex = 0;
  bool _finished = false;
  bool _stepsBuilt = false;
  List<_SessionStep> _steps = [];
  final _wheelKey = GlobalKey<SpinWheelWidgetState>(debugLabel: 'spinWheel');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<GroupsProvider>();
      provider.resetGroupResults(widget.groupId);
      _buildSteps(provider);
    });
  }

  /// Construit la liste des steps initiaux (sans tenir compte des conditions
  /// ni des répétitions dynamiques – celles-ci sont réévaluées à chaque avance).
  void _buildSteps(GroupsProvider provider) {
    final group = provider.groups.firstWhere((g) => g.id == widget.groupId);
    final steps = <_SessionStep>[];
    for (final wheel in group.wheels) {
      steps.add(_SessionStep(wheel: wheel, spinNumber: 1, totalSpins: 1));
    }
    setState(() {
      _steps = steps;
      _stepsBuilt = true;
    });
  }

  /// Après chaque résultat, on réexpanse les steps pour les roues avec repeatCount > 1.
  /// On recalcule aussi les steps skipped.
  void _expandStepsAfterResult(GroupsProvider provider, WheelGroup group) {
    final allWheels = group.wheels;
    final rebuilt = <_SessionStep>[];

    for (final wheel in allWheels) {
      final effectiveCount = wheel.effectiveRepeatCount(allWheels);
      final isSkipped = wheel.isSkippedConditionally(allWheels);

      if (isSkipped) {
        rebuilt.add(_SessionStep(
          wheel: wheel,
          spinNumber: 1,
          totalSpins: 1,
          skipped: true,
        ));
      } else {
        for (int i = 0; i < effectiveCount; i++) {
          rebuilt.add(_SessionStep(
            wheel: wheel,
            spinNumber: i + 1,
            totalSpins: effectiveCount,
          ));
        }
      }
    }

    // Conserver les résultats déjà obtenus pour les steps précédents
    int oldIdx = 0;
    for (int i = 0; i < rebuilt.length && oldIdx < _steps.length; i++) {
      while (oldIdx < _steps.length &&
          _steps[oldIdx].wheel.id != rebuilt[i].wheel.id) {
        oldIdx++;
      }
      if (oldIdx < _steps.length) {
        rebuilt[i].result = _steps[oldIdx].result;
        rebuilt[i].skipped = _steps[oldIdx].skipped;
        oldIdx++;
      }
    }

    // Recalculer _currentStepIndex : premier step sans résultat et non skippé
    int newCurrent = _currentStepIndex;
    if (newCurrent >= rebuilt.length) newCurrent = rebuilt.length - 1;

    setState(() {
      _steps = rebuilt;
      _currentStepIndex = newCurrent;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.firstWhere((g) => g.id == widget.groupId);

        if (!_stepsBuilt) {
          return Scaffold(
            backgroundColor: kBg,
            body: const Center(child: CircularProgressIndicator(color: kAccent)),
          );
        }

        if (group.wheels.isEmpty) {
          return _buildEmpty(context);
        }
        if (_finished) {
          return _buildSummary(context, group);
        }
        return _buildSession(context, provider, group);
      },
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar('Session'),
      body: const Center(child: Text('Aucune roue dans ce groupe.')),
    );
  }

  Widget _buildSession(BuildContext context, GroupsProvider provider, WheelGroup group) {
    if (_currentStepIndex >= _steps.length) {
      return _buildSummary(context, group);
    }

    final step = _steps[_currentStepIndex];
    final totalSteps = _steps.length;

    // Si le step courant est skippé, on avance automatiquement
    if (step.skipped) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _advanceStep(provider, group));
      return Scaffold(
        backgroundColor: kBg,
        appBar: _buildAppBar(group.name),
        body: const Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(group.name),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(_currentStepIndex, totalSteps),
            _buildWheelInfo(step, _currentStepIndex, totalSteps, group.wheels),
            Expanded(
              child: Center(
                child: SpinWheelWidget(
                  key: _wheelKey,
                  wheel: step.wheel,
                  allWheels: group.wheels,
                  size: _wheelSize(context),
                  onResult: (winner) => _onResult(context, provider, group, step, winner),
                ),
              ),
            ),
            _buildResultBanner(step),
            _buildSkippedWheels(group),
            _buildActions(context, provider, group, step),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  double _wheelSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Utilise 92% de la largeur, plafonné à 420px pour les grandes tablettes
    return (size.width * 0.92).clamp(240.0, 420.0);
  }

  AppBar _buildAppBar(String title) {
    return AppBar(
      backgroundColor: kSurface,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.close, color: kText2, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(title,
          style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: kBorder),
      ),
    );
  }

  Widget _buildProgressBar(int current, int total) {
    final progress = total == 0 ? 0.0 : current / total;
    return Container(
      height: 3,
      color: kSurface2,
      child: FractionallySizedBox(
        widthFactor: progress,
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [kAccent, kAccent3]),
          ),
        ),
      ),
    );
  }

  Widget _buildWheelInfo(
    _SessionStep step,
    int stepIndex,
    int totalSteps,
    List<SpinWheel> allWheels,
  ) {
    final wheel = step.wheel;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      wheel.name,
                      style: GoogleFonts.syne(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                    // Badge répétition
                    if (step.isRepeatedWheel) ...[
                      const Gap(8),
                      _RepeatBadge(current: step.spinNumber, total: step.totalSpins),
                    ],
                  ],
                ),
                Text(
                  'Étape ${stepIndex + 1} sur $totalSteps',
                  style: GoogleFonts.dmSans(fontSize: 12, color: kText3),
                ),
              ],
            ),
          ),
          if (wheel.dependencies.isNotEmpty)
            SgChip('${wheel.dependencies.length} dép.', color: kAccent2),
        ],
      ),
    );
  }

  /// Affiche un résumé compact des roues ignorées conditionnellement.
  Widget _buildSkippedWheels(WheelGroup group) {
    final skippedSteps = _steps
        .where((s) => s.skipped && s.result == null)
        .toList();
    if (skippedSteps.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        children: skippedSteps.map((s) => _SkippedWheelTile(wheel: s.wheel)).toList(),
      ),
    );
  }

  Widget _buildResultBanner(_SessionStep step) {
    final result = step.result;
    if (result == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [kAccent.withAlpha(38), kAccent3.withAlpha(25)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kAccent.withAlpha(76)),
      ),
      child: Row(
        children: [
          const Text('🎯', style: TextStyle(fontSize: 20)),
          const Gap(12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Résultat', style: GoogleFonts.dmSans(fontSize: 11, color: kText3)),
              Text(
                result,
                style: GoogleFonts.syne(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fade(duration: 400.ms)
        .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActions(
    BuildContext context,
    GroupsProvider provider,
    WheelGroup group,
    _SessionStep step,
  ) {
    final hasResult = step.result != null;
    final isLastStep = _currentStepIndex >= _steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!hasResult)
            SgButton(
              label: 'Tourner la roue !',
              icon: Icons.autorenew,
              fullWidth: true,
              onPressed: () => _getWheelKey(step)?.currentState?.spin(),
            )
          else if (!isLastStep)
            SgButton(
              label: 'Étape suivante →',
              icon: Icons.arrow_forward,
              fullWidth: true,
              onPressed: () => _advanceStep(provider, group),
            )
          else
            SgButton(
              label: 'Voir le récapitulatif',
              icon: Icons.summarize_outlined,
              fullWidth: true,
              onPressed: () => setState(() => _finished = true),
            ),
          if (hasResult) ...[
            const Gap(10),
            SgButton(
              label: 'Retourner',
              variant: SgButtonVariant.secondary,
              icon: Icons.refresh,
              fullWidth: true,
              onPressed: () {
                setState(() => step.result = null);
                provider.setWheelResult(group.id, step.wheel.id, null);
              },
            ),
          ],
        ],
      ),
    );
  }

  GlobalKey<SpinWheelWidgetState>? _getWheelKey(_SessionStep step) => _wheelKey;

  void _onResult(
    BuildContext context,
    GroupsProvider provider,
    WheelGroup group,
    _SessionStep step,
    WheelOption winner,
  ) {
    setState(() => step.result = winner.name);
    // On ne met le résultat dans le provider que pour le dernier spin de la roue
    // (pour que les dépendances soient correctes).
    if (step.spinNumber == step.totalSpins) {
      provider.setWheelResult(group.id, step.wheel.id, winner.name);
    }
    // Réévaluer les steps (conditions, répétitions dynamiques)
    _expandStepsAfterResult(provider, group);
  }

  void _advanceStep(GroupsProvider provider, WheelGroup group) {
    if (_currentStepIndex < _steps.length - 1) {
      setState(() => _currentStepIndex++);
      // Passer automatiquement les steps skippés
      _skipConditionalSteps(provider, group);
    } else {
      setState(() => _finished = true);
    }
  }

  void _skipConditionalSteps(GroupsProvider provider, WheelGroup group) {
    while (_currentStepIndex < _steps.length) {
      final step = _steps[_currentStepIndex];
      if (step.skipped) {
        if (_currentStepIndex < _steps.length - 1) {
          setState(() => _currentStepIndex++);
        } else {
          setState(() => _finished = true);
          return;
        }
      } else {
        break;
      }
    }
  }

  // ──────────────────────────────────────────────
  // Summary screen
  // ──────────────────────────────────────────────

  Widget _buildSummary(BuildContext context, WheelGroup group) {
    // Regrouper les résultats : si une roue a été tirée plusieurs fois, on liste tous les résultats
    final resultsByWheel = <String, List<String>>{};
    for (final step in _steps) {
      if (step.result != null) {
        resultsByWheel.putIfAbsent(step.wheel.id, () => []).add(step.result!);
      }
    }

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: kSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: kText2, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Récapitulatif',
            style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Column(
                  children: [
                    const Text('🎉', style: TextStyle(fontSize: 56))
                        .animate()
                        .fade(duration: 500.ms)
                        .scale(delay: 100.ms),
                    const Gap(12),
                    GradientText(
                      group.name,
                      style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                    const Gap(4),
                    Text(
                      'Génération terminée !',
                      style: GoogleFonts.dmSans(fontSize: 13, color: kText3),
                    ),
                  ],
                ),
              ),
              const Gap(32),
              const SgSectionHeader('Résultats'),
              ...group.wheels.asMap().entries.map((entry) {
                final i = entry.key;
                final wheel = entry.value;
                final results = resultsByWheel[wheel.id] ?? [];
                final skipped = _steps.any((s) => s.wheel.id == wheel.id && s.skipped);

                return _SummaryCard(
                  wheel: wheel,
                  index: i,
                  results: results,
                  skipped: skipped,
                ).animate().fade(duration: 300.ms, delay: (i * 80).ms).slideY(
                    begin: 0.2, end: 0, duration: 300.ms, delay: (i * 80).ms);
              }),
              const Gap(32),
              SgButton(
                label: 'Nouvelle session',
                icon: Icons.refresh,
                fullWidth: true,
                onPressed: () {
                  final provider = context.read<GroupsProvider>();
                  provider.resetGroupResults(widget.groupId);
                  setState(() {
                    _currentStepIndex = 0;
                    _finished = false;
                    _stepsBuilt = false;
                  });
                  _buildSteps(provider);
                },
              ),
              const Gap(12),
              SgButton(
                label: 'Retour',
                variant: SgButtonVariant.secondary,
                icon: Icons.arrow_back,
                fullWidth: true,
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widget : badge de répétition
// ──────────────────────────────────────────────

class _RepeatBadge extends StatelessWidget {
  final int current;
  final int total;

  const _RepeatBadge({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: kAccent2.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kAccent2.withAlpha(76)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.repeat, size: 11, color: kAccent2),
          const Gap(4),
          Text(
            '$current / $total',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kAccent2,
            ),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Widget : roue ignorée conditionnellement
// ──────────────────────────────────────────────

class _SkippedWheelTile extends StatelessWidget {
  final SpinWheel wheel;

  const _SkippedWheelTile({required this.wheel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: kSurface2.withAlpha(128),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: kText3.withAlpha(51),
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.do_not_disturb_alt_outlined, size: 14, color: kText3),
          const Gap(8),
          Expanded(
            child: Text(
              wheel.name,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: kText3,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
          Text(
            'Ignorée',
            style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Summary card
// ──────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final SpinWheel wheel;
  final int index;
  final List<String> results;
  final bool skipped;

  const _SummaryCard({
    required this.wheel,
    required this.index,
    required this.results,
    required this.skipped,
  });

  @override
  Widget build(BuildContext context) {
    final hasResult = results.isNotEmpty;
    final isMulti = results.length > 1;

    // Couleur de la première option gagnante (ou fallback)
    final winnerOpt = hasResult
        ? wheel.options.firstWhere(
            (o) => o.name == results.first,
            orElse: () => WheelOption(id: '', name: '', color: kAccent),
          )
        : null;
    final color = skipped ? kText3 : (winnerOpt?.color ?? kText3);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: skipped
              ? kText3.withAlpha(38)
              : hasResult
                  ? color.withAlpha(76)
                  : kBorder,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Index badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: skipped
                  ? kSurface2
                  : hasResult
                      ? color.withAlpha(38)
                      : kSurface2,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: skipped
                    ? kText3.withAlpha(38)
                    : hasResult
                        ? color.withAlpha(102)
                        : kBorder,
              ),
            ),
            child: Center(
              child: Text(
                '${index + 1}',
                style: GoogleFonts.syne(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: skipped ? kText3 : hasResult ? color : kText3,
                ),
              ),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(wheel.name,
                        style: GoogleFonts.dmSans(fontSize: 12, color: kText3)),
                    if (skipped) ...[
                      const Gap(6),
                      SgChip('Ignorée', color: kText3),
                    ],
                    if (isMulti) ...[
                      const Gap(6),
                      SgChip('×${results.length}', color: kAccent2),
                    ],
                  ],
                ),
                const Gap(4),
                if (skipped)
                  Text('(conditions non remplies)',
                      style: GoogleFonts.syne(
                          fontSize: 13, fontWeight: FontWeight.w600, color: kText3))
                else if (!hasResult)
                  Text('(non joué)',
                      style: GoogleFonts.syne(
                          fontSize: 14, fontWeight: FontWeight.w700, color: kText3))
                else if (isMulti)
                  // Afficher chaque résultat sous forme de chips
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: results.asMap().entries.map((e) {
                      final optColor = wheel.options
                          .firstWhere((o) => o.name == e.value,
                              orElse: () =>
                                  WheelOption(id: '', name: '', color: color))
                          .color;
                      return _ResultChip(label: e.value, color: optColor);
                    }).toList(),
                  )
                else
                  Text(
                    results.first,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
              ],
            ),
          ),
          if (hasResult && !skipped)
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: color.withAlpha(128), blurRadius: 6)],
              ),
            ),
        ],
      ),
    );
  }
}

class _ResultChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ResultChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(38),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Text(
        label,
        style: GoogleFonts.syne(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: kText,
        ),
      ),
    );
  }
}