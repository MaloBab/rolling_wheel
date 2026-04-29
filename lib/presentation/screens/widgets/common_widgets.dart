// lib/widgets/common_widgets.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../utils/app_theme.dart';

// ──────────────────────────────────────────────
// SgCard
// ──────────────────────────────────────────────

class SgCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? borderColor;

  const SgCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: kAccent.withAlpha(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor ?? kBorder),
          ),
          padding: padding ?? const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SgChip
// ──────────────────────────────────────────────

class SgChip extends StatelessWidget {
  final String label;
  final Color? color;

  const SgChip(this.label, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: (color ?? kAccent).withAlpha(38),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: (color ?? kAccent).withAlpha(76)),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: color ?? kAccent,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SgButton
// ──────────────────────────────────────────────

enum SgButtonVariant { primary, secondary, danger, ghost }

class SgButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final SgButtonVariant variant;
  final IconData? icon;
  final bool fullWidth;
  final bool small;

  const SgButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = SgButtonVariant.primary,
    this.icon,
    this.fullWidth = false,
    this.small = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Color border;
    switch (variant) {
      case SgButtonVariant.primary:
        bg = kAccent;
        fg = Colors.white;
        border = kAccent;
      case SgButtonVariant.secondary:
        bg = kSurface2;
        fg = kText2;
        border = kBorder;
      case SgButtonVariant.danger:
        bg = kAccent4.withAlpha(30);
        fg = kAccent4;
        border = kAccent4.withAlpha(64);
      case SgButtonVariant.ghost:
        bg = Colors.transparent;
        fg = kText3;
        border = Colors.transparent;
    }

    Widget child = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          Icon(icon, size: small ? 14 : 16, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: small ? 12 : 13,
            fontWeight: FontWeight.w500,
            color: fg,
          ),
        ),
      ],
    );

    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: small
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 7)
              : const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: child,
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────
// SgTextField
// ──────────────────────────────────────────────

class SgTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final bool autofocus;

  const SgTextField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.onChanged,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      autofocus: autofocus,
      style: GoogleFonts.dmSans(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
      ),
    );
  }
}

// ──────────────────────────────────────────────
// ColorPicker (grille de pastilles)
// ──────────────────────────────────────────────

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

// ──────────────────────────────────────────────
// Section header
// ──────────────────────────────────────────────

class SgSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const SgSectionHeader(this.title, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.syne(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: kText3,
              letterSpacing: 0.8,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing!,
          ],
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────
// Gradient text
// ──────────────────────────────────────────────

class GradientText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final Gradient gradient;

  const GradientText(
    this.text, {
    super.key,
    this.style,
    this.gradient = const LinearGradient(
      colors: [kAccent, kAccent3],
    ),
  });

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (bounds) => gradient.createShader(
        Rect.fromLTWH(0, 0, bounds.width, bounds.height),
      ),
      child: Text(text, style: style),
    );
  }
}

// ──────────────────────────────────────────────
// Snackbar helper
// ──────────────────────────────────────────────

void showSgSnackbar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message, style: GoogleFonts.dmSans(color: kText)),
      backgroundColor: error ? kAccent4.withAlpha(230) : kSurface2,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: error ? kAccent4 : kBorder2),
      ),
      duration: const Duration(seconds: 3),
    ),
  );
}