// lib/screens/group_editor_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../data/models/models.dart';
import '../../providers/groups_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/widgets.dart';
import '../../widgets/wheel_painter.dart';

class GroupEditorScreen extends StatefulWidget {
  final String groupId;

  const GroupEditorScreen({super.key, required this.groupId});

  @override
  State<GroupEditorScreen> createState() => _GroupEditorScreenState();
}

class _GroupEditorScreenState extends State<GroupEditorScreen> {
  int _selectedWheelIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Consumer<GroupsProvider>(
      builder: (context, provider, _) {
        final group = provider.groups.firstWhere((g) => g.id == widget.groupId);

        return Scaffold(
          backgroundColor: kBg,
          appBar: AppBar(
            backgroundColor: kSurface,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: kText2, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: group.color,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: group.color.withAlpha(153), blurRadius: 6)],
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Text(
                    group.name,
                    style: GoogleFonts.syne(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: kText,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: kText2, size: 20),
                tooltip: 'Modifier le groupe',
                onPressed: () => _showEditGroupDialog(context, group),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: kBorder),
            ),
          ),
          body: group.wheels.isEmpty
              ? _buildEmptyWheels(context, group)
              : _buildBody(context, provider, group),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showAddWheelDialog(context, group),
            backgroundColor: kAccent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: Text('Nouvelle roue', style: GoogleFonts.syne(fontWeight: FontWeight.w600)),
          ),
        );
      },
    );
  }

  Widget _buildEmptyWheels(BuildContext context, WheelGroup group) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('🎡', style: TextStyle(fontSize: 56))
              .animate()
              .fade(duration: 500.ms)
              .scale(delay: 100.ms),
          const Gap(16),
          Text('Aucune roue',
              style: GoogleFonts.syne(fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
          const Gap(8),
          Text(
            'Ajoute des roues à ce groupe\npour commencer à configurer.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 13, color: kText3),
          ),
          const Gap(24),
          SgButton(
            label: 'Ajouter une roue',
            icon: Icons.add,
            onPressed: () => _showAddWheelDialog(context, group),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, GroupsProvider provider, WheelGroup group) {
    if (_selectedWheelIndex >= group.wheels.length) {
      _selectedWheelIndex = group.wheels.length - 1;
    }
    final selectedWheel = group.wheels[_selectedWheelIndex];

    return Row(
      children: [
        _WheelSidebar(
          group: group,
          selectedIndex: _selectedWheelIndex,
          onSelected: (i) => setState(() => _selectedWheelIndex = i),
          onReorder: (oldIdx, newIdx) {
            provider.reorderWheels(group.id, oldIdx, newIdx);
            setState(() {
              if (_selectedWheelIndex == oldIdx) {
                _selectedWheelIndex = newIdx > oldIdx ? newIdx - 1 : newIdx;
              }
            });
          },
        ),
        Expanded(
          child: _WheelEditor(
            key: ValueKey(selectedWheel.id),
            group: group,
            wheel: selectedWheel,
            allWheels: group.wheels,
          ),
        ),
      ],
    );
  }

  void _showEditGroupDialog(BuildContext context, WheelGroup group) {
    showDialog(context: context, builder: (_) => _EditGroupDialog(group: group));
  }

  void _showAddWheelDialog(BuildContext context, WheelGroup group) {
    showDialog(context: context, builder: (_) => _AddWheelDialog(groupId: group.id));
  }
}

// ──────────────────────────────────────────────
// Sidebar: liste des roues
// ──────────────────────────────────────────────

class _WheelSidebar extends StatelessWidget {
  final WheelGroup group;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final Function(int, int) onReorder;

  const _WheelSidebar({
    required this.group,
    required this.selectedIndex,
    required this.onSelected,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 130,
      decoration: const BoxDecoration(
        color: kSurface,
        border: Border(right: BorderSide(color: kBorder)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 8),
            child: Text(
              'ORDRE',
              style: GoogleFonts.syne(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: kText3,
                letterSpacing: 1,
              ),
            ),
          ),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.only(bottom: 16),
              itemCount: group.wheels.length,
              onReorder: onReorder,
              proxyDecorator: (child, index, animation) =>
                  Material(color: Colors.transparent, child: child),
              itemBuilder: (ctx, i) {
                final w = group.wheels[i];
                final isSelected = i == selectedIndex;
                return _WheelTab(
                  key: ValueKey(w.id),
                  wheel: w,
                  index: i,
                  isSelected: isSelected,
                  onTap: () => onSelected(i),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _WheelTab extends StatelessWidget {
  final SpinWheel wheel;
  final int index;
  final bool isSelected;
  final VoidCallback onTap;

  const _WheelTab({
    super.key,
    required this.wheel,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withAlpha(30) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kAccent.withAlpha(102) : Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: kSurface2,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: kBorder),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: GoogleFonts.syne(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? kAccent : kText3,
                      ),
                    ),
                  ),
                ),
                const Gap(4),
                const Icon(Icons.drag_handle, size: 14, color: kText3),
                // Indicateur dégradé
                if (wheel.gradientBaseColor != null) ...[
                  const Gap(2),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Colors.black, wheel.gradientBaseColor!, Colors.white],
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
            const Gap(6),
            Text(
              wheel.name,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? kText : kText2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(4),
            Text(
              '${wheel.options.length} opt.',
              style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
            ),
            if (wheel.repeatCount > 1 || wheel.repeatSourceWheelId != null)
              Text(
                '×${wheel.repeatCount}',
                style: GoogleFonts.syne(fontSize: 10, color: kAccent2),
              ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Éditeur d'une roue (onglets)
// ──────────────────────────────────────────────

class _WheelEditor extends StatefulWidget {
  final WheelGroup group;
  final SpinWheel wheel;
  final List<SpinWheel> allWheels;

  const _WheelEditor({
    super.key,
    required this.group,
    required this.wheel,
    required this.allWheels,
  });

  @override
  State<_WheelEditor> createState() => _WheelEditorState();
}

class _WheelEditorState extends State<_WheelEditor>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();

    return Column(
      children: [
        _buildPreviewHeader(provider),
        Container(
          color: kSurface,
          child: TabBar(
            controller: _tabCtrl,
            labelColor: kAccent,
            unselectedLabelColor: kText3,
            indicatorColor: kAccent,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.syne(fontSize: 12, fontWeight: FontWeight.w700),
            unselectedLabelStyle: GoogleFonts.dmSans(fontSize: 12),
            tabs: const [
              Tab(text: 'Options'),
              Tab(text: 'Dépendances'),
              Tab(text: 'Paramètres'),
            ],
          ),
        ),
        Container(height: 1, color: kBorder),
        Expanded(
          child: TabBarView(
            controller: _tabCtrl,
            children: [
              _OptionsTab(group: widget.group, wheel: widget.wheel),
              _DependenciesTab(group: widget.group, wheel: widget.wheel),
              _SettingsTab(group: widget.group, wheel: widget.wheel),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewHeader(GroupsProvider provider) {
    return Container(
      color: kSurface,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: CustomPaint(
              painter: WheelPainter(
                wheel: widget.wheel,
                allWheels: widget.allWheels,
              ),
            ),
          ),
          const Gap(16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.wheel.name,
                  style: GoogleFonts.syne(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: kText,
                  ),
                ),
                const Gap(4),
                Text(
                  '${widget.wheel.options.length} option${widget.wheel.options.length > 1 ? 's' : ''}  •  '
                  '${widget.wheel.dependencies.length} dépendance${widget.wheel.dependencies.length > 1 ? 's' : ''}',
                  style: GoogleFonts.dmSans(fontSize: 12, color: kText3),
                ),
                const Gap(4),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (widget.wheel.removeAfterSpin)
                      const SgChip('Retrait auto', color: kAccent2),
                    if (widget.wheel.gradientBaseColor != null)
                      const SgChip('Dégradé', color: kAccent3),
                    if (widget.wheel.repeatCount > 1 || widget.wheel.repeatSourceWheelId != null)
                      SgChip('×${widget.wheel.repeatCount}', color: kAccent2),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            color: kSurface2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: kBorder),
            ),
            onSelected: (v) {
              if (v == 'delete') _confirmDelete(context, provider);
              if (v == 'rename') _showRenameDialog(context, provider);
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: Row(children: [
                  const Icon(Icons.edit_outlined, size: 16, color: kText2),
                  const Gap(8),
                  Text('Renommer', style: GoogleFonts.dmSans(color: kText2)),
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
            icon: const Icon(Icons.more_vert, color: kText3),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, GroupsProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer "${widget.wheel.name}" ?',
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
              provider.deleteWheel(widget.group.id, widget.wheel.id);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Supprimer', style: GoogleFonts.dmSans(color: kAccent4)),
          ),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, GroupsProvider provider) {
    final ctrl = TextEditingController(text: widget.wheel.name);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: kBorder2)),
        title: Text('Renommer',
            style: GoogleFonts.syne(color: kText, fontWeight: FontWeight.w700)),
        content: SgTextField(label: 'Nom', controller: ctrl, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.dmSans(color: kText2)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.updateWheel(widget.group.id, widget.wheel.id,
                    name: ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text('Sauvegarder', style: GoogleFonts.dmSans(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Onglet Options
// ──────────────────────────────────────────────

class _OptionsTab extends StatelessWidget {
  final WheelGroup group;
  final SpinWheel wheel;

  const _OptionsTab({required this.group, required this.wheel});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ...wheel.options.asMap().entries.map((entry) {
          final i = entry.key;
          final opt = entry.value;
          return _OptionTile(
            key: ValueKey(opt.id),
            option: opt,
            index: i,
            groupId: group.id,
            wheelId: wheel.id,
          ).animate().fade(duration: 200.ms, delay: (i * 40).ms);
        }),
        const Gap(12),
        SgButton(
          label: 'Ajouter une option',
          icon: Icons.add,
          variant: SgButtonVariant.secondary,
          fullWidth: true,
          onPressed: () => _showAddOptionDialog(context, provider),
        ),
        const Gap(80),
      ],
    );
  }

  void _showAddOptionDialog(BuildContext context, GroupsProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorder2),
        ),
        title: Text('Nouvelle option',
            style: GoogleFonts.syne(color: kText, fontWeight: FontWeight.w700)),
        content: SgTextField(
          label: 'Nom de l\'option',
          hint: 'Ex: Mage, Guerrier, Elfe…',
          controller: ctrl,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler', style: GoogleFonts.dmSans(color: kText2)),
          ),
          TextButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                provider.addOption(group.id, wheel.id, name: ctrl.text.trim());
              }
              Navigator.pop(context);
            },
            child: Text('Ajouter', style: GoogleFonts.dmSans(color: kAccent)),
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatefulWidget {
  final WheelOption option;
  final int index;
  final String groupId;
  final String wheelId;

  const _OptionTile({
    super.key,
    required this.option,
    required this.index,
    required this.groupId,
    required this.wheelId,
  });

  @override
  State<_OptionTile> createState() => _OptionTileState();
}

class _OptionTileState extends State<_OptionTile> {
  late TextEditingController _nameCtrl;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.option.name);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();
    final opt = widget.option;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _showColorPicker(context, provider),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: opt.color,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withAlpha(51), width: 1.5),
                    ),
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: _editing
                      ? TextField(
                          controller: _nameCtrl,
                          autofocus: true,
                          style: GoogleFonts.dmSans(fontSize: 13, color: kText),
                          decoration: const InputDecoration(
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 6),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) => _saveEdit(provider),
                        )
                      : GestureDetector(
                          onTap: () => setState(() => _editing = true),
                          child: Text(opt.name,
                              style: GoogleFonts.dmSans(fontSize: 13, color: kText)),
                        ),
                ),
                Container(
                  width: 40,
                  margin: const EdgeInsets.only(right: 6),
                  child: Text(
                    '×${opt.weight.toStringAsFixed(opt.weight == opt.weight.roundToDouble() ? 0 : 1)}',
                    style: GoogleFonts.syne(
                        fontSize: 11, color: kAccent, fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
                if (_editing)
                  IconButton(
                    icon: const Icon(Icons.check, color: kAccent, size: 18),
                    onPressed: () => _saveEdit(provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  )
                else
                  PopupMenuButton<String>(
                    color: kSurface2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: const BorderSide(color: kBorder),
                    ),
                    onSelected: (v) {
                      if (v == 'edit') setState(() => _editing = true);
                      if (v == 'delete') {
                        provider.deleteOption(widget.groupId, widget.wheelId, opt.id);
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'edit',
                        child: Text('Renommer',
                            style: GoogleFonts.dmSans(color: kText2, fontSize: 13)),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Supprimer',
                            style: GoogleFonts.dmSans(color: kAccent4, fontSize: 13)),
                      ),
                    ],
                    icon: const Icon(Icons.more_vert, color: kText3, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Row(
              children: [
                Text('Poids', style: GoogleFonts.dmSans(fontSize: 11, color: kText3)),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: opt.color,
                      thumbColor: opt.color,
                      inactiveTrackColor: kBorder,
                      trackHeight: 2,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                      overlayShape: SliderComponentShape.noOverlay,
                    ),
                    child: Slider(
                      value: opt.weight.clamp(0.1, 10.0),
                      min: 0.1,
                      max: 10.0,
                      divisions: 99,
                      onChanged: (v) {
                        provider.updateOption(
                          widget.groupId,
                          widget.wheelId,
                          opt.id,
                          weight: (v * 10).round() / 10,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _saveEdit(GroupsProvider provider) {
    if (_nameCtrl.text.trim().isNotEmpty) {
      provider.updateOption(
        widget.groupId,
        widget.wheelId,
        widget.option.id,
        name: _nameCtrl.text.trim(),
      );
    }
    setState(() => _editing = false);
  }

  void _showColorPicker(BuildContext context, GroupsProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: kSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: kBorder2),
        ),
        title: Text('Couleur',
            style: GoogleFonts.syne(color: kText, fontWeight: FontWeight.w700)),
        content: ColorPickerGrid(
          colors: kWheelColors,
          selectedColor: widget.option.color,
          onSelected: (c) {
            provider.updateOption(widget.groupId, widget.wheelId, widget.option.id,
                color: c);
            Navigator.pop(context);
          },
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Onglet Dépendances
// ──────────────────────────────────────────────

class _DependenciesTab extends StatelessWidget {
  final WheelGroup group;
  final SpinWheel wheel;

  const _DependenciesTab({required this.group, required this.wheel});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();
    final sourceWheels = group.wheels.where((w) => w.id != wheel.id).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Info box
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: kAccent.withAlpha(18),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kAccent.withAlpha(51)),
          ),
          child: Text(
            'Une dépendance permet qu\'une roue précédente influence les probabilités de celle-ci. '
            'Un poids de 0 exclut totalement une option. '
            'Si toutes les options tombent à 0, la roue est ignorée automatiquement en session.',
            style: GoogleFonts.dmSans(fontSize: 12, color: kText2, height: 1.5),
          ),
        ),
        const Gap(16),

        if (wheel.dependencies.isEmpty && sourceWheels.isEmpty)
          Text('Aucune autre roue dans ce groupe.',
              style: GoogleFonts.dmSans(fontSize: 13, color: kText3))
        else ...[
          ...wheel.dependencies.asMap().entries.map((entry) {
            final i = entry.key;
            final dep = entry.value;
            final src = group.wheels.firstWhere(
              (w) => w.id == dep.sourceWheelId,
              orElse: () => SpinWheel(id: '', name: '?', options: []),
            );
            return _DependencyCard(
              key: ValueKey('dep_$i'),
              dependency: dep,
              depIndex: i,
              sourceWheel: src,
              targetWheel: wheel,
              group: group,
            ).animate().fade(duration: 200.ms, delay: (i * 60).ms);
          }),

          if (sourceWheels.isNotEmpty) ...[
            const Gap(12),
            SgButton(
              label: 'Ajouter une dépendance',
              icon: Icons.add_link,
              variant: SgButtonVariant.secondary,
              fullWidth: true,
              onPressed: () => _showAddDepDialog(context, provider, sourceWheels),
            ),
          ],
        ],
        const Gap(80),
      ],
    );
  }

  void _showAddDepDialog(
    BuildContext context,
    GroupsProvider provider,
    List<SpinWheel> sourceWheels,
  ) {
    showDialog(
      context: context,
      builder: (_) => _AddDependencyDialog(
        group: group,
        targetWheel: wheel,
        sourceWheels: sourceWheels,
      ),
    );
  }
}

class _DependencyCard extends StatelessWidget {
  final Dependency dependency;
  final int depIndex;
  final SpinWheel sourceWheel;
  final SpinWheel targetWheel;
  final WheelGroup group;

  const _DependencyCard({
    super.key,
    required this.dependency,
    required this.depIndex,
    required this.sourceWheel,
    required this.targetWheel,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kSurface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 8),
            child: Row(
              children: [
                const Icon(Icons.account_tree_outlined, size: 14, color: kAccent),
                const Gap(8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.syne(
                          fontSize: 12, fontWeight: FontWeight.w700, color: kText),
                      children: [
                        TextSpan(
                            text: sourceWheel.name,
                            style: const TextStyle(color: kAccent2)),
                        const TextSpan(text: '  →  '),
                        TextSpan(
                            text: targetWheel.name,
                            style: const TextStyle(color: kAccent3)),
                      ],
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 16, color: kText3),
                  onPressed: () => _showEditDialog(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, size: 16, color: kAccent4),
                  onPressed: () =>
                      provider.removeDependency(group.id, targetWheel.id, depIndex),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
          // Résumé visuel : pour chaque option source, mini barres des poids cibles
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: sourceWheel.options.map((srcOpt) {
                final weightMap = dependency.weights[srcOpt.id] ?? {};
                final totalW = weightMap.values.fold(0.0, (s, v) => s + v);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                                color: srcOpt.color, shape: BoxShape.circle),
                          ),
                          const Gap(6),
                          Text(
                            srcOpt.name,
                            style: GoogleFonts.syne(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: kText2),
                          ),
                        ],
                      ),
                      const Gap(4),
                      // Mini barres de probabilité pour chaque option cible
                      ...targetWheel.options.map((tgtOpt) {
                        final w = weightMap[tgtOpt.id] ?? 1.0;
                        final pct = totalW > 0 ? (w / totalW) : 0.0;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 3, left: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                    color: tgtOpt.color, shape: BoxShape.circle),
                              ),
                              const Gap(6),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  tgtOpt.name,
                                  style: GoogleFonts.dmSans(
                                      fontSize: 10, color: kText3),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Expanded(
                                flex: 4,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(3),
                                  child: LinearProgressIndicator(
                                    value: pct.toDouble(),
                                    minHeight: 5,
                                    backgroundColor: kSurface3,
                                    valueColor: AlwaysStoppedAnimation(
                                      w == 0 ? kText3 : tgtOpt.color,
                                    ),
                                  ),
                                ),
                              ),
                              const Gap(6),
                              SizedBox(
                                width: 28,
                                child: Text(
                                  w == 0
                                      ? '—'
                                      : '${(pct * 100).round()}%',
                                  style: GoogleFonts.syne(
                                    fontSize: 9,
                                    color: w == 0 ? kText3 : kText2,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _EditDependencyDialog(
        group: group,
        targetWheel: targetWheel,
        sourceWheel: sourceWheel,
        dependency: dependency,
        depIndex: depIndex,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialog: ajouter dépendance
// ──────────────────────────────────────────────

class _AddDependencyDialog extends StatefulWidget {
  final WheelGroup group;
  final SpinWheel targetWheel;
  final List<SpinWheel> sourceWheels;

  const _AddDependencyDialog({
    required this.group,
    required this.targetWheel,
    required this.sourceWheels,
  });

  @override
  State<_AddDependencyDialog> createState() => _AddDependencyDialogState();
}

class _AddDependencyDialogState extends State<_AddDependencyDialog> {
  late SpinWheel _selectedSource;

  @override
  void initState() {
    super.initState();
    _selectedSource = widget.sourceWheels.first;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder2),
      ),
      title: Text('Nouvelle dépendance',
          style: GoogleFonts.syne(color: kText, fontWeight: FontWeight.w700)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Quelle roue influence "${widget.targetWheel.name}" ?',
              style: GoogleFonts.dmSans(fontSize: 13, color: kText2)),
          const Gap(12),
          ...widget.sourceWheels.map((w) {
            final isSelected = w.id == _selectedSource.id;
            return GestureDetector(
              onTap: () => setState(() => _selectedSource = w),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? kAccent.withAlpha(30) : kSurface2,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? kAccent.withAlpha(102) : kBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked
                          : Icons.radio_button_unchecked,
                      size: 16,
                      color: isSelected ? kAccent : kText3,
                    ),
                    const Gap(10),
                    Text(
                      w.name,
                      style: GoogleFonts.dmSans(
                        fontSize: 13,
                        color: isSelected ? kText : kText2,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${w.options.length} opt.',
                      style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Annuler', style: GoogleFonts.dmSans(color: kText2)),
        ),
        TextButton(
          onPressed: () {
            final weights = <String, Map<String, double>>{};
            for (final srcOpt in _selectedSource.options) {
              weights[srcOpt.id] = {
                for (final tgtOpt in widget.targetWheel.options) tgtOpt.id: 1.0,
              };
            }
            context.read<GroupsProvider>().addDependency(
              widget.group.id,
              widget.targetWheel.id,
              Dependency(sourceWheelId: _selectedSource.id, weights: weights),
            );
            Navigator.pop(context);
          },
          child: Text('Créer', style: GoogleFonts.dmSans(color: kAccent)),
        ),
      ],
    );
  }
}

// ──────────────────────────────────────────────
// Dialog: éditer matrice de dépendance (refonte UX)
// ──────────────────────────────────────────────

class _EditDependencyDialog extends StatefulWidget {
  final WheelGroup group;
  final SpinWheel targetWheel;
  final SpinWheel sourceWheel;
  final Dependency dependency;
  final int depIndex;

  const _EditDependencyDialog({
    required this.group,
    required this.targetWheel,
    required this.sourceWheel,
    required this.dependency,
    required this.depIndex,
  });

  @override
  State<_EditDependencyDialog> createState() => _EditDependencyDialogState();
}

class _EditDependencyDialogState extends State<_EditDependencyDialog>
    with SingleTickerProviderStateMixin {
  late Map<String, Map<String, double>> _weights;
  late TabController _tabCtrl;
  // ignore: unused_field
  int _activeSrcTab = 0;

  @override
  void initState() {
    super.initState();
    _weights = widget.dependency.weights.map(
      (k, v) => MapEntry(k, Map<String, double>.from(v)),
    );
    for (final srcOpt in widget.sourceWheel.options) {
      _weights.putIfAbsent(srcOpt.id, () => {
        for (final tgtOpt in widget.targetWheel.options) tgtOpt.id: 1.0,
      });
      for (final tgtOpt in widget.targetWheel.options) {
        _weights[srcOpt.id]!.putIfAbsent(tgtOpt.id, () => 1.0);
      }
    }
    _tabCtrl = TabController(
      length: widget.sourceWheel.options.length,
      vsync: this,
    );
    _tabCtrl.addListener(() => setState(() => _activeSrcTab = _tabCtrl.index));
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  /// Probabilités calculées pour le tab actif
  Map<String, double> _probabilities(String srcOptId) {
    final wMap = _weights[srcOptId] ?? {};
    final total = wMap.values.fold(0.0, (s, v) => s + v);
    if (total == 0) return {for (final k in wMap.keys) k: 0.0};
    return wMap.map((k, v) => MapEntry(k, v / total));
  }

  /// Applique un preset à toutes les options cibles pour une option source
  void _applyPreset(String srcOptId, String preset) {
    final tgtOpts = widget.targetWheel.options;
    setState(() {
      if (preset == 'equal') {
        for (final t in tgtOpts) {
          _weights[srcOptId]![t.id] = 1.0;
        }
      } else if (preset == 'first') {
        for (int i = 0; i < tgtOpts.length; i++) {
          _weights[srcOptId]![tgtOpts[i].id] = i == 0 ? 5.0 : 1.0;
        }
      } else if (preset == 'block') {
        // Bloquer toutes les options (cette roue sera ignorée)
        for (final t in tgtOpts) {
          _weights[srcOptId]![t.id] = 0.0;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final srcOpts = widget.sourceWheel.options;
    final tgtOpts = widget.targetWheel.options;

    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder2),
      ),
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
              child: Row(
                children: [
                  const Icon(Icons.account_tree_outlined, size: 16, color: kAccent),
                  const Gap(8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.syne(
                            fontSize: 15, fontWeight: FontWeight.w700, color: kText),
                        children: [
                          TextSpan(
                              text: widget.sourceWheel.name,
                              style: const TextStyle(color: kAccent2)),
                          const TextSpan(text: '  →  '),
                          TextSpan(
                              text: widget.targetWheel.name,
                              style: const TextStyle(color: kAccent3)),
                        ],
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: kText2, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
              child: Text(
                'Ajuste les poids pour chaque résultat possible de "${widget.sourceWheel.name}".',
                style: GoogleFonts.dmSans(fontSize: 12, color: kText3),
              ),
            ),

            // ── Tabs options source ──
            Container(
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: kBorder)),
              ),
              child: TabBar(
                controller: _tabCtrl,
                isScrollable: true,
                labelColor: kAccent,
                unselectedLabelColor: kText3,
                indicatorColor: kAccent,
                indicatorWeight: 2,
                tabs: srcOpts.map((o) {
                  // Vérifier si cette source bloque tout
                  final wMap = _weights[o.id] ?? {};
                  final allZero = wMap.values.every((v) => v == 0);
                  return Tab(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: allZero ? kText3 : o.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const Gap(6),
                        Text(o.name, style: GoogleFonts.dmSans(fontSize: 12)),
                        if (allZero) ...[
                          const Gap(4),
                          const Icon(Icons.block, size: 10, color: kText3),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // ── Corps : sliders + preview probabilités ──
            SizedBox(
              height: math.min(tgtOpts.length * 64.0 + 120, 420),
              child: TabBarView(
                controller: _tabCtrl,
                children: srcOpts.map((srcOpt) {
                  final probs = _probabilities(srcOpt.id);
                  final allZero = probs.values.every((v) => v == 0);

                  return ListView(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                    children: [
                      // Presets rapides
                      Row(
                        children: [
                          Text('Preset :',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: kText3)),
                          const Gap(8),
                          _PresetChip(
                            label: 'Égal',
                            onTap: () => _applyPreset(srcOpt.id, 'equal'),
                          ),
                          const Gap(6),
                          _PresetChip(
                            label: 'Bloquer',
                            onTap: () => _applyPreset(srcOpt.id, 'block'),
                            danger: true,
                          ),
                        ],
                      ),
                      if (allZero) ...[
                        const Gap(8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: kAccent4.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: kAccent4.withAlpha(51)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline,
                                  size: 14, color: kAccent4),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  'Tous les poids sont à 0 : cette roue sera ignorée quand "${srcOpt.name}" est tiré.',
                                  style: GoogleFonts.dmSans(
                                      fontSize: 11,
                                      color: kAccent4,
                                      height: 1.4),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const Gap(12),
                      // Sliders pour chaque option cible
                      ...tgtOpts.map((tgtOpt) {
                        final w =
                            _weights[srcOpt.id]?[tgtOpt.id] ?? 1.0;
                        final pct = probs[tgtOpt.id] ?? 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: tgtOpt.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    child: Text(
                                      tgtOpt.name,
                                      style: GoogleFonts.dmSans(
                                          fontSize: 13, color: kText),
                                    ),
                                  ),
                                  // Poids brut
                                  Text(
                                    '×${w.toStringAsFixed(w == w.roundToDouble() ? 0 : 1)}',
                                    style: GoogleFonts.syne(
                                      fontSize: 12,
                                      color: w == 0 ? kText3 : kAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Gap(8),
                                  // Pourcentage de probabilité
                                  Container(
                                    width: 38,
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      w == 0
                                          ? '0%'
                                          : '${(pct * 100).round()}%',
                                      style: GoogleFonts.syne(
                                        fontSize: 11,
                                        color: w == 0
                                            ? kText3.withAlpha(128)
                                            : kText2,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(4),
                              // Barre de probabilité + slider superposés
                              Stack(
                                children: [
                                  // Barre de probabilité en arrière-plan
                                  Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: pct,
                                        child: Container(
                                          height: 14,
                                          decoration: BoxDecoration(
                                            color: tgtOpt.color
                                                .withAlpha(w == 0 ? 10 : 38),
                                            borderRadius:
                                                BorderRadius.circular(7),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Slider
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor:
                                          tgtOpt.color.withAlpha(200),
                                      thumbColor: tgtOpt.color,
                                      inactiveTrackColor:
                                          kSurface3,
                                      trackHeight: 2,
                                      thumbShape:
                                          const RoundSliderThumbShape(
                                              enabledThumbRadius: 8),
                                      overlayShape:
                                          SliderComponentShape.noOverlay,
                                    ),
                                    child: Slider(
                                      value: w.clamp(0.0, 10.0),
                                      min: 0.0,
                                      max: 10.0,
                                      divisions: 20,
                                      onChanged: (val) {
                                        setState(() {
                                          _weights[srcOpt.id]![tgtOpt.id] =
                                              (val * 2).round() / 2;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  );
                }).toList(),
              ),
            ),

            // ── Actions ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SgButton(
                    label: 'Annuler',
                    variant: SgButtonVariant.secondary,
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Gap(10),
                  SgButton(
                    label: 'Sauvegarder',
                    onPressed: () {
                      context.read<GroupsProvider>().updateDependency(
                        widget.group.id,
                        widget.targetWheel.id,
                        widget.depIndex,
                        Dependency(
                          sourceWheelId: widget.dependency.sourceWheelId,
                          weights: _weights,
                        ),
                      );
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip de preset pour la matrice de dépendance
class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const _PresetChip({
    required this.label,
    required this.onTap,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = danger ? kAccent4 : kAccent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withAlpha(20),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withAlpha(64)),
        ),
        child: Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Onglet Paramètres (avec dégradé + répétition)
// ──────────────────────────────────────────────

class _SettingsTab extends StatelessWidget {
  final WheelGroup group;
  final SpinWheel wheel;

  const _SettingsTab({required this.group, required this.wheel});

  @override
  Widget build(BuildContext context) {
    final provider = context.read<GroupsProvider>();
    // Roues qui peuvent servir de source pour repeatCount
    final repeatSources = group.wheels
        .where((w) => w.id != wheel.id)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Retrait après tirage ──
        SgCard(
          child: Row(
            children: [
              const Icon(Icons.remove_circle_outline, color: kText2, size: 20),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Retirer après tirage',
                        style: GoogleFonts.syne(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kText)),
                    const Gap(2),
                    Text(
                      'L\'option tirée est supprimée de la roue après chaque tour.',
                      style: GoogleFonts.dmSans(fontSize: 12, color: kText3),
                    ),
                  ],
                ),
              ),
              Switch(
                value: wheel.removeAfterSpin,
                activeThumbColor: kAccent,
                onChanged: (v) =>
                    provider.updateWheel(group.id, wheel.id, removeAfterSpin: v),
              ),
            ],
          ),
        ),
        const Gap(12),

        // ── Dégradé de couleur ──
        SgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.gradient, color: kText2, size: 20),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Dégradé de couleur',
                            style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kText)),
                        const Gap(2),
                        Text(
                          'Les options passent de noir → couleur → blanc selon leur ordre.',
                          style:
                              GoogleFonts.dmSans(fontSize: 12, color: kText3),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: wheel.gradientBaseColor != null,
                    activeThumbColor: kAccent3,
                    onChanged: (v) {
                      provider.updateWheelGradient(
                        group.id,
                        wheel.id,
                        v ? kWheelColors[0] : null,
                      );
                    },
                  ),
                ],
              ),
              if (wheel.gradientBaseColor != null) ...[
                const Gap(12),
                Text('Couleur de base :',
                    style: GoogleFonts.dmSans(fontSize: 12, color: kText3)),
                const Gap(8),
                // Aperçu du dégradé actuel
                _GradientPreview(
                  baseColor: wheel.gradientBaseColor!,
                  optionCount: wheel.options.length,
                ),
                const Gap(10),
                ColorPickerGrid(
                  colors: kWheelColors,
                  selectedColor: wheel.gradientBaseColor!,
                  onSelected: (c) =>
                      provider.updateWheelGradient(group.id, wheel.id, c),
                ),
              ],
            ],
          ),
        ),
        const Gap(12),

        // ── Répétition ──
        SgCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.repeat, color: kText2, size: 20),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Répétition',
                            style: GoogleFonts.syne(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: kText)),
                        const Gap(2),
                        Text(
                          'Cette roue tourne plusieurs fois en session.',
                          style:
                              GoogleFonts.dmSans(fontSize: 12, color: kText3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(14),

              // Nombre fixe de répétitions
              Row(
                children: [
                  Flexible(
                    child: Text('Répétitions fixes :',
                        style: GoogleFonts.dmSans(fontSize: 13, color: kText2)),
                  ),
                  const Spacer(),
                  _CounterWidget(
                    value: wheel.repeatCount,
                    min: 1,
                    max: 10,
                    onChanged: (v) =>
                        provider.updateWheelRepeat(group.id, wheel.id, repeatCount: v),
                  ),
                ],
              ),

              if (repeatSources.isNotEmpty) ...[
                const Gap(12),
                Container(height: 1, color: kBorder),
                const Gap(12),
                Text(
                  'Ou piloter via une roue source :',
                  style: GoogleFonts.dmSans(fontSize: 12, color: kText3),
                ),
                const Gap(8),
                Text(
                  'Si la roue source retourne un entier (ex : "2"), cette roue tournera ce nombre de fois.',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: kText3, height: 1.4),
                ),
                const Gap(8),
                // Sélecteur de roue source
                _WheelSourceSelector(
                  wheels: repeatSources,
                  selectedId: wheel.repeatSourceWheelId,
                  onSelected: (id) => provider.updateWheelRepeat(
                    group.id,
                    wheel.id,
                    repeatSourceWheelId: id,
                    clearSource: id == null,
                  ),
                ),
              ],
            ],
          ),
        ),
        const Gap(80),
      ],
    );
  }
}

/// Aperçu visuel du dégradé sur les options de la roue
class _GradientPreview extends StatelessWidget {
  final Color baseColor;
  final int optionCount;

  const _GradientPreview({required this.baseColor, required this.optionCount});

  @override
  Widget build(BuildContext context) {
    final n = optionCount.clamp(2, 12);
    return Row(
      children: List.generate(n, (i) {
        final t = n == 1 ? 0.5 : i / (n - 1);
        final Color c;
        if (t <= 0.5) {
          final f = t / 0.5;
          c = Color.fromARGB(
            255,
            ((baseColor.r * 255.0).round().clamp(0, 255) * f).round(),
            ((baseColor.g * 255.0).round().clamp(0, 255) * f).round(),
            ((baseColor.b * 255.0).round().clamp(0, 255) * f).round(),
          );
        } else {
          final f = (t - 0.5) / 0.5;
          c = Color.fromARGB(
            255,
            (baseColor.r * 255.0).round().clamp(0, 255) + ((255 - (baseColor.r * 255.0).round().clamp(0, 255)) * f).round(),
            (baseColor.g * 255.0).round().clamp(0, 255) + ((255 - (baseColor.g * 255.0).round().clamp(0, 255)) * f).round(),
            (baseColor.b * 255.0).round().clamp(0, 255) + ((255 - (baseColor.b * 255.0).round().clamp(0, 255)) * f).round(),
          );
        }
        return Expanded(
          child: Container(
            height: 20,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.horizontal(
                left: i == 0 ? const Radius.circular(6) : Radius.zero,
                right: i == n - 1 ? const Radius.circular(6) : Radius.zero,
              ),
            ),
          ),
        );
      }),
    );
  }
}

/// Compteur +/- pour le nombre de répétitions
class _CounterWidget extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _CounterWidget({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterBtn(
          icon: Icons.remove,
          enabled: value > min,
          onTap: () => onChanged(value - 1),
        ),
        Container(
          width: 40,
          alignment: Alignment.center,
          child: Text(
            '$value',
            style: GoogleFonts.syne(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: value > 1 ? kAccent2 : kText2,
            ),
          ),
        ),
        _CounterBtn(
          icon: Icons.add,
          enabled: value < max,
          onTap: () => onChanged(value + 1),
        ),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _CounterBtn({required this.icon, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? kSurface2 : kSurface2.withAlpha(128),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: enabled ? kBorder2 : kBorder),
        ),
        child: Icon(
          icon,
          size: 16,
          color: enabled ? kText2 : kText3,
        ),
      ),
    );
  }
}

/// Sélecteur de roue source pour la répétition dynamique
class _WheelSourceSelector extends StatelessWidget {
  final List<SpinWheel> wheels;
  final String? selectedId;
  final ValueChanged<String?> onSelected;

  const _WheelSourceSelector({
    required this.wheels,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Option "aucune"
        _SourceTile(
          label: 'Aucune (répétition fixe)',
          isSelected: selectedId == null,
          onTap: () => onSelected(null),
          subtitle: null,
        ),
        ...wheels.map((w) {
          final optPreview = w.options.take(3).map((o) => o.name).join(', ');
          return _SourceTile(
            label: w.name,
            isSelected: selectedId == w.id,
            onTap: () => onSelected(w.id),
            subtitle: optPreview,
          );
        }),
      ],
    );
  }
}

class _SourceTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final String? subtitle;

  const _SourceTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kAccent.withAlpha(20) : kSurface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? kAccent.withAlpha(76) : kBorder,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: isSelected ? kAccent : kText3,
            ),
            const Gap(10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: isSelected ? kText : kText2,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.dmSans(fontSize: 10, color: kText3),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Dialogs groupe & roue (inchangés sauf _EditGroupDialog)
// ──────────────────────────────────────────────

class _EditGroupDialog extends StatefulWidget {
  final WheelGroup group;
  const _EditGroupDialog({required this.group});
  @override
  State<_EditGroupDialog> createState() => _EditGroupDialogState();
}

class _EditGroupDialogState extends State<_EditGroupDialog> {
  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.group.name);
    _descCtrl = TextEditingController(text: widget.group.description ?? '');
    _selectedColor = widget.group.color;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modifier le groupe',
                style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const Gap(20),
            SgTextField(label: 'Nom', controller: _nameCtrl, autofocus: true),
            const Gap(12),
            SgTextField(
                label: 'Description (optionnel)', controller: _descCtrl),
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
                SgButton(
                  label: 'Sauvegarder',
                  onPressed: () {
                    if (_nameCtrl.text.trim().isNotEmpty) {
                      context.read<GroupsProvider>().updateGroup(
                            widget.group.id,
                            name: _nameCtrl.text.trim(),
                            color: _selectedColor,
                            description: _descCtrl.text.trim().isEmpty
                                ? null
                                : _descCtrl.text.trim(),
                          );
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddWheelDialog extends StatefulWidget {
  final String groupId;
  const _AddWheelDialog({required this.groupId});
  @override
  State<_AddWheelDialog> createState() => _AddWheelDialogState();
}

class _AddWheelDialogState extends State<_AddWheelDialog> {
  final _ctrl = TextEditingController();
  final _optCtrl = TextEditingController();
  final List<String> _options = ['Option A', 'Option B', 'Option C'];

  @override
  void dispose() {
    _ctrl.dispose();
    _optCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: kBorder2),
      ),
      insetPadding: const EdgeInsets.all(20),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle roue',
                style: GoogleFonts.syne(
                    fontSize: 18, fontWeight: FontWeight.w700, color: kText)),
            const Gap(20),
            SgTextField(
              label: 'Nom de la roue',
              hint: 'Ex: Race, Classe, Origine…',
              controller: _ctrl,
              autofocus: true,
            ),
            const Gap(16),
            const SgSectionHeader('Options initiales'),
            ..._options.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: kWheelColors[e.key % kWheelColors.length],
                          shape: BoxShape.circle,
                        ),
                      ),
                      const Gap(8),
                      Expanded(
                          child: Text(e.value,
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: kText2))),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _options.removeAt(e.key)),
                        child: const Icon(Icons.close, size: 14, color: kText3),
                      ),
                    ],
                  ),
                )),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _optCtrl,
                    style: GoogleFonts.dmSans(fontSize: 13, color: kText),
                    decoration: InputDecoration(
                      hintText: 'Ajouter une option…',
                      hintStyle:
                          GoogleFonts.dmSans(fontSize: 13, color: kText3),
                      isDense: true,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 8),
                      border: InputBorder.none,
                    ),
                    onSubmitted: (v) {
                      if (v.trim().isNotEmpty) {
                        setState(() {
                          _options.add(v.trim());
                          _optCtrl.clear();
                        });
                      }
                    },
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    if (_optCtrl.text.trim().isNotEmpty) {
                      setState(() {
                        _options.add(_optCtrl.text.trim());
                        _optCtrl.clear();
                      });
                    }
                  },
                  child: const Icon(Icons.add_circle_outline,
                      color: kAccent, size: 20),
                ),
              ],
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
                SgButton(
                  label: 'Créer',
                  onPressed: () {
                    if (_ctrl.text.trim().isNotEmpty) {
                      context.read<GroupsProvider>().addWheel(
                            widget.groupId,
                            name: _ctrl.text.trim(),
                            optionNames:
                                _options.isNotEmpty ? _options : null,
                          );
                    }
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}