import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/product.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.width,
  });

  final Product product;
  final VoidCallback onTap;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final p = product;

    final card = InkWell(
      borderRadius: BorderRadius.circular(AppRadius.md),
      onTap: onTap,
      child: Container(
        width: width,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.softCloud, AppColors.canvas],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                      child: CachedNetworkImage(
                        imageUrl: p.imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (_, _) => const Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.mute,
                            ),
                          ),
                        ),
                        errorWidget: (_, _, _) => const Center(
                          child: Icon(
                            Icons.pets,
                            size: 36,
                            color: AppColors.stone,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (p.badges.isNotEmpty)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.canvas.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: AppColors.hairlineSoft),
                      ),
                      child: Text(
                        p.badges.first,
                        style: AppTypography.captionSm.copyWith(
                          color: AppColors.ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (p.onSale)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.sale, AppColors.saleDeep],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '-${p.discountPercent}%',
                        style: AppTypography.captionSm.copyWith(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  bottom: 8,
                  right: 8,
                  child: _QuickAddButton(product: p),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (p.colorways.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          for (var i = 0; i < p.colorways.length && i < 5; i++) ...[
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _swatchColor(p.colorways[i]),
                                border: Border.all(
                                  color: AppColors.hairline,
                                  width: 0.5,
                                ),
                              ),
                            ),
                            if (i < p.colorways.length - 1 && i < 4)
                              const SizedBox(width: 5),
                          ],
                        ],
                      ),
                    ),
                  Text(
                    p.name,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    p.subtitle,
                    style: AppTypography.captionSm
                        .copyWith(color: AppColors.mute, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _PriceRow(product: p),
                ],
              ),
            ),
          ],
        ),
      ),
    );

    return card;
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    final p = product;
    if (p.onSale) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            Formatters.vnd(p.price),
            style: AppTypography.bodyStrong.copyWith(
              color: AppColors.accentPinkDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            Formatters.vnd(p.originalPrice!),
            style: AppTypography.captionSm.copyWith(
              color: AppColors.ash,
              decoration: TextDecoration.lineThrough,
            ),
          ),
        ],
      );
    }
    return Text(
      Formatters.vnd(p.price),
      style: AppTypography.bodyStrong.copyWith(
        color: AppColors.ink,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _QuickAddButton extends StatelessWidget {
  const _QuickAddButton({required this.product});
  final Product product;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: () {
          context.read<CartState>().add(product);
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ink,
              duration: const Duration(milliseconds: 1400),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              content: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppColors.accentMint,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Đã thêm ${product.name} vào giỏ hàng',
                      style: AppTypography.captionMd
                          .copyWith(color: AppColors.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.gradientStart, AppColors.accentPinkDeep],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.add, color: AppColors.onPrimary, size: 20),
        ),
      ),
    );
  }
}

Color _swatchColor(String name) {
  final n = name.toLowerCase();
  if (n.contains('salmon') || n.contains('pink')) return AppColors.dogAccent;
  if (n.contains('chicken') || n.contains('beef') || n.contains('peanut')) {
    return const Color(0xFFE0A464);
  }
  if (n.contains('tuna') || n.contains('fish') || n.contains('teal')) {
    return AppColors.catAccent;
  }
  if (n.contains('mint')) return AppColors.successBright;
  if (n.contains('gray')) return AppColors.charcoal;
  if (n.contains('red')) return AppColors.sale;
  if (n.contains('blue')) return AppColors.info;
  if (n.contains('multi')) return AppColors.accentPurpleSoft;
  if (n.contains('butter') || n.contains('yellow')) {
    return AppColors.fishAccent;
  }
  if (n.contains('lavender') || n.contains('purple')) {
    return AppColors.accentPurpleSoft;
  }
  return AppColors.ink;
}