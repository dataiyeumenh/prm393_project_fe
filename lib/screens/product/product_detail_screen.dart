import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/product.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/disclosure_row.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/promo_badge.dart';
import '../../widgets/product_card.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, required this.product});

  final Product product;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  String? _selectedColorway;
  int _quantity = 1;
  bool _favorite = false;

  @override
  void initState() {
    super.initState();
    if (widget.product.colorways.isNotEmpty) {
      _selectedColorway = widget.product.colorways.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;
    final related = MockData.products
        .where((x) => x.categoryId == p.categoryId && x.id != p.id)
        .toList();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            CustomScrollView(
              slivers: [
                SliverAppBar(
                  backgroundColor: AppColors.canvas,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  pinned: true,
                  leading: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _IconCircle(
                      icon: Icons.arrow_back,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _IconCircle(
                        icon: _favorite ? Icons.favorite : Icons.favorite_border,
                        color: _favorite ? AppColors.sale : AppColors.ink,
                        onTap: () => setState(() => _favorite = !_favorite),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: _IconCircle(
                        icon: Icons.share_outlined,
                        onTap: () {},
                      ),
                    ),
                  ],
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        color: AppColors.softCloud,
                        height: 380,
                        child: Stack(
                          children: [
                            PageView(
                              onPageChanged: (i) =>
                                  setState(() => _imageIndex = i),
                              children: [
                                for (final url in p.images)
                                  CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    placeholder: (_, _) => const Center(
                                      child: CircularProgressIndicator(
                                        color: AppColors.mute,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                    errorWidget: (_, _, _) => const Center(
                                      child: Icon(
                                        Icons.pets,
                                        size: 64,
                                        color: AppColors.stone,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (p.images.length > 1)
                              Positioned(
                                bottom: 16,
                                right: 16,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.canvas,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.lg),
                                  ),
                                  child: Text(
                                    '${_imageIndex + 1} / ${p.images.length}',
                                    style: AppTypography.captionSm,
                                  ),
                                ),
                              ),
                            if (p.badges.isNotEmpty)
                              Positioned(
                                top: 16,
                                left: 16,
                                child: Wrap(
                                  spacing: 6,
                                  children: [
                                    for (final b in p.badges)
                                      PromoBadge(label: b),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.brand.toUpperCase(),
                              style: AppTypography.captionSm.copyWith(
                                color: AppColors.mute,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(p.name, style: AppTypography.headingXl),
                            const SizedBox(height: 4),
                            Text(
                              p.subtitle,
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.mute),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                for (var i = 0; i < 5; i++)
                                  Icon(
                                    i < p.rating.round()
                                        ? Icons.star
                                        : Icons.star_border,
                                    color: AppColors.star,
                                    size: 18,
                                  ),
                                const SizedBox(width: 8),
                                Text(
                                  '${p.rating}',
                                  style: AppTypography.bodyStrong,
                                ),
                                Text(
                                  '  ·  ${p.reviewCount} reviews',
                                  style: AppTypography.captionMd
                                      .copyWith(color: AppColors.mute),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                if (p.onSale)
                                  Text(
                                    '\$${p.price.toStringAsFixed(2)}',
                                    style: AppTypography.headingLg
                                        .copyWith(color: AppColors.sale),
                                  )
                                else
                                  Text(
                                    '\$${p.price.toStringAsFixed(2)}',
                                    style: AppTypography.headingLg,
                                  ),
                                if (p.onSale) ...[
                                  const SizedBox(width: 12),
                                  Text(
                                    '\$${p.originalPrice!.toStringAsFixed(2)}',
                                    style: AppTypography.bodyMd.copyWith(
                                      color: AppColors.mute,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  PromoBadge(
                                    label: '-${p.discountPercent}%',
                                    color: AppColors.sale,
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (p.colorways.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.fromLTRB(20, 8, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'FLAVOR: ${_selectedColorway?.toUpperCase() ?? ''}',
                                style: AppTypography.captionMd,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  for (final c in p.colorways)
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _selectedColorway = c),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 18,
                                          vertical: 10,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _selectedColorway == c
                                              ? AppColors.ink
                                              : AppColors.canvas,
                                          borderRadius:
                                              BorderRadius.circular(
                                                  AppRadius.lg),
                                          border: Border.all(
                                            color: _selectedColorway == c
                                                ? AppColors.ink
                                                : AppColors.hairline,
                                          ),
                                        ),
                                        child: Text(
                                          c,
                                          style: AppTypography.buttonSm
                                              .copyWith(
                                            color: _selectedColorway == c
                                                ? AppColors.onPrimary
                                                : AppColors.ink,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      const Divider(height: 1, color: AppColors.hairline),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: DisclosureRow(
                          label: 'View Product Details',
                          initiallyOpen: true,
                          child: Text(
                            p.description,
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.charcoal),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: DisclosureRow(
                          label: 'Ingredients',
                          child: Text(
                            p.ingredients.isEmpty
                                ? 'Information not available.'
                                : p.ingredients,
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.charcoal),
                          ),
                        ),
                      ),
                      if (p.nutrition.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: DisclosureRow(
                            label: 'Nutrition',
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                for (final entry in p.nutrition.entries)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          entry.key,
                                          style: AppTypography.captionMd,
                                        ),
                                        Text(
                                          entry.value,
                                          style: AppTypography.bodyStrong,
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: DisclosureRow(
                          label: 'Shipping & Returns',
                          child: Text(
                            'Free shipping on orders over \$50. 30-day hassle-free returns. '
                            'Members get free express shipping on all orders.',
                            style: AppTypography.bodyMd
                                .copyWith(color: AppColors.charcoal),
                          ),
                        ),
                      ),
                      Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 20),
                        child: DisclosureRow(
                          label: 'Reviews (${p.reviewCount})',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < 3; i++)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          for (var s = 0; s < 5; s++)
                                            Icon(
                                              s < 5 - i
                                                  ? Icons.star
                                                  : Icons.star_border,
                                              color: AppColors.star,
                                              size: 14,
                                            ),
                                          const SizedBox(width: 8),
                                          Text(
                                            ['Jordan M.', 'Sam K.', 'Avery L.'][i],
                                            style: AppTypography.bodyStrong,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        [
                                          'My pet absolutely loves this. Will definitely repurchase.',
                                          'Great quality and my vet recommended it. Highly recommend.',
                                          'A bit pricey but the ingredients are top notch.',
                                        ][i],
                                        style: AppTypography.bodyMd.copyWith(
                                          color: AppColors.charcoal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      if (related.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.section),
                        const SectionHeader(title: 'YOU MAY ALSO LIKE'),
                        SizedBox(
                          height: 280,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: related.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (_, i) => SizedBox(
                              width: 180,
                              child: ProductCard(
                                product: related[i],
                                onTap: () => Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                      product: related[i],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.canvas,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                padding: EdgeInsets.fromLTRB(
                  20,
                  12,
                  20,
                  12 + MediaQuery.of(context).padding.bottom,
                ),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.hairline),
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Row(
                        children: [
                          _QtyBtn(
                            icon: Icons.remove,
                            onTap: _quantity > 1
                                ? () => setState(() => _quantity--)
                                : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              '$_quantity',
                              textAlign: TextAlign.center,
                              style: AppTypography.bodyStrong,
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            onTap: () => setState(() => _quantity++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PrimaryButton(
                        label:
                            p.stock > 0 ? 'Add to Bag  •  \$${(p.price * _quantity).toStringAsFixed(2)}' : 'Notify Me',
                        expand: true,
                        icon: p.stock > 0 ? Icons.shopping_bag_outlined : Icons.notifications_none,
                        onPressed: () {
                          if (p.stock > 0) {
                            context.read<CartState>().add(p, qty: _quantity);
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.ink,
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
                                        'Added $_quantity × ${p.name} to bag.',
                                        style: AppTypography.captionMd
                                            .copyWith(color: AppColors.onPrimary),
                                      ),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                duration: const Duration(milliseconds: 1600),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'We\'ll notify you when it\'s back.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.lg),
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.icon, required this.onTap, this.color});
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.softCloud,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: color ?? AppColors.ink, size: 20),
        ),
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: SizedBox(
          width: 40,
          height: 48,
          child: Icon(
            icon,
            color: onTap == null ? AppColors.stone : AppColors.ink,
            size: 18,
          ),
        ),
      ),
    );
  }
}
