import 'package:flutter/material.dart';

/// Centralized Design System Colors for CardSage.
/// Luxury Fintech Theme featuring Deep Obsidian, Imperial Gold, Cyber Emerald, and Royal Sapphire.
class AppColors {
  const AppColors._();

  // Canvas & Surfaces (Layered Dark System)
  static const Color canvasDark = Color(0xFF090B10);
  static const Color surfacePrimary = Color(0xFF11151F);
  static const Color surfaceSecondary = Color(0xFF181E2C);
  static const Color surfaceElevated = Color(0xFF222B3E);
  static const Color surfaceCard = Color(0xFF141926);

  // Luminous Borders & Dividers
  static const Color borderSubtle = Color(0x1FFFFFFF); // 12% White
  static const Color borderProminent = Color(0x33FFFFFF); // 20% White
  static const Color borderGlow = Color(0x40DFB76C); // Gold rim glow
  static const Color divider = Color(0x0FFFFFFF); // 6% White

  // Luxury Accents
  static const Color gold = Color(0xFFDFB76C);
  static const Color goldLight = Color(0xFFF7E096);
  static const Color goldDark = Color(0xFF8C6A24);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldLight = Color(0xFF34D399);
  static const Color emeraldDark = Color(0xFF065F46);

  static const Color sapphire = Color(0xFF3B82F6);
  static const Color sapphireLight = Color(0xFF60A5FA);
  static const Color sapphireDark = Color(0xFF1E3A8A);

  static const Color purple = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);

  // Typography Palette
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textTertiary = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF334155);

  // Status & Alerts
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Card Gradients
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE68A), Color(0xFFDFB76C), Color(0xFF8C6A24)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF065F46)],
  );

  static const LinearGradient sapphireGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF60A5FA), Color(0xFF3B82F6), Color(0xFF1E3A8A)],
  );

  static const LinearGradient obsidianGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E2638), Color(0xFF111520), Color(0xFF0B0E17)],
  );

  static const LinearGradient cardGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0x2EFFFFFF), Color(0x0AFFFFFF)],
  );
}
