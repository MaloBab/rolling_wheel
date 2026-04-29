// lib/presentation/widgets/buttons/sg_button.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

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
    final (bg, fg, border) = _resolveColors();

    final content = Row(
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
          child: content,
        ),
      ),
    );
  }

  (Color bg, Color fg, Color border) _resolveColors() => switch (variant) {
        SgButtonVariant.primary => (kAccent, Colors.white, kAccent),
        SgButtonVariant.secondary => (kSurface2, kText2, kBorder),
        SgButtonVariant.danger => (
            kAccent4.withAlpha(30),
            kAccent4,
            kAccent4.withAlpha(64)
          ),
        SgButtonVariant.ghost => (
            Colors.transparent,
            kText3,
            Colors.transparent
          ),
      };
}