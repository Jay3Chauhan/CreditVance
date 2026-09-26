import 'package:flutter/material.dart';

/// Brand and raw color tokens for CreditVance.
///
/// Screens should not read these directly for surfaces or text — use the
/// theme-aware `context.colors` (see [AppPalette]) so light, dark and system
/// modes all render correctly. Brand accents and card skins live here because
/// they are identical across themes.
class AppColors {
  const AppColors._();

  // Brand accents
  static const Color gold = Color(0xFFD6B06A);
  static const Color goldLight = Color(0xFFF1D9A3);
  static const Color goldDeep = Color(0xFF9C7430);

  static const Color emerald = Color(0xFF10B981);
  static const Color emeraldDeep = Color(0xFF047857);

  static const Color sapphire = Color(0xFF3B82F6);
  static const Color sapphireDeep = Color(0xFF1D4ED8);

  static const Color violet = Color(0xFF8B5CF6);
  static const Color rose = Color(0xFFF43F5E);
  static const Color amber = Color(0xFFF59E0B);
  static const Color teal = Color(0xFF14B8A6);
  static const Color ruby = Color(0xFFEF4444);

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Dark palette
  static const Color darkCanvas = Color(0xFF09090C);
  static const Color darkSurface = Color(0xFF111217);
  static const Color darkSurfaceAlt = Color(0xFF17191F);
  static const Color darkSurfaceHigh = Color(0xFF1F222A);
  static const Color darkBorder = Color(0x14FFFFFF);
  static const Color darkBorderStrong = Color(0x24FFFFFF);
  static const Color darkTextPrimary = Color(0xFFF4F4F5);
  static const Color darkTextSecondary = Color(0xFFA1A1AA);
  static const Color darkTextTertiary = Color(0xFF71717A);

  // Light palette (warm ivory)
  static const Color lightCanvas = Color(0xFFF7F6F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1EFEA);
  static const Color lightSurfaceHigh = Color(0xFFE8E5DE);
  static const Color lightBorder = Color(0x14000000);
  static const Color lightBorderStrong = Color(0x26000000);
  static const Color lightTextPrimary = Color(0xFF14151A);
  static const Color lightTextSecondary = Color(0xFF585C66);
  static const Color lightTextTertiary = Color(0xFF8B8F99);
  static const Color lightGold = Color(0xFFA27A2F);
  static const Color lightEmerald = Color(0xFF059669);
  static const Color lightSapphire = Color(0xFF2563EB);
  static const Color lightRuby = Color(0xFFDC2626);
  static const Color lightAmber = Color(0xFFD97706);

  // Card surface text (cards are always rendered as dark metal)
  static const Color cardText = Color(0xFFF8F8FA);
  static const Color cardTextMuted = Color(0xB3F8F8FA);
  static const Color cardTextFaint = Color(0x80F8F8FA);
  static const Color cardChipLight = Color(0xFFE9CD8C);
  static const Color cardChipDark = Color(0xFF9A7738);
  static const Color cardStripe = Color(0xFF16161A);
  static const Color cardSignature = Color(0xFFECE9E1);

  static const Color scrim = Color(0x99000000);
  static const Color shadowDark = Color(0x66000000);
  static const Color shadowLight = Color(0x1A1B1A17);

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF3DDA6), Color(0xFFD6B06A), Color(0xFF9C7430)],
  );

  static const LinearGradient emeraldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF34D399), Color(0xFF10B981), Color(0xFF047857)],
  );

  /// Card skins used by the vault card renderer.
  static const List<CardSkin> cardSkins = [
    CardSkin(
      name: 'Obsidian',
      colors: [Color(0xFF2A2C33), Color(0xFF141519), Color(0xFF0A0A0D)],
      accent: Color(0xFFD6B06A),
    ),
    CardSkin(
      name: 'Aurum',
      colors: [Color(0xFF3B2F1A), Color(0xFF1E180D), Color(0xFF0D0A05)],
      accent: Color(0xFFF1D9A3),
    ),
    CardSkin(
      name: 'Sapphire',
      colors: [Color(0xFF1B2F5E), Color(0xFF0F1A36), Color(0xFF070C1A)],
      accent: Color(0xFF93C5FD),
    ),
    CardSkin(
      name: 'Emerald',
      colors: [Color(0xFF123D31), Color(0xFF0A221B), Color(0xFF04100C)],
      accent: Color(0xFF6EE7B7),
    ),
    CardSkin(
      name: 'Amethyst',
      colors: [Color(0xFF34225A), Color(0xFF1B1233), Color(0xFF0C0818)],
      accent: Color(0xFFC4B5FD),
    ),
    CardSkin(
      name: 'Titanium',
      colors: [Color(0xFF4A4D55), Color(0xFF2A2C31), Color(0xFF16171A)],
      accent: Color(0xFFE4E4E7),
    ),
    CardSkin(
      name: 'Rosso',
      colors: [Color(0xFF4A1A22), Color(0xFF260C12), Color(0xFF120508)],
      accent: Color(0xFFFDA4AF),
    ),
  ];
}

/// Visual skin for a rendered credit card.
class CardSkin {
  final String name;
  final List<Color> colors;
  final Color accent;

  const CardSkin({
    required this.name,
    required this.colors,
    required this.accent,
  });

  LinearGradient get gradient => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: colors,
      );

  /// Picks a skin from a card's name / bank so each card is recognisable
  /// and stays stable across launches.
  static CardSkin resolve({required String cardName, required String bankName}) {
    final name = cardName.toLowerCase();
    final skins = AppColors.cardSkins;
    if (name.contains('infinia') ||
        name.contains('magnus') ||
        name.contains('reserve') ||
        name.contains('emeralde') ||
        name.contains('centurion')) {
      return skins[1];
    }
    if (name.contains('atlas') || name.contains('travel') || name.contains('regalia')) {
      return skins[2];
    }
    if (name.contains('cashback') || name.contains('millennia') || name.contains('neu')) {
      return skins[3];
    }
    if (name.contains('platinum') || name.contains('metal')) {
      return skins[5];
    }
    final seed = (cardName + bankName).codeUnits.fold<int>(0, (a, b) => a + b);
    return skins[seed % skins.length];
  }
}
