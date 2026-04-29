// lib/presentation/screens/session/session_screen.dart
//
// Widget purement déclaratif. Tout l'état et la logique de session
// sont dans [SessionProvider], instancié en scope local ici.

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/models.dart';
import '../../../domain/session/session_step.dart';
import '../../providers/groups_provider.dart';
import '../../providers/session_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../widgets/wheel_painter.dart';
import '../../extensions/model_extensions.dart';

// ──────────────────────────────────────────────
// Point d'entrée : instancie le SessionProvider en scope local
// ──────────────────────────────────────────────

class SessionScreen extends StatelessWidget {
  final String groupId;

  const SessionScreen({super.key, required this.groupId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => SessionProvider(
        groupsProvider: ctx.read<GroupsProvider>(),
        groupId: groupId,
      ),
      child: _SessionView(groupId: groupId),
    );
  }
}

// ──────────────────────────────────────────────
// Vue principale
// ──────────────────────────────────────────────

class _SessionView extends StatefulWidget {
  final String groupId;

  const _SessionView({required this.groupId});

  @override
  State<_SessionView> createState() => _SessionViewState();
}

class _SessionViewState extends State<_SessionView> {
  final _wheelKey = GlobalKey<SpinWheelWidgetState>(debugLabel: 'spinWheel');

  @override
  void initState() {
    super.initState();
    // Initialisation après le premier frame pour que le provider soit prêt.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SessionProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionProvider>(
      builder: (context, session, _) {
        final groupsProvider = context.read<GroupsProvider>();
        final group = groupsProvider.groups
            .firstWhere((g) => g.id == widget.groupId);

        if (!session.initialized) {
          return Scaffold(
            backgroundColor: kBg,
            body: const Center(
                child: CircularProgressIndicator(color: kAccent)),
          );
        }
        if (group.wheels.isEmpty) return _buildEmpty(context);
        if (session.finished) return _buildSummary(context, session, group);
        return _buildSession(context, session, group);
      },
    );
  }

  // ── Écrans ────────────────────────────────────────────────────────────────

  Widget _buildEmpty(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar('Session'),
      body: const Center(child: Text('Aucune roue dans ce groupe.')),
    );
  }

  Widget _buildSession(
    BuildContext context,
    SessionProvider session,
    WheelGroup group,
  ) {
    final step = session.currentStep;
    if (step == null) return _buildSummary(context, session, group);

    // Auto-avance sur les steps skippés.
    if (step.skipped) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => session.advanceStep(),
      );
      return Scaffold(
        backgroundColor: kBg,
        appBar: _buildAppBar(group.name),
        body: const Center(child: CircularProgressIndicator(color: kAccent)),
      );
    }

    final totalSteps = session.steps.length;
    final currentIndex = session.currentStepIndex;

    return Scaffold(
      backgroundColor: kBg,
      appBar: _buildAppBar(group.name),
      body: SafeArea(
        child: Column(
          children: [
            _buildProgressBar(currentIndex, totalSteps),
            _buildWheelInfo(step, currentIndex, totalSteps),
            Expanded(
              child: Center(
                child: SpinWheelWidget(
                  key: _wheelKey,
                  wheel: step.wheel,
                  allWheels: group.wheels,
                  size: _wheelSize(context),
                  onSpinEnd: session.onSpinEnd,
                ),
              ),
            ),
            _buildResultBanner(step),
            _buildSkippedWheels(session),
            _buildActions(context, session, step),
            const Gap(24),
          ],
        ),
      ),
    );
  }

  // ── Widgets de session ────────────────────────────────────────────────────

  Widget _buildWheelInfo(SessionStep step, int stepIndex, int totalSteps) {
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
                    if (step.isRepeated) ...[
                      const Gap(8),
                      _RepeatBadge(
                          current: step.spinNumber, total: step.totalSpins),
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

  Widget _buildSkippedWheels(SessionProvider session) {
    final skipped =
        session.steps.where((s) => s.skipped && s.result == null).toList();
    if (skipped.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      child: Column(
        children:
            skipped.map((s) => _SkippedWheelTile(wheel: s.wheel)).toList(),
      ),
    );
  }

  Widget _buildResultBanner(SessionStep step) {
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
              Text('Résultat',
                  style: GoogleFonts.dmSans(fontSize: 11, color: kText3)),
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
        .slideY(
            begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildActions(
    BuildContext context,
    SessionProvider session,
    SessionStep step,
  ) {
    final hasResult = step.result != null;
    final isLastStep =
        session.currentStepIndex >= session.steps.length - 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          if (!hasResult)
            SgButton(
              label: 'Tourner la roue !',
              icon: Icons.autorenew,
              fullWidth: true,
              onPressed: () => _wheelKey.currentState?.spin(),
            )
          else if (!isLastStep)
            SgButton(
              label: 'Étape suivante →',
              icon: Icons.arrow_forward,
              fullWidth: true,
              onPressed: session.advanceStep,
            )
          else
            SgButton(
              label: 'Voir le récapitulatif',
              icon: Icons.summarize_outlined,
              fullWidth: true,
              onPressed: session.advanceStep,
            ),
          if (hasResult) ...[
            const Gap(10),
            SgButton(
              label: 'Retourner',
              variant: SgButtonVariant.secondary,
              icon: Icons.refresh,
              fullWidth: true,
              onPressed: session.retryCurrentStep,
            ),
          ],
        ],
      ),
    );
  }

  // ── Récapitulatif ─────────────────────────────────────────────────────────

  Widget _buildSummary(
    BuildContext context,
    SessionProvider session,
    WheelGroup group,
  ) {
    final resultsByWheel = <String, List<String>>{};
    for (final step in session.steps) {
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
            style: GoogleFonts.syne(
                fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
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
                      style: GoogleFonts.syne(
                          fontSize: 22, fontWeight: FontWeight.w800),
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
                final skipped = session.steps
                    .any((s) => s.wheel.id == wheel.id && s.skipped);
                return _SummaryCard(
                  wheel: wheel,
                  index: i,
                  results: results,
                  skipped: skipped,
                )
                    .animate()
                    .fade(duration: 300.ms, delay: (i * 80).ms)
                    .slideY(
                        begin: 0.2,
                        end: 0,
                        duration: 300.ms,
                        delay: (i * 80).ms);
              }),
              const Gap(32),
              SgButton(
                label: 'Nouvelle session',
                icon: Icons.refresh,
                fullWidth: true,
                onPressed: session.restart,
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

  // ── Helpers ───────────────────────────────────────────────────────────────

  double _wheelSize(BuildContext context) {
    final size = MediaQuery.of(context).size;
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
          style: GoogleFonts.syne(
              fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
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
        border: Border.all(color: kText3.withAlpha(51)),
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
          Text('Ignorée',
              style: GoogleFonts.dmSans(fontSize: 10, color: kText3)),
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

    final winnerOpt = hasResult
        ? wheel.options.firstWhere(
            (o) => o.name == results.first,
            orElse: () => WheelOption(id: '', name: '', colorValue: kAccent.toARGB32()),
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
                        style:
                            GoogleFonts.dmSans(fontSize: 12, color: kText3)),
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
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kText3))
                else if (!hasResult)
                  Text('(non joué)',
                      style: GoogleFonts.syne(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText3))
                else if (isMulti)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: results.asMap().entries.map((e) {
                      final optColor = wheel.options
                          .firstWhere((o) => o.name == e.value,
                              orElse: () => WheelOption(id: '', name: '', colorValue: color.toARGB32())).color;
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
                boxShadow: [
                  BoxShadow(color: color.withAlpha(128), blurRadius: 6)
                ],
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