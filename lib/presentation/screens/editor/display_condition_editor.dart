// lib/screens/display_condition_editor.dart
//
// Widget autonome pour éditer la condition d'affichage d'une roue.
// À importer dans group_editor_screen.dart et à afficher dans la section
// de configuration avancée d'une roue (aux côtés de repeatCount, removeAfterSpin, etc.)
//
// Usage :
//   DisplayConditionEditor(
//     wheel: wheel,
//     allWheels: group.wheels,
//     groupId: group.id,
//   )

import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/models.dart';
import '../../../core/utils/condition_parser.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../extensions/model_extensions.dart';

// ──────────────────────────────────────────────
// Widget principal
// ──────────────────────────────────────────────

class DisplayConditionEditor extends StatefulWidget {
  final SpinWheel wheel;
  final List<SpinWheel> allWheels;
  final String groupId;

  const DisplayConditionEditor({
    super.key,
    required this.wheel,
    required this.allWheels,
    required this.groupId,
  });

  @override
  State<DisplayConditionEditor> createState() => _DisplayConditionEditorState();
}

class _DisplayConditionEditorState extends State<DisplayConditionEditor> {
  late TextEditingController _ctrl;
  String? _validationError;
  bool _expanded = false;

  List<SpinWheel> get _otherWheels =>
      widget.allWheels.where((w) => w.id != widget.wheel.id).toList();

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.wheel.displayCondition ?? '');
    _validate(_ctrl.text);
  }

  @override
  void didUpdateWidget(DisplayConditionEditor old) {
    super.didUpdateWidget(old);
    if (old.wheel.displayCondition != widget.wheel.displayCondition) {
      _ctrl.text = widget.wheel.displayCondition ?? '';
      _validate(_ctrl.text);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _validate(String value) {
    setState(() {
      _validationError = ConditionParser.validate(value);
    });
  }

  void _save(String value) {
    _validate(value);
    if (_validationError != null) return;
    context.read<GroupsProvider>().updateWheelCondition(
          widget.groupId,
          widget.wheel.id,
          value.trim().isEmpty ? null : value.trim(),
        );
  }

  void _clear() {
    _ctrl.clear();
    setState(() => _validationError = null);
    context.read<GroupsProvider>().updateWheelCondition(
          widget.groupId,
          widget.wheel.id,
          null,
        );
  }

  // ── Insère un snippet à la position du curseur ──

  void _insert(String snippet) {
    final text = _ctrl.text;
    final sel = _ctrl.selection;
    final start = sel.start < 0 ? text.length : sel.start;
    final end = sel.end < 0 ? text.length : sel.end;
    final newText = text.replaceRange(start, end, snippet);
    _ctrl.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + snippet.length),
    );
    _validate(newText);
  }

  @override
  Widget build(BuildContext context) {
    final hasCondition = widget.wheel.displayCondition != null &&
        widget.wheel.displayCondition!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasCondition ? kAccent3.withAlpha(76) : kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête cliquable
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.filter_alt_outlined,
                    size: 16,
                    color: hasCondition ? kAccent3 : kText3,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Condition d\'affichage',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasCondition ? kAccent3 : kText2,
                          ),
                        ),
                        if (hasCondition && !_expanded)
                          Text(
                            widget.wheel.displayCondition!,
                            style: GoogleFonts.robotoMono(
                                fontSize: 10, color: kText3),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (!hasCondition && !_expanded)
                          Text(
                            'Toujours affichée',
                            style: GoogleFonts.dmSans(
                                fontSize: 11, color: kText3),
                          ),
                      ],
                    ),
                  ),
                  if (hasCondition)
                    SgChip('Actif', color: kAccent3),
                  const Gap(8),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    size: 18,
                    color: kText3,
                  ),
                ],
              ),
            ),
          ),

          // Corps éditeur (affiché si expanded)
          if (_expanded) ...[
            Container(height: 1, color: kBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Description
                  Text(
                    'Cette roue ne s\'affiche que si la condition est vraie. '
                    'Utilise les noms des autres roues comme variables.',
                    style: GoogleFonts.dmSans(fontSize: 11, color: kText3),
                  ),
                  const Gap(10),

                  // Aide-mémoire des noms de roues disponibles
                  if (_otherWheels.isNotEmpty) ...[
                    Text(
                      'Roues disponibles :',
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: kText2, fontWeight: FontWeight.w600),
                    ),
                    const Gap(6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _otherWheels.map((w) {
                        return _WheelRefChip(
                          wheel: w,
                          onTap: () => _insert('"${w.name}"'),
                          onInsertResult: (optName) =>
                              _insert('${w.name} == "$optName"'),
                        );
                      }).toList(),
                    ),
                    const Gap(10),
                  ],

                  // Boutons opérateurs
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _OpButton(label: '&&', onTap: () => _insert(' && ')),
                      _OpButton(label: '||', onTap: () => _insert(' || ')),
                      _OpButton(label: '!', onTap: () => _insert('!')),
                      _OpButton(label: '( )', onTap: () => _insert('()')),
                      _OpButton(label: '==', onTap: () => _insert(' == ')),
                      _OpButton(label: '!=', onTap: () => _insert(' != ')),
                    ],
                  ),
                  const Gap(10),

                  // Champ de saisie
                  TextFormField(
                    controller: _ctrl,
                    style: GoogleFonts.robotoMono(fontSize: 13, color: kText),
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                      hintText: 'Ex: Race == "Elfe" || Race == "Humain"',
                      hintStyle:
                          GoogleFonts.robotoMono(fontSize: 12, color: kText3),
                      errorText: _validationError,
                      errorStyle:
                          GoogleFonts.dmSans(fontSize: 10, color: kAccent4),
                      suffixIcon: _ctrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 16),
                              onPressed: _clear,
                              color: kText3,
                            )
                          : null,
                    ),
                    onChanged: (v) => _validate(v),
                    onEditingComplete: () => _save(_ctrl.text),
                  ),

                  // Prévisualisation en temps réel
                  if (_otherWheels.isNotEmpty &&
                      _ctrl.text.isNotEmpty &&
                      _validationError == null) ...[
                    const Gap(10),
                    _ConditionPreview(
                      expression: _ctrl.text,
                      allWheels: widget.allWheels,
                      currentWheelId: widget.wheel.id,
                    ),
                  ],

                  const Gap(12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_ctrl.text.isNotEmpty)
                        SgButton(
                          label: 'Effacer',
                          variant: SgButtonVariant.ghost,
                          small: true,
                          onPressed: _clear,
                        ),
                      const Gap(8),
                      SgButton(
                        label: 'Enregistrer',
                        small: true,
                        icon: Icons.check,
                        onPressed: _validationError == null
                            ? () => _save(_ctrl.text)
                            : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Chip d'une roue disponible (avec popup options)
// ──────────────────────────────────────────────

class _WheelRefChip extends StatelessWidget {
  final SpinWheel wheel;
  final VoidCallback onTap;
  final void Function(String optionName) onInsertResult;

  const _WheelRefChip({
    required this.wheel,
    required this.onTap,
    required this.onInsertResult,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: kSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: kBorder),
      ),
      tooltip: 'Insérer une comparaison',
      itemBuilder: (_) => [
        PopupMenuItem(
          value: '__name__',
          child: Text(
            'Insérer "${wheel.name}"',
            style: GoogleFonts.dmSans(fontSize: 12, color: kText2),
          ),
        ),
        if (wheel.options.isNotEmpty)
          PopupMenuItem(
            enabled: false,
            height: 24,
            child: Text(
              'Options disponibles :',
              style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
            ),
          ),
        ...wheel.options.map((o) => PopupMenuItem(
              value: o.name,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: o.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    '${wheel.name} == "${o.name}"',
                    style: GoogleFonts.robotoMono(fontSize: 11, color: kText),
                  ),
                ],
              ),
            )),
      ],
      onSelected: (v) {
        if (v == '__name__') {
          onTap();
        } else {
          onInsertResult(v);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kAccent.withAlpha(25),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: kAccent.withAlpha(76)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.circle, size: 7, color: kAccent),
            const Gap(5),
            Text(
              wheel.name,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: kAccent,
              ),
            ),
            const Gap(4),
            const Icon(Icons.arrow_drop_down, size: 14, color: kAccent),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Bouton opérateur
// ──────────────────────────────────────────────

class _OpButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _OpButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: kSurface3,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: kBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.robotoMono(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: kAccent2,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Prévisualisation : teste l'expression avec les
// résultats actuels des roues (si disponibles)
// ──────────────────────────────────────────────

class _ConditionPreview extends StatelessWidget {
  final String expression;
  final List<SpinWheel> allWheels;
  final String currentWheelId;

  const _ConditionPreview({
    required this.expression,
    required this.allWheels,
    required this.currentWheelId,
  });

  @override
  Widget build(BuildContext context) {
    final wheels = allWheels
        .where((w) => w.id != currentWheelId)
        .map((w) => (name: w.name, result: w.result))
        .toList();

    final hasResults = wheels.any((w) => w.result != null);

    // S'il n'y a pas de résultats de session, afficher juste la structure parsée
    if (!hasResults) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: kSurface3,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: kBorder),
        ),
        child: Row(
          children: [
            const Icon(Icons.info_outline, size: 14, color: kText3),
            const Gap(8),
            Expanded(
              child: Text(
                'Syntaxe valide. La condition sera évaluée pendant la session.',
                style: GoogleFonts.dmSans(fontSize: 11, color: kText3),
              ),
            ),
          ],
        ),
      );
    }

    // Avec résultats : évaluer et afficher le résultat
    final result = ConditionParser.evaluate(expression, wheels);
    final color = result ? kAccent3 : kAccent4;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(76)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                result ? Icons.check_circle_outline : Icons.cancel_outlined,
                size: 14,
                color: color,
              ),
              const Gap(8),
              Text(
                result ? 'Roue affichée' : 'Roue masquée',
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: color),
              ),
              const Gap(6),
              Text(
                '(avec les résultats actuels)',
                style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
              ),
            ],
          ),
          const Gap(4),
          // Afficher les valeurs utilisées
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: wheels
                .where((w) => w.result != null)
                .map((w) => _MiniResultChip(name: w.name, result: w.result!))
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _MiniResultChip extends StatelessWidget {
  final String name;
  final String result;

  const _MiniResultChip({required this.name, required this.result});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: kSurface3,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: kBorder),
      ),
      child: Text(
        '$name = "$result"',
        style: GoogleFonts.robotoMono(fontSize: 10, color: kText2),
      ),
    );
  }
}