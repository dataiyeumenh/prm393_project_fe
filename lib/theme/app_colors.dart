import 'package:flutter/material.dart';

/// Pet food brand tokens — warm, friendly, with playful accents.
class AppColors {
  AppColors._();

  // Brand & Accent
  static const Color ink = Color(0xFF111111); // pure black for max contrast
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Surface — warm gradient stops (cream → peach → mint)
  static const Color canvas = Color(0xFFFFFBF5); // very light warm white
  static const Color canvasDeep = Color(0xFFFEF4E4); // warmer cream
  static const Color softCloud = Color(0xFFFDEEE0); // peach cream
  static const Color hairline = Color(0xFFE0D4C4);
  static const Color hairlineSoft = Color(0xFFEDE3D6);

  // Text scale — darker for legibility against cream
  static const Color charcoal = Color(0xFF2A2630);
  static const Color ash = Color(0xFF4A4550);
  static const Color mute = Color(0xFF5C5762); // darker than before (was #6F6975)
  static const Color stone = Color(0xFF8C8590); // darker than before (was #9A939F)

  // Semantic
  static const Color sale = Color(0xFFFF5C8A); // coral pink
  static const Color saleDeep = Color(0xFFD63A6B);
  static const Color success = Color(0xFF3DAE73); // slightly darker mint
  static const Color successBright = Color(0xFF7DD8A2);
  static const Color info = Color(0xFF5B7AFE);

  // Pet category accents — cute & saturated
  static const Color dogAccent = Color(0xFFFFB4C2); // pastel pink
  static const Color catAccent = Color(0xFFA8E0E5); // mint teal
  static const Color birdAccent = Color(0xFFC8B6FF); // lavender
  static const Color fishAccent = Color(0xFFFFD9A0); // butter
  static const Color smallPetAccent = Color(0xFFFFE5B4); // peach

  // Brand gradient anchors (for hero, FAB, pills)
  static const Color gradientStart = Color(0xFFFFB4C2); // pink
  static const Color gradientMid = Color(0xFFFFD9A0); // butter
  static const Color gradientEnd = Color(0xFFA8E0E5); // mint

  // Editorial accent palette
  static const Color accentPink = Color(0xFFFF5C8A);
  static const Color accentPinkSoft = Color(0xFFFFD6E1);
  static const Color accentPurpleSoft = Color(0xFFC8B6FF);
  static const Color accentPurplePale = Color(0xFFE6DEFF);
  static const Color accentTeal = Color(0xFF6FBFB8);
  static const Color accentPinkDeep = Color(0xFFC24577);
  static const Color accentButter = Color(0xFFFFE5B4);
  static const Color accentMint = Color(0xFFCDEFD8);

  // Functional
  static const Color star = Color(0xFFFFB940); // amber for ratings

  // Saturated category accents (for icon cards — pastel versions stay for soft bg)
  static const Color dogAccentSolid = Color(0xFFFF6B8E); // saturated pink
  static const Color catAccentSolid = Color(0xFF4FB8C0); // saturated teal
  static const Color birdAccentSolid = Color(0xFF9C7AFF); // saturated purple
  static const Color fishAccentSolid = Color(0xFFFF9A45); // saturated orange
  static const Color treatsAccentSolid = Color(0xFF34C76A); // saturated green
  static const Color catLitterAccentSolid = Color(0xFF5C5762); // charcoal
  static const Color toysAccentSolid = Color(0xFFB86BFF); // saturated purple
  static const Color accessoriesAccentSolid = Color(0xFFFFB85C); // amber peach

  /// Cute pastel gradient used as the app background.
  static const LinearGradient appBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFF7E8), // warm cream top-left
      Color(0xFFFFFBF5), // canvas center
      Color(0xFFF1F8F5), // cool mint bottom-right
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Subtle decorative blobs for hero/page backgrounds.
  static const RadialGradient blobPink = RadialGradient(
    colors: [Color(0x33FFB4C2), Color(0x00FFB4C2)],
  );
  static const RadialGradient blobMint = RadialGradient(
    colors: [Color(0x33A8E0E5), Color(0x00A8E0E5)],
  );
  static const RadialGradient blobButter = RadialGradient(
    colors: [Color(0x33FFD9A0), Color(0x00FFD9A0)],
  );
}