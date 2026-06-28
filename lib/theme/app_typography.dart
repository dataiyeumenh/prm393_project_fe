import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Display-style title with a friendly gradient fill and a soft
/// script/cursive font for a "cong cong" feel.
class GradientHeadline extends StatelessWidget {
  const GradientHeadline(
    this.text, {
    super.key,
    this.fontSize = 72,
    this.height = 0.9,
    this.gradient,
    this.shadows = const [
      Shadow(
        color: Color(0x33000000),
        blurRadius: 18,
        offset: Offset(0, 4),
      ),
    ],
    this.useScript = true,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.5,
  });

  final String text;
  final double fontSize;
  final double height;
  final LinearGradient? gradient;
  final List<Shadow> shadows;

  /// When true uses a flowing script font (Caveat / Pacifico via Google Fonts);
  /// falls back to Bebas Neue if script font fails to load.
  final bool useScript;
  final FontWeight fontWeight;
  final double letterSpacing;

  static const _defaultGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFC24577), // accentPinkDeep
      Color(0xFFFF5C8A), // accentPink
      Color(0xFFFF8B40), // warm orange
    ],
  );

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
      color: AppColors.ink, // overwritten by shader
    );
    final TextStyle styled = useScript
        ? GoogleFonts.pacifico(
            textStyle: base.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              height: 1.1,
            ),
          )
        : base.copyWith(fontFamily: 'Bebas Neue');

    return ShaderMask(
      blendMode: BlendMode.srcIn,
      shaderCallback: (rect) => (gradient ?? _defaultGradient).createShader(
        Rect.fromLTWH(0, 0, rect.width, rect.height),
      ),
      child: Text(text, style: styled),
    );
  }
}

/// Plain solid-color display headline with optional shadow.
class DisplayHeadline extends StatelessWidget {
  const DisplayHeadline(
    this.text, {
    super.key,
    this.fontSize = 72,
    this.height = 0.9,
    this.color,
    this.shadows = const [
      Shadow(
        color: Color(0x22000000),
        blurRadius: 12,
        offset: Offset(0, 3),
      ),
    ],
    this.useScript = true,
    this.fontWeight = FontWeight.w600,
    this.letterSpacing = 0.5,
  });

  final String text;
  final double fontSize;
  final double height;
  final Color? color;
  final List<Shadow> shadows;

  /// When true uses a flowing script font (Pacifico).
  final bool useScript;
  final FontWeight fontWeight;
  final double letterSpacing;

  @override
  Widget build(BuildContext context) {
    final base = TextStyle(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      shadows: shadows,
      color: color ?? AppColors.ink,
    );
    final styled = useScript
        ? GoogleFonts.pacifico(
            textStyle: base.copyWith(
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
              height: 1.1,
            ),
          )
        : base.copyWith(fontFamily: 'Bebas Neue');
    return Text(text, style: styled);
  }
}

class AppTypography {
  AppTypography._();

  static const Color _defaultInk = Color(0xFF111111);

  static TextStyle displayCampaign = const TextStyle(
    fontFamily: 'Bebas Neue',
    fontSize: 64,
    fontWeight: FontWeight.w600,
    height: 0.9,
    letterSpacing: 0.5,
    color: _defaultInk,
  );

  static TextStyle headingXl = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.5,
    color: _defaultInk,
  );

  static TextStyle headingLg = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
    color: _defaultInk,
  );

  static TextStyle headingMd = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.4,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle bodyMd = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle bodyStrong = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.5,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle buttonLg = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle buttonMd = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle buttonSm = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle linkMd = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    decoration: TextDecoration.underline,
    color: _defaultInk,
  );

  static TextStyle captionMd = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle captionSm = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0,
    color: _defaultInk,
  );

  static TextStyle utilityXs = const TextStyle(
    fontFamily: 'Inter',
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0,
    color: _defaultInk,
  );
}

class AppRadius {
  AppRadius._();

  static const double none = 0;
  static const double sm = 18;
  static const double md = 24;
  static const double lg = 30;
  static const double full = 9999;
}