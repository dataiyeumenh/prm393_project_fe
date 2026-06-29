import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../models/api/product_dto.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/disclosure_row.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/promo_badge.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    this.product,
    this.productId,
  });

  final Product? product;
  final String? productId;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _imageIndex = 0;
  int _quantity = 1;
  bool _favorite = false;
  bool _loading = true;
  ProductDetailDTO? _productDetail;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loading = false;
    } else if (widget.productId != null) {
      _loadProduct();
    }
  }

  Future<void> _loadProduct() async {
    if (widget.productId == null) return;
    
    final result = await ProductService.getProductById(widget.productId!);
    if (mounted) {
      if (result.isSuccess && result.data != null) {
        setState(() {
          _productDetail = result.data;
          _loading = false;
        });
      } else {
        setState(() {
          _error = result.error ?? 'Failed to load product';
          _loading = false;
        });
      }
    }
  }

  bool get _isFromApi => widget.product == null && _productDetail != null;
  String get _name => _isFromApi ? _productDetail!.name : widget.product!.name;
  String? get _brandName => _isFromApi ? _productDetail!.brandName : widget.product!.brand;
  double get _price => _isFromApi ? _productDetail!.price : widget.product!.price;
  String get _description => _isFromApi ? (_productDetail!.description ?? '') : widget.product!.description;
  int get _stockQuantity => _isFromApi ? _productDetail!.stockQuantity : widget.product!.stock;
  List<String> get _images {
    if (_isFromApi) {
      return _productDetail!.images.map((img) => img.imageUrl).toList();
    }
    return widget.product!.images;
  }
  String? get _subtitle => _isFromApi ? _productDetail!.categoryName : widget.product!.subtitle;

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.canvas,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.mute),
              const SizedBox(height: 16),
              Text(_error!, style: AppTypography.bodyMd),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadProduct();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final images = _images;

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
                            images.isNotEmpty
                                ? PageView(
                                    onPageChanged: (i) =>
                                        setState(() => _imageIndex = i),
                                    children: images.map((url) {
                                      return CachedNetworkImage(
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
                                      );
                                    }).toList(),
                                  )
                                : const Center(
                                    child: Icon(
                                      Icons.image,
                                      size: 64,
                                      color: AppColors.stone,
                                    ),
                                  ),
                            if (images.length > 1)
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
                                    '${_imageIndex + 1} / ${images.length}',
                                    style: AppTypography.captionSm,
                                  ),
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
                            if (_brandName != null)
                              Text(
                                _brandName!.toUpperCase(),
                                style: AppTypography.captionSm.copyWith(
                                  color: AppColors.mute,
                                  letterSpacing: 1.5,
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(_name, style: AppTypography.headingXl),
                            if (_subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                _subtitle!,
                                style: AppTypography.bodyMd
                                    .copyWith(color: AppColors.mute),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  '\$${_price.toStringAsFixed(0)}',
                                  style: AppTypography.headingLg,
                                ),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _stockQuantity > 0
                                        ? AppColors.success.withValues(alpha: 0.1)
                                        : AppColors.sale.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(AppRadius.full),
                                  ),
                                  child: Text(
                                    _stockQuantity > 0
                                        ? '$_stockQuantity in stock'
                                        : 'Out of stock',
                                    style: AppTypography.captionSm.copyWith(
                                      color: _stockQuantity > 0
                                          ? AppColors.success
                                          : AppColors.sale,
                                      fontWeight: FontWeight.w600,
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
                      if (_description.isNotEmpty)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: DisclosureRow(
                            label: 'Product Details',
                            initiallyOpen: true,
                            child: Text(
                              _description,
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.charcoal),
                            ),
                          ),
                        ),
                      if (_isFromApi && _productDetail!.sku != null)
                        Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 20),
                          child: DisclosureRow(
                            label: 'SKU',
                            child: Text(
                              _productDetail!.sku!,
                              style: AppTypography.bodyMd
                                  .copyWith(color: AppColors.charcoal),
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
                        label: _stockQuantity > 0
                            ? 'Add to Bag  •  \$${(_price * _quantity).toStringAsFixed(0)}'
                            : 'Notify Me',
                        expand: true,
                        icon: _stockQuantity > 0
                            ? Icons.shopping_bag_outlined
                            : Icons.notifications_none,
                        onPressed: () {
                          if (_stockQuantity > 0) {
                            context.read<CartState>().add(
                              widget.product ?? Product(
                                id: _productDetail!.id,
                                name: _productDetail!.name,
                                subtitle: _productDetail!.categoryName ?? '',
                                categoryId: '',
                                petType: PetType.dog,
                                price: _productDetail!.price,
                                imageUrl: _productDetail!.primaryImageUrl ?? '',
                                images: _productDetail!.images.map((e) => e.imageUrl).toList(),
                                rating: 4.5,
                                reviewCount: 100,
                                brand: _productDetail!.brandName ?? '',
                                weightGrams: 0,
                                stock: _productDetail!.stockQuantity,
                              ),
                              qty: _quantity,
                            );
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
                                        'Added $_quantity × $_name to bag.',
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
                                content: const Text(
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
