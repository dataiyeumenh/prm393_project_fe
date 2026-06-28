import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CategoryIconCard extends StatelessWidget {
  const CategoryIconCard({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Use the saturated accent directly for both bg and icon, with a
    // white-on-color treatment for legibility against the cream canvas.
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: SizedBox(
        width: 84,
        child: Column(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color,
                    _darken(color, 0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.55),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
                border: Border.all(color: AppColors.onPrimary, width: 3),
              ),
              alignment: Alignment.center,
              child: Icon(icon, color: AppColors.onPrimary, size: 32),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: AppTypography.captionMd.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Color _darken(Color base, double amount) {
    final hsl = HSLColor.fromColor(base);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }
}