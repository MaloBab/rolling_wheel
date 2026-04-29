// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_constants.dart';
import '../../../data/models/models.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../session/session_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            Expanded(child: _buildBody(context)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateGroupDialog(context),
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text('Nouveau groupe', style: GoogleFonts.syne(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientText(
                'SpinGroups',
                style: GoogleFonts.syne(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                'Roues aléatoires pour personnages',
                style: GoogleFonts.dmSans(fontSize: 13, color: kText3),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.file_upload_outlined, color: kText2),
            tooltip: 'Importer un groupe',
            onPressed: () => _importGroup(context),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, _) {
        if (!provider.isLoaded) {
          return const Center(child: CircularProgressIndicator(color: kAccent));
        }
        if (provider.groups.isEmpty) {
          return _buildEmptyState(context);
        }
        return _buildGroupList(context, provider);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎡', style: TextStyle(fontSize: 64))
                .animate()
                .fade(duration: 600.ms)
                .scale(delay: 200.ms),
            const Gap(20),
            Text(
              'Aucun groupe',
              style: GoogleFonts.syne(fontSize: 22, fontWeight: FontWeight.w700, color: kText),
            ),
            const Gap(8),
            Text(
              'Crée un groupe de roues pour commencer\nà générer tes personnages !',
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSans(fontSize: 14, color: kText3),
            ),
            const Gap(28),
            SgButton(
              label: 'Créer un groupe',
              icon: Icons.add,
              onPressed: () => _showCreateGroupDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupList(BuildContext context, GroupsProvider provider) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      itemCount: provider.groups.length,
      onReorder: provider.reorderGroups,
      itemBuilder: (context, index) {
        final group = provider.groups[index];
        return _GroupCard(
          key: ValueKey(group.id),
          group: group,
          index: index,
        );
      },
    );
  }

  void _showCreateGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _CreateGroupDialog(),
    );
  }

  Future<void> _importGroup(BuildContext context) async {
    final result = await importGroupFromFile();
    if (!context.mounted) return;
    if (result.success) {
      context.read<GroupsProvider>().importGroup(result.group!);
      showSgSnackbar(context, '✓ Groupe "${result.group!.name}" importé');
    } else {
      showSgSnackbar(context, result.error ?? 'Erreur d\'import', error: true);
    }
  }
}

// ──────────────────────────────────────────────
// Group card
// ──────────────────────────────────────────────

class _GroupCard extends StatelessWidget {
  final WheelGroup group;
  final int index;

  const _GroupCard({super.key, required this.group, required this.index});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SgCard(
        borderColor: group.color.withAlpha(76),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => GroupEditorScreen(groupId: group.id)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: group.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: group.color.withAlpha(128), blurRadius: 6)],
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Text(
                    group.name,
                    style: GoogleFonts.syne(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                  ),
                ),
                _GroupActions(group: group),
              ],
            ),
            if (group.description != null && group.description!.isNotEmpty) ...[
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(left: 22),
                child: Text(group.description!, style: GoogleFonts.dmSans(fontSize: 12, color: kText3)),
              ),
            ],
            const Gap(12),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  SgChip('${group.wheels.length} roue${group.wheels.length > 1 ? 's' : ''}', color: group.color),
                  ...group.wheels.take(3).map((w) => SgChip(w.name, color: kText3)),
                  if (group.wheels.length > 3)
                    SgChip('+${group.wheels.length - 3}', color: kText3),
                ],
              ),
            ),
            const Gap(14),
            Padding(
              padding: const EdgeInsets.only(left: 22),
              child: Row(
                children: [
                  SgButton(
                    label: 'Éditer',
                    variant: SgButtonVariant.secondary,
                    small: true,
                    icon: Icons.edit_outlined,
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => GroupEditorScreen(groupId: group.id)),
                    ),
                  ),
                  const Gap(8),
                  if (group.wheels.isNotEmpty)
                    SgButton(
                      label: 'Lancer',
                      small: true,
                      icon: Icons.play_arrow_rounded,
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => SessionScreen(groupId: group.id)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fade(duration: 300.ms, delay: (index * 60).ms)
        .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (index * 60).ms);
  }
}

class _GroupActions extends StatelessWidget {
  final WheelGroup group;

  const _GroupActions({required this.group});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      color: kSurface2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: kBorder),
      ),
      onSelected: (v) async {
        switch (v) {
          case 'export':
            await _exportGroup(context);
          case 'delete':
            _deleteGroup(context);
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'export',
          child: Row(children: [
            const Icon(Icons.file_download_outlined, size: 16, color: kText2),
            const Gap(8),
            Text('Exporter', style: GoogleFonts.dmSans(color: kText2)),
          ]),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Row(children: [
            Icon(Icons.delete_outline, size: 16, color: kAccent4),
            const Gap(8),
            Text('Supprimer', style: GoogleFonts.dmSans(color: kAccent4)),
          ]),
        ),
      ],
      icon: const Icon(Icons.more_vert, color: kText3, size: 20),
    );
  }

  Future<void> _exportGroup(BuildContext context) async {
    try {
      await shareGroup(group);
    } catch (e) {
      if (!context.mounted) return;
      // Fallback: afficher JSON dans dialog
      final json = exportGroupAsString(group);
      showDialog(
        context: context,
        builder: (_) => _JsonExportDialog(groupName: group.name, json: json),
      );
    }
  }

  void _deleteGroup(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        title: Text('Supprimer "${group.name}" ?',
            style: GoogleFonts.syne(color: kText, fontWeight: FontWeight.w700)),
        content: Text('Cette action est irréversible.',
            style: GoogleFonts.dmSans(color: kText2)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.dmSans(color: kText2)),
          ),
          TextButton(
            onPressed: () {
              context.read<GroupsProvider>().deleteGroup(group.id);
              Navigator.pop(context);
            },
            child: Text('Supprimer', style: GoogleFonts.dmSans(color: kAccent4)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialogs
// ──────────────────────────────────────────────

class _CreateGroupDialog extends StatefulWidget {
  const _CreateGroupDialog();

  @override
  State<_CreateGroupDialog> createState() => _CreateGroupDialogState();
}

class _CreateGroupDialogState extends State<_CreateGroupDialog> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  Color _selectedColor = kGroupColors[0];
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    context.read<GroupsProvider>().addGroup(
          name: _nameCtrl.text.trim(),
          color: _selectedColor,
          description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
        );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouveau groupe',
                  style: GoogleFonts.syne(fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
              const Gap(20),
              SgTextField(
                label: 'Nom du groupe',
                hint: 'Ex: Création de personnage RPG',
                controller: _nameCtrl,
                autofocus: true,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
              ),
              const Gap(12),
              SgTextField(
                label: 'Description (optionnel)',
                hint: 'Ex: Génération aléatoire pour D&D',
                controller: _descCtrl,
              ),
              const Gap(16),
              const SgSectionHeader('Couleur'),
              ColorPickerGrid(
                colors: kGroupColors,
                selectedColor: _selectedColor,
                onSelected: (c) => setState(() => _selectedColor = c),
              ),
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SgButton(
                    label: 'Annuler',
                    variant: SgButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(10),
                  SgButton(label: 'Créer', onPressed: _submit),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JsonExportDialog extends StatelessWidget {
  final String groupName;
  final String json;

  const _JsonExportDialog({required this.groupName, required this.json});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Export — $groupName',
                style: GoogleFonts.syne(fontSize: 16, fontWeight: FontWeight.w700, color: kText)),
            const Gap(12),
            Text('Copiez ce JSON pour l\'importer sur un autre appareil.',
                style: GoogleFonts.dmSans(fontSize: 12, color: kText3)),
            const Gap(12),
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: kSurface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: kBorder),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(12),
                child: SelectableText(
                  json,
                  style: GoogleFonts.robotoMono(fontSize: 11, color: kText2),
                ),
              ),
            ),
            const Gap(16),
            SgButton(
              label: 'Fermer',
              variant: SgButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}