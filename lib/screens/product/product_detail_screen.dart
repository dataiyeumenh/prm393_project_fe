import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../models/api/product_dto.dart';
import '../../models/api/review_dto.dart';
import '../../models/product.dart';
import '../../services/product_service.dart';
import '../../services/review_service.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/disclosure_row.dart';
import '../../widgets/primary_button.dart';
import '../../utils/formatters.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({super.key, this.product, this.productId});

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
  bool _loadingReviews = true;
  bool _postingReview = false;
  double _averageRating = 0;
  int _reviewTotalPages = 0;
  int _reviewCurrentPage = 0;
  List<ProductReviewDTO> _reviews = [];

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _loading = false;
      _loadReviews();
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
        _loadReviews();
      } else {
        setState(() {
          _error = result.error ?? 'Không tải được sản phẩm';
          _loading = false;
        });
      }
    }
  }

  bool get _isFromApi => widget.product == null && _productDetail != null;
  String get _name => _isFromApi ? _productDetail!.name : widget.product!.name;
  String? get _brandName =>
      _isFromApi ? _productDetail!.brandName : widget.product!.brand;
  double get _price =>
      _isFromApi ? _productDetail!.price : widget.product!.price;
  String get _description => _isFromApi
      ? (_productDetail!.description ?? '')
      : widget.product!.description;
  int get _stockQuantity =>
      _isFromApi ? _productDetail!.stockQuantity : widget.product!.stock;
  List<String> get _images {
    if (_isFromApi) {
      return _productDetail!.images.map((img) => img.imageUrl).toList();
    }
    return widget.product!.images;
  }

  String? get _subtitle =>
      _isFromApi ? _productDetail!.categoryName : widget.product!.subtitle;

  String? get _productId =>
      _isFromApi ? _productDetail?.id : widget.product?.id;

  Future<void> _loadReviews() async {
    final productId = _productId;
    if (productId == null || productId.isEmpty) {
      if (mounted) {
        setState(() {
          _loadingReviews = false;
          _reviews = [];
          _averageRating = 0;
          _reviewCurrentPage = 0;
          _reviewTotalPages = 0;
        });
      }
      return;
    }

    if (mounted) {
      setState(() => _loadingReviews = true);
    }

    final result = await ReviewService.getProductReviews(productId: productId);
    if (!mounted) return;

    if (result.isSuccess && result.data != null) {
      final page = result.data!;
      setState(() {
        _reviews = page.reviews;
        _averageRating = page.averageRating;
        _reviewCurrentPage = page.currentPage;
        _reviewTotalPages = page.totalPages;
        _loadingReviews = false;
      });
      return;
    }

    setState(() => _loadingReviews = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sale,
        content: Text(
          result.error ?? 'Không tải được đánh giá sản phẩm',
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

  Future<void> _openReviewComposer() async {
    if (_postingReview) return;
    final productId = _productId;
    if (productId == null || productId.isEmpty) return;

    final payload = await showModalBottomSheet<_CreateReviewPayload>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _CreateReviewSheet(),
    );
    if (payload == null) return;

    final uploads = <ReviewUploadImage>[];
    for (final file in payload.images) {
      uploads.add(
        ReviewUploadImage(bytes: await file.readAsBytes(), fileName: file.name),
      );
    }

    if (!mounted) return;
    setState(() => _postingReview = true);
    final result = await ReviewService.createReview(
      productId: productId,
      rating: payload.rating,
      comment: payload.comment,
      images: uploads,
    );
    if (!mounted) return;
    setState(() => _postingReview = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.success,
          content: Text(
            'Đánh giá của bạn đã được gửi',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      _loadReviews();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.sale,
        content: Text(
          result.error ?? 'Gửi đánh giá thất bại',
          style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
        ),
      ),
    );
  }

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
                child: const Text('Thử lại'),
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
                        icon: _favorite
                            ? Icons.favorite
                            : Icons.favorite_border,
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
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.lg,
                                    ),
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
                                style: AppTypography.bodyMd.copyWith(
                                  color: AppColors.mute,
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Text(
                                  Formatters.vnd(_price),
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
                                        ? AppColors.success.withValues(
                                            alpha: 0.1,
                                          )
                                        : AppColors.sale.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(
                                      AppRadius.full,
                                    ),
                                  ),
                                  child: Text(
                                    _stockQuantity > 0
                                        ? 'Còn $_stockQuantity sản phẩm'
                                        : 'Hết hàng',
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
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DisclosureRow(
                            label: 'Chi tiết sản phẩm',
                            initiallyOpen: true,
                            child: Text(
                              _description,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ),
                      if (_isFromApi && _productDetail!.sku != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: DisclosureRow(
                            label: 'SKU',
                            child: Text(
                              _productDetail!.sku!,
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.charcoal,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _ReviewSection(
                          loading: _loadingReviews,
                          posting: _postingReview,
                          averageRating: _averageRating,
                          reviews: _reviews,
                          currentPage: _reviewCurrentPage,
                          totalPages: _reviewTotalPages,
                          onWriteReview: _openReviewComposer,
                          onReload: _loadReviews,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: DisclosureRow(
                          label: 'Vận chuyển & đổi trả',
                          child: Text(
                            'Miễn phí vận chuyển cho đơn từ 1.250.000 ₫. Đổi trả trong 30 ngày, đơn giản nhanh chóng. '
                            'Thành viên được miễn phí vận chuyển nhanh cho mọi đơn hàng.',
                            style: AppTypography.bodyMd.copyWith(
                              color: AppColors.charcoal,
                            ),
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
                            ? 'Thêm vào giỏ'
                            : 'Báo khi có hàng',
                        expand: true,
                        icon: _stockQuantity > 0
                            ? Icons.shopping_bag_outlined
                            : Icons.notifications_none,
                        onPressed: () {
                          if (_stockQuantity > 0) {
                            context.read<CartState>().add(
                              widget.product ??
                                  Product(
                                    id: _productDetail!.id,
                                    name: _productDetail!.name,
                                    subtitle:
                                        _productDetail!.categoryName ?? '',
                                    categoryId: '',
                                    petType: PetType.dog,
                                    price: _productDetail!.price,
                                    imageUrl:
                                        _productDetail!.primaryImageUrl ?? '',
                                    images: _productDetail!.images
                                        .map((e) => e.imageUrl)
                                        .toList(),
                                    rating: _averageRating,
                                    reviewCount: _reviews.length,
                                    brand: _productDetail!.brandName ?? '',
                                    weightGrams: 0,
                                    stock: _productDetail!.stockQuantity,
                                  ),
                              qty: _quantity,
                            );
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Chúng tôi sẽ báo khi có hàng trở lại.',
                                ),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.lg,
                                  ),
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

class _ReviewSection extends StatelessWidget {
  const _ReviewSection({
    required this.loading,
    required this.posting,
    required this.averageRating,
    required this.reviews,
    required this.currentPage,
    required this.totalPages,
    required this.onWriteReview,
    required this.onReload,
  });

  final bool loading;
  final bool posting;
  final double averageRating;
  final List<ProductReviewDTO> reviews;
  final int currentPage;
  final int totalPages;
  final Future<void> Function() onWriteReview;
  final Future<void> Function() onReload;

  @override
  Widget build(BuildContext context) {
    return DisclosureRow(
      label: 'Đánh giá sản phẩm',
      initiallyOpen: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                averageRating.toStringAsFixed(1),
                style: AppTypography.headingLg,
              ),
              const SizedBox(width: 8),
              _StarDisplay(rating: averageRating),
              const SizedBox(width: 8),
              Text(
                '(${reviews.length})',
                style: AppTypography.captionMd.copyWith(color: AppColors.mute),
              ),
              const Spacer(),
              OutlinedButton.icon(
                onPressed: posting ? null : onWriteReview,
                icon: posting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.rate_review_outlined, size: 18),
                label: Text(posting ? 'Đang gửi...' : 'Viết review'),
              ),
            ],
          ),
          if (loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (reviews.isEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softCloud,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.reviews_outlined, color: AppColors.mute),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Chưa có đánh giá nào cho sản phẩm này.',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.charcoal,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Tải lại',
                      onPressed: onReload,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            const SizedBox(height: 10),
            ...reviews.map((r) => _ReviewCard(review: r)),
            if (totalPages > 1)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Trang ${currentPage + 1} / $totalPages',
                  style: AppTypography.captionSm.copyWith(
                    color: AppColors.mute,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ProductReviewDTO review;

  @override
  Widget build(BuildContext context) {
    final name = (review.userFullName?.trim().isNotEmpty ?? false)
        ? review.userFullName!
        : 'Người dùng';
    final dateLabel = review.createdAt == null
        ? ''
        : '${review.createdAt!.day.toString().padLeft(2, '0')}/${review.createdAt!.month.toString().padLeft(2, '0')}/${review.createdAt!.year}';

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.softCloud,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.hairlineSoft,
                backgroundImage: (review.userAvatarUrl?.isNotEmpty ?? false)
                    ? NetworkImage(review.userAvatarUrl!)
                    : null,
                child: (review.userAvatarUrl?.isNotEmpty ?? false)
                    ? null
                    : const Icon(Icons.person, size: 16, color: AppColors.mute),
              ),
              const SizedBox(width: 10),
              Expanded(child: Text(name, style: AppTypography.bodyStrong)),
              if (dateLabel.isNotEmpty)
                Text(
                  dateLabel,
                  style: AppTypography.captionSm.copyWith(
                    color: AppColors.mute,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _StarDisplay(rating: review.rating),
          if (review.comment.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: AppTypography.bodyMd.copyWith(color: AppColors.charcoal),
            ),
          ],
          if (review.imageUrls.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 82,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: review.imageUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final imageUrl = review.imageUrls[i];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 82,
                      height: 82,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => Container(
                        width: 82,
                        height: 82,
                        color: AppColors.hairlineSoft,
                        alignment: Alignment.center,
                        child: const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (_, _, _) => Container(
                        width: 82,
                        height: 82,
                        color: AppColors.hairlineSoft,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_not_supported_outlined,
                          color: AppColors.mute,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  const _StarDisplay({required this.rating, this.size = 16});

  final double rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final starIndex = i + 1;
        final icon = rating >= starIndex
            ? Icons.star_rounded
            : rating >= starIndex - 0.5
            ? Icons.star_half_rounded
            : Icons.star_border_rounded;
        return Icon(icon, size: size, color: AppColors.star);
      }),
    );
  }
}

class _CreateReviewPayload {
  const _CreateReviewPayload({
    required this.rating,
    required this.comment,
    required this.images,
  });

  final double rating;
  final String comment;
  final List<XFile> images;
}

class _CreateReviewSheet extends StatefulWidget {
  const _CreateReviewSheet();

  @override
  State<_CreateReviewSheet> createState() => _CreateReviewSheetState();
}

class _CreateReviewSheetState extends State<_CreateReviewSheet> {
  final _commentCtrl = TextEditingController();
  final _picker = ImagePicker();
  final List<XFile> _images = [];
  double _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picked = await _picker.pickMultiImage(
      imageQuality: 88,
      maxWidth: 1200,
    );
    if (picked.isEmpty) return;
    setState(() {
      _images.addAll(picked);
      if (_images.length > 5) {
        _images.removeRange(5, _images.length);
      }
    });
  }

  void _submit() {
    final comment = _commentCtrl.text.trim();
    if (comment.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập nội dung đánh giá'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    Navigator.of(context).pop(
      _CreateReviewPayload(rating: _rating, comment: comment, images: _images),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text('Viết review', style: AppTypography.headingLg),
              const SizedBox(height: 12),
              Text('Đánh giá của bạn', style: AppTypography.bodyStrong),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                children: List.generate(5, (i) {
                  final value = i + 1;
                  return IconButton(
                    onPressed: () => setState(() => _rating = value.toDouble()),
                    icon: Icon(
                      _rating >= value
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: AppColors.star,
                    ),
                  );
                }),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _commentCtrl,
                minLines: 4,
                maxLines: 6,
                decoration: const InputDecoration(
                  hintText: 'Chia sẻ cảm nhận của bạn về sản phẩm...',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImages,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text('Thêm ảnh (${_images.length}/5)'),
                  ),
                ],
              ),
              if (_images.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: SizedBox(
                    height: 70,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _images.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 8),
                      itemBuilder: (_, i) {
                        final img = _images[i];
                        return Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: FutureBuilder(
                                future: img.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState !=
                                      ConnectionState.done) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.hairlineSoft,
                                      alignment: Alignment.center,
                                      child: const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    );
                                  }

                                  final bytes = snapshot.data;
                                  if (bytes == null) {
                                    return Container(
                                      width: 70,
                                      height: 70,
                                      color: AppColors.hairlineSoft,
                                      alignment: Alignment.center,
                                      child: const Icon(Icons.image_outlined),
                                    );
                                  }

                                  return Image.memory(
                                    bytes,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              top: -6,
                              right: -6,
                              child: IconButton(
                                onPressed: () =>
                                    setState(() => _images.removeAt(i)),
                                icon: const Icon(
                                  Icons.cancel,
                                  size: 18,
                                  color: AppColors.sale,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: PrimaryButton(
                  label: _submitting ? 'Đang xử lý...' : 'Gửi đánh giá',
                  onPressed: _submitting ? null : _submit,
                  expand: true,
                  icon: Icons.send_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
