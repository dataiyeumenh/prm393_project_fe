import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Decorative gradient background shared across all screens.
///
/// Adds a soft pastel gradient plus two blurred color blobs
/// so the app never looks "blank white".
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        const Positioned.fill(child: _GradientLayer()),
        Positioned(
          top: -120,
          right: -80,
          child: _Blob(
            size: 280,
            gradient: AppColors.blobPink,
          ),
        ),
        Positioned(
          top: 200,
          left: -120,
          child: _Blob(
            size: 320,
            gradient: AppColors.blobButter,
          ),
        ),
        Positioned(
          bottom: -100,
          right: -60,
          child: _Blob(
            size: 260,
            gradient: AppColors.blobMint,
          ),
        ),
        child,
      ],
    );
  }
}

class _GradientLayer extends StatelessWidget {
  const _GradientLayer();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppColors.appBackground,
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.gradient});
  final double size;
  final RadialGradient gradient;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
        ),
      ),
    );
  }
}