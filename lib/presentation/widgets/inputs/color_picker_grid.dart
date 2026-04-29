// lib/presentation/widgets/inputs/color_picker_grid.dart

import 'package:flutter/material.dart';

class ColorPickerGrid extends StatefulWidget {
  final List<Color> colors;
  final Color selectedColor;
  final ValueChanged<Color> onSelected;

  const ColorPickerGrid({
    super.key,
    required this.colors,
    required this.selectedColor,
    required this.onSelected,
  });

  @override
  State<ColorPickerGrid> createState() => _ColorPickerGridState();
}

class _ColorPickerGridState extends State<ColorPickerGrid> {
  late Color _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedColor;
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.colors.map((c) {
        final isSelected = c == _selected;
        return GestureDetector(
          onTap: () {
            setState(() => _selected = c);
            widget.onSelected(c);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 2.5,
              ),
              boxShadow: isSelected
                  ? [BoxShadow(color: c.withAlpha(50), blurRadius: 8)]
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }
}