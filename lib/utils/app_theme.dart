// lib/utils/app_theme.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ──────────────────────────────────────────────
// Palette
// ──────────────────────────────────────────────

const kBg = Color(0xFF0D0E14);
const kSurface = Color(0xFF14151F);
const kSurface2 = Color(0xFF1C1D2B);
const kSurface3 = Color(0xFF22233A);
const kAccent = Color(0xFF7C6FF7);
const kAccent2 = Color(0xFFF7C16F);
const kAccent3 = Color(0xFF6FF7C1);
const kAccent4 = Color(0xFFF76F9A);
const kText = Color(0xFFF0EEFF);
const kText2 = Color(0xFF9896B8);
const kText3 = Color(0xFF5A5878);
const kBorder = Color(0x267C6FF7);
const kBorder2 = Color(0x4D7C6FF7);

/// Couleurs disponibles pour les options de roue
const kWheelColors = [
  Color(0xFF7C6FF7), Color(0xFFF7C16F), Color(0xFF6FF7C1), Color(0xFFF76F9A),
  Color(0xFF6FC8F7), Color(0xFFF79C6F), Color(0xFFB06FF7), Color(0xFF6FF78C),
  Color(0xFFF76F6F), Color(0xFF6FD4F7), Color(0xFFF7E76F), Color(0xFF6F8CF7),
  Color(0xFFE26FF7), Color(0xFF6FF7B8), Color(0xFFF7A66F), Color(0xFF6FB2F7),
  Color(0xFFD4F76F), Color(0xFFF76FB6), Color(0xFF6FF7F7), Color(0xFFF7836F),
  Color(0xFF7EF76F), Color(0xFFF76FC8), Color(0xFF6F9FF7), Color(0xFFF7CF6F),
];

/// Couleurs disponibles pour les groupes
const kGroupColors = [
  Color(0xFF7C6FF7), Color(0xFFF7C16F), Color(0xFF6FF7C1),
  Color(0xFFF76F9A), Color(0xFF6FC8F7), Color(0xFFB06FF7),
  Color(0xFF6FF78C), Color(0xFFF79C6F),
];

// ──────────────────────────────────────────────
// Theme
// ──────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: kBg,
    colorScheme: const ColorScheme.dark(
      primary: kAccent,
      secondary: kAccent2,
      surface: kSurface,
    ),
    textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.syne(
        fontSize: 32, fontWeight: FontWeight.w800, color: kText,
      ),
      displayMedium: GoogleFonts.syne(
        fontSize: 24, fontWeight: FontWeight.w700, color: kText,
      ),
      titleLarge: GoogleFonts.syne(
        fontSize: 18, fontWeight: FontWeight.w700, color: kText,
      ),
      titleMedium: GoogleFonts.syne(
        fontSize: 15, fontWeight: FontWeight.w600, color: kText,
      ),
      bodyLarge: GoogleFonts.dmSans(fontSize: 15, color: kText),
      bodyMedium: GoogleFonts.dmSans(fontSize: 13, color: kText2),
      bodySmall: GoogleFonts.dmSans(fontSize: 11, color: kText3),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface2,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAccent, width: 1.5),
      ),
      labelStyle: GoogleFonts.dmSans(color: kText3, fontSize: 13),
      hintStyle: GoogleFonts.dmSans(color: kText3, fontSize: 13),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAccent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.syne(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: kBorder),
      ),
    ),
    dividerColor: kBorder,
  );
}