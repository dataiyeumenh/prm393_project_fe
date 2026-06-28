import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class CampaignTile extends StatelessWidget {
  const CampaignTile({
    super.key,
    required this.headline,
    required this.subhead,
    required this.cta,
    required this.background,
    required this.onTap,
    this.textColor = AppColors.onPrimary,
    this.height = 480,
  });

  final String headline;
  final String subhead;
  final String cta;
  final Color background;
  final VoidCallback onTap;
  final Color textColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [background, background.withValues(alpha: 0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PetPatternPainter(background)),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    subhead.toUpperCase(),
                    style: AppTypography.captionSm.copyWith(
                      color: textColor.withValues(alpha: 0.8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        headline,
                        style: AppTypography.displayCampaign.copyWith(
                          color: textColor,
                          fontSize: 72,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Material(
                        color: AppColors.canvas,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            child: Text(
                              cta,
                              style: AppTypography.buttonMd.copyWith(
                                color: AppColors.ink,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetPatternPainter extends CustomPainter {
  _PetPatternPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    for (var i = 0; i < 8; i++) {
      final cx = size.width * (i % 4) * 0.28 + 30;
      final cy = size.height * (i ~/ 4) * 0.55 + 40;
      canvas.drawCircle(Offset(cx, cy), 60, paint);
      canvas.drawCircle(Offset(cx + 35, cy + 25), 35, paint);
      canvas.drawCircle(Offset(cx + 80, cy - 10), 45, paint);
    }

    final stroke = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 5; i++) {
      final y = size.height * (i + 1) / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), stroke);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
