import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/api/admin_dto.dart';
import '../../../models/api/brand_dto.dart';
import '../../../models/api/category_dto.dart';
import '../../../services/admin_service.dart';
import '../../../services/brand_service.dart';
import '../../../services/category_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../admin_shell.dart';

class AdminWarehouseScreen extends StatefulWidget {
  const AdminWarehouseScreen({super.key});

  @override
  State<AdminWarehouseScreen> createState() => _AdminWarehouseScreenState();
}

class _AdminWarehouseScreenState extends State<AdminWarehouseScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  List<AdminWarehouseProductDTO> _products = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 0;
  String? _error;
  String _search = '';

  // Metadata loaded once
  List<CategoryDTO> _categories = [];
  List<BrandDTO> _brands = [];

  // Filters (client-side): categoryId/brandId for exact match, level computed
  int? _filterCategoryId;
  int? _filterBrandId;
  StockLevel? _filterLevel;

  static const _pageSize = 20;

  List<AdminWarehouseProductDTO> get _filteredProducts {
    var list = _products;
    if (_filterBrandId != null) {
      list = list.where((p) => p.brandId == _filterBrandId).toList();
    }
    if (_filterCategoryId != null) {
      list = list.where((p) => p.categoryId == _filterCategoryId).toList();
    }
    if (_filterLevel != null) {
      list = list.where((p) => p.stockLevel == _filterLevel).toList();
    }
    return list;
  }

  bool get _hasActiveFilter =>
      _filterBrandId != null ||
      _filterCategoryId != null ||
      _filterLevel != null;

  String? _categoryName(int id) =>
      _categories.where((c) => c.id == id).firstOrNull?.name;

  String? _brandName(int id) =>
      _brands.where((b) => b.id == id).firstOrNull?.name;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch(reset: true);
    _loadMetadata();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
            _scrollCtrl.position.maxScrollExtent - 100 &&
        !_loading &&
        _hasMore) {
      _fetch();
    }
  }

  Future<void> _loadMetadata() async {
    final results = await Future.wait([
      CategoryService.getAllCategories(),
      BrandService.getAllBrands(),
    ]);
    final catResult = results[0] as dynamic;
    final brandResult = results[1] as dynamic;
    debugPrint(
      '[Warehouse] Category result: success=${catResult.isSuccess}, count=${catResult.data?.length ?? 0}, error=${catResult.error}',
    );
    debugPrint(
      '[Warehouse] Brand result: success=${brandResult.isSuccess}, count=${brandResult.data?.length ?? 0}, error=${brandResult.error}',
    );
    if (!mounted) return;
    setState(() {
      if (catResult.isSuccess && catResult.data != null) {
        _categories = catResult.data!;
      }
      if (brandResult.isSuccess && brandResult.data != null) {
        _brands = brandResult.data!;
      }
      _hydrateMetadataFromProducts(_products);
    });
  }

  void _hydrateMetadataFromProducts(List<AdminWarehouseProductDTO> products) {
    if (_categories.isNotEmpty && _brands.isNotEmpty) return;

    final categoryMap = <int, CategoryDTO>{
      for (final c in _categories) c.id: c,
    };
    final brandMap = <int, BrandDTO>{for (final b in _brands) b.id: b};

    for (final p in products) {
      if (p.categoryId != null &&
          p.categoryName != null &&
          p.categoryName!.isNotEmpty) {
        categoryMap.putIfAbsent(
          p.categoryId!,
          () => CategoryDTO(id: p.categoryId!, name: p.categoryName!),
        );
      }
      if (p.brandId != null && p.brandName != null && p.brandName!.isNotEmpty) {
        brandMap.putIfAbsent(
          p.brandId!,
          () => BrandDTO(id: p.brandId!, name: p.brandName!),
        );
      }
    }

    _categories = categoryMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    _brands = brandMap.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  Future<void> _fetch({bool reset = false}) async {
    if (!reset && (!_hasMore || _loading)) return;
    setState(() {
      _loading = true;
      if (reset) _error = null;
    });

    final page = reset ? 0 : _page;
    final result = await AdminService.getWarehouseProducts(
      page: page,
      size: _pageSize,
      search: _search.isEmpty ? null : _search,
    );

    if (!mounted) return;
    setState(() {
      if (result.isSuccess && result.data != null) {
        final items = result.data!.content;
        _products = reset ? items : [..._products, ...items];
        _hydrateMetadataFromProducts(_products);
        _hasMore = !result.data!.last;
        _page = page + 1;
        _error = null;
      } else {
        _error = result.error;
        if (reset) _products = [];
      }
      _loading = false;
    });
  }

  void _onSearchSubmit(String val) {
    _search = val.trim();
    _fetch(reset: true);
  }

  Future<void> _openProductCreator() async {
    final result = await showModalBottomSheet<_ProductCreateResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _ProductCreateSheet(categories: _categories, brands: _brands),
    );
    if (result == null) return;

    MultipartFile? imageFile;
    if (result.imageBytes != null && result.imageFileName != null) {
      imageFile = MultipartFile.fromBytes(
        result.imageBytes!,
        filename: result.imageFileName,
      );
    }

    final createResult = await AdminService.createProduct(
      result.product,
      image: imageFile,
    );

    if (!mounted) return;
    if (createResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Tạo sản phẩm thành công',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      _fetch(reset: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.sale,
          behavior: SnackBarBehavior.floating,
          content: Text(
            createResult.error ?? 'Tạo sản phẩm thất bại',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
    }
  }

  Future<void> _openProductEditor(AdminWarehouseProductDTO product) async {
    final result = await showModalBottomSheet<_ProductEditResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductEditSheet(
        product: product,
        categories: _categories,
        brands: _brands,
      ),
    );
    if (result == null) return;

    MultipartFile? imageFile;
    if (result.imageBytes != null && result.imageFileName != null) {
      imageFile = MultipartFile.fromBytes(
        result.imageBytes!,
        filename: result.imageFileName,
      );
    }

    if (result.updates.isEmpty && imageFile == null) return;

    final updateResult = await AdminService.updateProduct(
      product.id,
      result.updates,
      image: imageFile,
    );
    if (!mounted) return;
    if (updateResult.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Cập nhật sản phẩm thành công',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      // Refresh the list to reflect changes
      _fetch(reset: true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.sale,
          behavior: SnackBarBehavior.floating,
          content: Text(
            updateResult.error ?? 'Cập nhật sản phẩm thất bại',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
    }
  }

  Future<void> _confirmDelete(AdminWarehouseProductDTO product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá sản phẩm?'),
        content: Text(
          'Bạn chắc chắn muốn xoá "${product.name}"? Hành động này không thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Huỷ'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.sale),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final result = await AdminService.deleteProduct(product.id);
    if (!mounted) return;
    if (result.isSuccess) {
      setState(() => _products.removeWhere((p) => p.id == product.id));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${product.name} đã được xoá',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.sale,
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.error ?? 'Xoá sản phẩm thất bại',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
    }
  }

  Color _stockColor(StockLevel level) {
    switch (level) {
      case StockLevel.outOfStock:
        return AppColors.sale;
      case StockLevel.low:
        return AppColors.saleDeep;
      case StockLevel.medium:
        return const Color(0xFFFF9A45);
      case StockLevel.good:
        return AppColors.success;
    }
  }

  Color _stockBg(StockLevel level) =>
      _stockColor(level).withValues(alpha: 0.12);

  Future<void> _openFilterSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        brands: _brands,
        categories: _categories,
        selectedBrandId: _filterBrandId,
        selectedCategoryId: _filterCategoryId,
        selectedLevel: _filterLevel,
        onApply: (brandId, categoryId, level) {
          setState(() {
            _filterBrandId = brandId;
            _filterCategoryId = categoryId;
            _filterLevel = level;
          });
          Navigator.of(context).pop();
        },
        onClear: () {
          setState(() {
            _filterBrandId = null;
            _filterCategoryId = null;
            _filterLevel = null;
          });
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredProducts;
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(subtitle: 'Trang quản trị', title: 'Kho hàng'),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _openProductCreator,
        backgroundColor: AppColors.ink,
        foregroundColor: AppColors.onPrimary,
        tooltip: 'Thêm sản phẩm',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          // Search + filter row
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    onSubmitted: _onSearchSubmit,
                    textInputAction: TextInputAction.search,
                    style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
                    decoration: InputDecoration(
                      hintText: 'Tìm sản phẩm…',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.mute,
                      ),
                      suffixIcon: _search.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: AppColors.mute,
                              ),
                              onPressed: () {
                                _searchCtrl.clear();
                                _search = '';
                                _fetch(reset: true);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Filter button
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    IconButton(
                      onPressed: _openFilterSheet,
                      icon: Icon(
                        Icons.tune_rounded,
                        color: _hasActiveFilter
                            ? AppColors.accentPinkDeep
                            : AppColors.mute,
                      ),
                      tooltip: 'Bộ lọc',
                    ),
                    if (_hasActiveFilter)
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.accentPinkDeep,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Active filter chips
          if (_hasActiveFilter)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  if (_filterLevel != null)
                    _FilterChip(
                      label: _filterLevel!.label,
                      onRemove: () => setState(() => _filterLevel = null),
                    ),
                  if (_filterBrandId != null)
                    _FilterChip(
                      label:
                          _brandName(_filterBrandId!) ??
                          'Thương hiệu ${_brandName(_filterBrandId!) ?? ''}',
                      onRemove: () => setState(() => _filterBrandId = null),
                    ),
                  if (_filterCategoryId != null)
                    _FilterChip(
                      label:
                          _categoryName(_filterCategoryId!) ??
                          'Danh mục ${_categoryName(_filterCategoryId!) ?? ''}',
                      onRemove: () => setState(() => _filterCategoryId = null),
                    ),
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => setState(() {
                      _filterBrandId = null;
                      _filterCategoryId = null;
                      _filterLevel = null;
                    }),
                    child: Text(
                      'Xoá hết bộ lọc',
                      style: AppTypography.utilityXs.copyWith(
                        color: AppColors.sale,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          Expanded(
            child: _error != null && _products.isEmpty
                ? _WarehouseError(
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetch(reset: true),
                    color: AppColors.accentPinkDeep,
                    child: filtered.isEmpty && !_loading
                        ? const _EmptyWarehouse()
                        : ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount:
                                filtered.length +
                                (_hasMore && !_hasActiveFilter ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              if (i == filtered.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final p = filtered[i];
                              return _ProductStockCard(
                                product: p,
                                stockColor: _stockColor(p.stockLevel),
                                stockBg: _stockBg(p.stockLevel),
                                onEdit: () => _openProductEditor(p),
                                onDelete: () => _confirmDelete(p),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _ProductStockCard extends StatefulWidget {
  const _ProductStockCard({
    required this.product,
    required this.stockColor,
    required this.stockBg,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminWarehouseProductDTO product;
  final Color stockColor;
  final Color stockBg;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  State<_ProductStockCard> createState() => _ProductStockCardState();
}

class _ProductStockCardState extends State<_ProductStockCard>
    with SingleTickerProviderStateMixin {
  static const double _actionWidth = 140.0; // width of the two action buttons
  late AnimationController _animCtrl;
  late Animation<double> _offsetAnim;
  double _dragStartX = 0;
  bool _isOpen = false;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _offsetAnim = Tween<double>(
      begin: 0,
      end: -_actionWidth,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  void _open() {
    _animCtrl.forward();
    setState(() => _isOpen = true);
  }

  void _close() {
    _animCtrl.reverse();
    setState(() => _isOpen = false);
  }

  void _toggle() => _isOpen ? _close() : _open();

  void _onDragStart(DragStartDetails d) {
    _dragStartX = d.globalPosition.dx;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition.dx - _dragStartX;
    if (delta > 0 && !_isOpen) return; // ignore right-swipe when closed
    final current = _isOpen ? -_actionWidth : 0.0;
    final newOffset = (current + delta).clamp(-_actionWidth, 0.0);
    _animCtrl.value = (-newOffset) / _actionWidth;
  }

  void _onDragEnd(DragEndDetails d) {
    final offset = -_offsetAnim.value;
    if (offset > _actionWidth * 0.4) {
      _open();
    } else {
      _close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final level = widget.product.stockLevel;
    final product = widget.product;

    return GestureDetector(
      onLongPress: _toggle,
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: Stack(
        children: [
          // ── Action buttons (behind the card) ──
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Row(
                  children: [
                    // Update button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _close();
                          widget.onEdit();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.accentPinkDeep.withValues(
                              alpha: 0.15,
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(AppRadius.md),
                              bottomLeft: Radius.circular(AppRadius.md),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.edit_outlined,
                                color: AppColors.accentPinkDeep,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Sửa',
                                style: AppTypography.utilityXs.copyWith(
                                  color: AppColors.accentPinkDeep,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Delete button
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _close();
                          widget.onDelete();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.sale.withValues(alpha: 0.15),
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(AppRadius.md),
                              bottomRight: Radius.circular(AppRadius.md),
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                color: AppColors.sale,
                                size: 22,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Xoá',
                                style: AppTypography.utilityXs.copyWith(
                                  color: AppColors.sale,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Card (slides left on gesture) ──
          AnimatedBuilder(
            animation: _offsetAnim,
            builder: (_, child) => Transform.translate(
              offset: Offset(_offsetAnim.value, 0),
              child: child,
            ),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.canvas,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(
                  color: level == StockLevel.outOfStock
                      ? AppColors.sale.withValues(alpha: 0.4)
                      : AppColors.hairlineSoft,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x04000000),
                    blurRadius: 8,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Product image
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: AppColors.softCloud,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: product.primaryImageUrl != null
                        ? Image.network(
                            product.primaryImageUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.inventory_2_outlined,
                              color: AppColors.mute,
                              size: 22,
                            ),
                          )
                        : const Icon(
                            Icons.inventory_2_outlined,
                            color: AppColors.mute,
                            size: 22,
                          ),
                  ),
                  const SizedBox(width: 12),
                  // Product info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: AppTypography.captionMd.copyWith(
                            color: AppColors.ink,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            if (product.brandName != null) ...[
                              Text(
                                product.brandName!,
                                style: AppTypography.utilityXs.copyWith(
                                  color: AppColors.mute,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 3,
                                height: 3,
                                decoration: const BoxDecoration(
                                  color: AppColors.stone,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Text(
                              Formatters.vnd(product.price),
                              style: AppTypography.utilityXs.copyWith(
                                color: AppColors.mute,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.stockBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                '${product.stockQuantity} trong kho',
                                style: AppTypography.utilityXs.copyWith(
                                  color: widget.stockColor,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.stockBg,
                                borderRadius: BorderRadius.circular(
                                  AppRadius.full,
                                ),
                              ),
                              child: Text(
                                level.viLabel,
                                style: AppTypography.utilityXs.copyWith(
                                  color: widget.stockColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Swipe hint icon
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      size: 20,
                      color: AppColors.mute.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCreateResult {
  const _ProductCreateResult({
    required this.product,
    this.imageBytes,
    this.imageFileName,
  });

  final Map<String, dynamic> product;
  final Uint8List? imageBytes;
  final String? imageFileName;
}

class _ProductEditResult {
  const _ProductEditResult({
    required this.updates,
    this.imageBytes,
    this.imageFileName,
  });

  final Map<String, dynamic> updates;
  final Uint8List? imageBytes;
  final String? imageFileName;
}

class _ProductCreateSheet extends StatefulWidget {
  const _ProductCreateSheet({required this.categories, required this.brands});

  final List<CategoryDTO> categories;
  final List<BrandDTO> brands;

  @override
  State<_ProductCreateSheet> createState() => _ProductCreateSheetState();
}

class _ProductCreateSheetState extends State<_ProductCreateSheet> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _skuCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();
  final _categoryIdCtrl = TextEditingController();
  final _brandIdCtrl = TextEditingController();

  final _picker = ImagePicker();

  int? _selectedCategoryId;
  int? _selectedBrandId;
  Uint8List? _imageBytes;
  String? _imageFileName;
  String? _error;
  bool _pickingImage = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _skuCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryIdCtrl.dispose();
    _brandIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFileName = file.name;
      });
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final sku = _skuCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    final categoryId =
        _selectedCategoryId ?? int.tryParse(_categoryIdCtrl.text.trim());
    final brandId = _selectedBrandId ?? int.tryParse(_brandIdCtrl.text.trim());

    if (name.isEmpty) {
      setState(() => _error = 'Vui lòng nhập tên sản phẩm');
      return;
    }
    if (price == null || price < 0) {
      setState(() => _error = 'Vui lòng nhập giá hợp lệ');
      return;
    }
    if (stock == null || stock < 0) {
      setState(() => _error = 'Vui lòng nhập số lượng tồn kho hợp lệ');
      return;
    }
    if (_selectedCategoryId == null) {
      setState(() => _error = 'Vui lòng chọn danh mục');
      return;
    }
    if (_selectedBrandId == null) {
      setState(() => _error = 'Vui lòng chọn thương hiệu');
      return;
    }

    final product = <String, dynamic>{
      'name': name,
      'description': description,
      'price': price,
      'stock': stock,
      'categoryId': categoryId,
      'brandId': brandId,
      if (sku.isNotEmpty) 'sku': sku,
    };

    Navigator.of(context).pop(
      _ProductCreateResult(
        product: product,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasCategories = widget.categories.isNotEmpty;
    final hasBrands = widget.brands.isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Thêm sản phẩm',
                  style: AppTypography.headingMd.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tạo sản phẩm mới và có thể tải ảnh đại diện lên.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _skuCtrl,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã SKU (không bắt buộc)',
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Giá *',
                          prefixText: '₫ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tồn kho *',
                          suffixText: 'sp',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedCategoryId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Danh mục *'),
                  hint: Text(
                    hasCategories
                        ? 'Chọn danh mục'
                        : 'Chưa có danh mục nào',
                  ),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _categoryIdCtrl.text = value?.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<int>(
                  initialValue: _selectedBrandId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Thương hiệu *'),
                  hint: Text(
                    hasBrands ? 'Chọn thương hiệu' : 'Chưa có thương hiệu nào',
                  ),
                  items: widget.brands
                      .map(
                        (b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBrandId = value;
                      _brandIdCtrl.text = value?.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _pickingImage
                        ? 'Đang chọn ảnh...'
                        : 'Chọn ảnh đại diện',
                  ),
                ),
                if (_imageFileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageFileName!,
                    style: AppTypography.utilityXs.copyWith(
                      color: AppColors.mute,
                    ),
                  ),
                ],
                if (_imageBytes != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    child: Image.memory(
                      _imageBytes!,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: AppTypography.captionMd.copyWith(
                      color: AppColors.sale,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: _save,
                        child: const Text('Tạo mới'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProductEditSheet extends StatefulWidget {
  const _ProductEditSheet({
    required this.product,
    required this.categories,
    required this.brands,
  });
  final AdminWarehouseProductDTO product;
  final List<CategoryDTO> categories;
  final List<BrandDTO> brands;

  @override
  State<_ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<_ProductEditSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _stockCtrl;
  late final TextEditingController _categoryIdCtrl;
  late final TextEditingController _brandIdCtrl;
  final _picker = ImagePicker();

  int? _selectedCategoryId;
  int? _selectedBrandId;
  Uint8List? _imageBytes;
  String? _imageFileName;
  bool _pickingImage = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.name);
    _descCtrl = TextEditingController(text: widget.product.description ?? '');
    _priceCtrl = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );
    _stockCtrl = TextEditingController(text: '${widget.product.stockQuantity}');
    _categoryIdCtrl = TextEditingController(
      text: widget.product.categoryId?.toString() ?? '',
    );
    _brandIdCtrl = TextEditingController(
      text: widget.product.brandId?.toString() ?? '',
    );
    _selectedCategoryId = widget.product.categoryId;
    _selectedBrandId = widget.product.brandId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _stockCtrl.dispose();
    _categoryIdCtrl.dispose();
    _brandIdCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final description = _descCtrl.text.trim();
    final price = double.tryParse(_priceCtrl.text.trim());
    final stock = int.tryParse(_stockCtrl.text.trim());
    final categoryId =
        _selectedCategoryId ?? int.tryParse(_categoryIdCtrl.text.trim());
    final brandId = _selectedBrandId ?? int.tryParse(_brandIdCtrl.text.trim());
    if (name.isEmpty || price == null || stock == null) return;

    final updates = <String, dynamic>{};
    if (name != widget.product.name) updates['name'] = name;

    final oldDescription = (widget.product.description ?? '').trim();
    if (description != oldDescription) updates['description'] = description;

    if ((price - widget.product.price).abs() > 0.0001) {
      updates['price'] = price;
    }

    if (stock != widget.product.stockQuantity) {
      updates['stock'] = stock;
    }

    if (categoryId != widget.product.categoryId && categoryId != null) {
      updates['categoryId'] = categoryId;
    }

    if (brandId != widget.product.brandId && brandId != null) {
      updates['brandId'] = brandId;
    }

    Navigator.of(context).pop(
      _ProductEditResult(
        updates: updates,
        imageBytes: _imageBytes,
        imageFileName: _imageFileName,
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_pickingImage) return;
    setState(() => _pickingImage = true);
    try {
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 1800,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _imageBytes = bytes;
        _imageFileName = file.name;
      });
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryValue =
        widget.categories.any((c) => c.id == _selectedCategoryId)
        ? _selectedCategoryId
        : null;
    final brandValue = widget.brands.any((b) => b.id == _selectedBrandId)
        ? _selectedBrandId
        : null;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.canvas,
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(AppRadius.lg),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.hairline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Cập nhật sản phẩm',
                  style: AppTypography.headingMd.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(
                  'SKU: ${widget.product.sku ?? '—'}',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                ),
                const SizedBox(height: 20),
                // Name
                TextField(
                  controller: _nameCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    labelText: 'Tên sản phẩm *',
                  ),
                ),
                const SizedBox(height: 14),
                // Description
                TextField(
                  controller: _descCtrl,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Mô tả',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 14),
                // Price + Stock
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _priceCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*\.?\d{0,2}'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Giá *',
                          prefixText: '₫ ',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextField(
                        controller: _stockCtrl,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Tồn kho *',
                          suffixText: 'sp',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Category dropdown
                DropdownButtonFormField<int>(
                  initialValue: categoryValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Danh mục'),
                  hint: Text(
                    widget.categories.isNotEmpty
                        ? 'Chọn danh mục'
                        : 'Chưa có danh mục nào',
                  ),
                  items: widget.categories
                      .map(
                        (c) => DropdownMenuItem<int>(
                          value: c.id,
                          child: Text(c.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                      _categoryIdCtrl.text = value?.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                // Brand dropdown
                DropdownButtonFormField<int>(
                  initialValue: brandValue,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Thương hiệu'),
                  hint: Text(
                    widget.brands.isNotEmpty
                        ? 'Chọn thương hiệu'
                        : 'Chưa có thương hiệu nào',
                  ),
                  items: widget.brands
                      .map(
                        (b) => DropdownMenuItem<int>(
                          value: b.id,
                          child: Text(b.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBrandId = value;
                      _brandIdCtrl.text = value?.toString() ?? '';
                    });
                  },
                ),
                const SizedBox(height: 14),
                OutlinedButton.icon(
                  onPressed: _pickingImage ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  label: Text(
                    _pickingImage
                        ? 'Picking image...'
                        : 'Choose new thumbnail image',
                  ),
                ),
                if (_imageFileName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageFileName!,
                    style: AppTypography.utilityXs.copyWith(
                      color: AppColors.mute,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  child: _imageBytes != null
                      ? Image.memory(
                          _imageBytes!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : widget.product.primaryImageUrl != null
                      ? Image.network(
                          widget.product.primaryImageUrl!,
                          height: 120,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: AppColors.ash.withValues(alpha: 0.16),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.image_outlined,
                            color: AppColors.mute.withValues(alpha: 0.6),
                          ),
                        ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Huỷ'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.ink,
                          foregroundColor: AppColors.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.full),
                          ),
                        ),
                        onPressed: _save,
                        child: const Text('Lưu'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyWarehouse extends StatelessWidget {
  const _EmptyWarehouse();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Column(
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 64,
              color: AppColors.hairline,
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa tìm thấy sản phẩm',
              style: AppTypography.headingMd.copyWith(color: AppColors.ash),
            ),
          ],
        ),
      ],
    );
  }
}

class _WarehouseError extends StatelessWidget {
  const _WarehouseError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: AppColors.sale),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            ),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
// ─────────────────────────────────────────────────────────────────────────────
// Filter chip (active filter badge in the row)
// ─────────────────────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentPink.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.accentPinkDeep.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.utilityXs.copyWith(
              color: AppColors.accentPinkDeep,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              size: 14,
              color: AppColors.accentPinkDeep,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter bottom sheet
// ─────────────────────────────────────────────────────────────────────────────

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.brands,
    required this.categories,
    required this.selectedBrandId,
    required this.selectedCategoryId,
    required this.selectedLevel,
    required this.onApply,
    required this.onClear,
  });

  final List<BrandDTO> brands;
  final List<CategoryDTO> categories;
  final int? selectedBrandId;
  final int? selectedCategoryId;
  final StockLevel? selectedLevel;
  final void Function(int? brandId, int? categoryId, StockLevel? level) onApply;
  final VoidCallback onClear;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _brandId;
  int? _categoryId;
  StockLevel? _level;

  @override
  void initState() {
    super.initState();
    _brandId = widget.selectedBrandId;
    _categoryId = widget.selectedCategoryId;
    _level = widget.selectedLevel;
  }

  static const _levelColors = {
    StockLevel.outOfStock: AppColors.sale,
    StockLevel.low: AppColors.saleDeep,
    StockLevel.medium: Color(0xFFFF9A45),
    StockLevel.good: AppColors.success,
  };

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.88;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Lọc sản phẩm',
                style: AppTypography.headingMd.copyWith(color: AppColors.ink),
              ),
              const SizedBox(height: 20),

              // ── Stock Level ──
              Text(
                'Mức tồn kho',
                style: AppTypography.captionMd.copyWith(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in StockLevel.values) _buildLevelChip(level),
                ],
              ),
              const SizedBox(height: 20),

              // ── Category ──
              if (widget.categories.isNotEmpty) ...[
                Text(
                  'Danh mục',
                  style: AppTypography.captionMd.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in widget.categories)
                      _buildIdChip(
                        label: c.name,
                        id: c.id,
                        selectedId: _categoryId,
                        onTap: (v) => setState(() => _categoryId = v),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── Brand ──
              if (widget.brands.isNotEmpty) ...[
                Text(
                  'Thương hiệu',
                  style: AppTypography.captionMd.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final b in widget.brands)
                      _buildIdChip(
                        label: b.name,
                        id: b.id,
                        selectedId: _brandId,
                        onTap: (v) => setState(() => _brandId = v),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
              ],

              // ── Actions ──
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.onClear,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.sale,
                        side: BorderSide(
                          color: AppColors.sale.withValues(alpha: 0.5),
                        ),
                      ),
                      child: const Text('Đặt lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.ink,
                        foregroundColor: AppColors.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.full),
                        ),
                      ),
                      onPressed: () =>
                          widget.onApply(_brandId, _categoryId, _level),
                      child: const Text('Áp dụng'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLevelChip(StockLevel level) {
    final selected = _level == level;
    final color = _levelColors[level] ?? AppColors.mute;
    return GestureDetector(
      onTap: () => setState(() => _level = selected ? null : level),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : AppColors.softCloud,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: selected ? color : AppColors.hairline,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          level.viLabel,
          style: AppTypography.utilityXs.copyWith(
            color: selected ? color : AppColors.ash,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildIdChip({
    required String label,
    required int id,
    required int? selectedId,
    required void Function(int?) onTap,
  }) {
    final isSelected = selectedId == id;
    return GestureDetector(
      onTap: () => onTap(isSelected ? null : id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentPink.withValues(alpha: 0.14)
              : AppColors.softCloud,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? AppColors.accentPinkDeep.withValues(alpha: 0.5)
                : AppColors.hairline,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: AppTypography.utilityXs.copyWith(
            color: isSelected ? AppColors.accentPinkDeep : AppColors.ash,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
