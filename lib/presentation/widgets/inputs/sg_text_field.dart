// lib/presentation/widgets/inputs/sg_text_field.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../theme/app_theme.dart';

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