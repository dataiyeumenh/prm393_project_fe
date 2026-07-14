import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../theme/app_theme.dart';

/// Cute, illustrated hero banner for the home screen.
class HeroBanner extends StatefulWidget {
  const HeroBanner({
    super.key,
    required this.onShopTap,
  });

  final VoidCallback onShopTap;

  @override
  State<HeroBanner> createState() => _HeroBannerState();
}

class _HeroBannerState extends State<HeroBanner> {
  final _ctrl = PageController(viewportFraction: 0.86);
  int _index = 0;

  static const List<_Slide> _slides = [
    _Slide(
      kicker: 'MỚI TUẦN NÀY',
      title: 'Làm\nvới yêu\nthương',
      body: 'Nguyên liệu thật cho boss khỏe mỗi ngày.',
      cta: 'Mua sản phẩm hot',
      image:
          'https://images.unsplash.com/photo-1583511655826-05700d52f4d9?w=900',
      gradient: [AppColors.gradientStart, AppColors.accentPinkDeep],
    ),
    _Slide(
      kicker: 'BST MÙA XUÂN',
      title: 'Mèo\nlên đồ',
      body: 'Pate & snack khiến boss mèo mê tít.',
      cta: 'Khám phá mèo',
      image:
          'https://images.unsplash.com/photo-1574144611937-0df059b5ef3e?w=900',
      gradient: [AppColors.gradientMid, AppColors.fishAccent],
    ),
    _Slide(
      kicker: 'BẠN CÓ CÁNH',
      title: 'Boss\nnhỏ,\nniềm vui lớn',
      body: 'Đồ dùng cho chim, cá và thú nhỏ.',
      cta: 'Xem tất cả',
      image:
          'https://images.unsplash.com/photo-1522858547137-f1dcec554f55?w=900',
      gradient: [AppColors.gradientEnd, AppColors.accentTeal],
    ),
  ];

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 320,
          child: PageView.builder(
            controller: _ctrl,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: _slides.length,
            itemBuilder: (_, i) {
              final s = _slides[i];
              return Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: i == _slides.length - 1 ? 16 : 10,
                ),
                child: _HeroCard(slide: s, onTap: widget.onShopTap),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < _slides.length; i++) ...[
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: i == _index ? 22 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _index
                      ? AppColors.accentPinkDeep
                      : AppColors.hairline,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              if (i < _slides.length - 1) const SizedBox(width: 4),
            ],
          ],
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.slide, required this.onTap});
  final _Slide slide;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: slide.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _PawPatternPainter()),
            ),
            Positioned(
              right: -16,
              bottom: -16,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.onPrimary.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.onPrimary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: Text(
                      slide.kicker,
                      style: AppTypography.captionSm.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    slide.title,
                    style: AppTypography.displayCampaign.copyWith(
                      color: AppColors.onPrimary,
                      fontSize: 56,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    slide.body,
                    style: AppTypography.bodyMd.copyWith(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          color: Color(0x66000000),
                          blurRadius: 8,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Material(
                    color: AppColors.canvas,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      onTap: onTap,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              slide.cta,
                              style: AppTypography.buttonSm.copyWith(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.arrow_forward,
                              size: 14,
                              color: AppColors.ink,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 14,
              top: 24,
              child: ClipOval(
                child: SizedBox(
                  width: 110,
                  height: 110,
                  child: CachedNetworkImage(
                    imageUrl: slide.image,
                    fit: BoxFit.cover,
                    placeholder: (_, _) => Container(
                      color: AppColors.onPrimary.withValues(alpha: 0.3),
                    ),
                    errorWidget: (_, _, _) => Container(
                      color: AppColors.onPrimary.withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.pets,
                        color: AppColors.onPrimary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PawPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onPrimary.withValues(alpha: 0.07)
      ..style = PaintingStyle.fill;

    const pawSpacing = 70.0;
    for (var y = -10.0; y < size.height; y += pawSpacing) {
      for (var x = -10.0; x < size.width; x += pawSpacing) {
        // 4 toe pads
        for (var t = 0; t < 4; t++) {
          final tx = x + (t % 2) * 12.0;
          final ty = y + (t ~/ 2) * 10.0;
          canvas.drawCircle(Offset(tx, ty), 5, paint);
        }
        // main pad
        canvas.drawOval(
          Rect.fromCenter(center: Offset(x + 8, y + 24), width: 22, height: 18),
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Slide {
  const _Slide({
    required this.kicker,
    required this.title,
    required this.body,
    required this.cta,
    required this.image,
    required this.gradient,
  });
  final String kicker;
  final String title;
  final String body;
  final String cta;
  final String image;
  final List<Color> gradient;
}