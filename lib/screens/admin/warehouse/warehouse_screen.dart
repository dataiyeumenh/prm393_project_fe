import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../models/api/admin_dto.dart';
import '../../../services/admin_service.dart';
import '../../../theme/app_theme.dart';
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

  static const _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch(reset: true);
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

  Future<void> _openStockEditor(AdminWarehouseProductDTO product) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _StockEditSheet(product: product),
    );
    if (result != null && result != product.stockQuantity) {
      final updateResult = await AdminService.updateProductStock(
        product.id,
        result,
      );
      if (!mounted) return;
      if (updateResult.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            content: Text(
              'Stock updated to $result units',
              style: AppTypography.captionMd.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        );
        // Refresh the product in the list locally
        setState(() {
          final idx = _products.indexWhere((p) => p.id == product.id);
          if (idx >= 0) {
            _products[idx] = AdminWarehouseProductDTO(
              id: product.id,
              name: product.name,
              sku: product.sku,
              price: product.price,
              stockQuantity: result,
              categoryName: product.categoryName,
              brandName: product.brandName,
              primaryImageUrl: product.primaryImageUrl,
            );
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sale,
            behavior: SnackBarBehavior.floating,
            content: Text(
              updateResult.error ?? 'Failed to update stock',
              style: AppTypography.captionMd.copyWith(
                color: AppColors.onPrimary,
              ),
            ),
          ),
        );
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(subtitle: 'Admin Panel', title: 'Warehouse'),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchCtrl,
              onSubmitted: _onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: 'Search products…',
                prefixIcon: const Icon(Icons.search, color: AppColors.mute),
                suffixIcon: _search.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: AppColors.mute),
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
          const Divider(height: 1),
          // Summary banner
          if (!_loading && _products.isNotEmpty)
            _StockSummaryBanner(products: _products),
          Expanded(
            child: _error != null && _products.isEmpty
                ? _WarehouseError(
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetch(reset: true),
                    color: AppColors.accentPinkDeep,
                    child: _products.isEmpty && !_loading
                        ? const _EmptyWarehouse()
                        : ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _products.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              if (i == _products.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              final p = _products[i];
                              return _ProductStockCard(
                                product: p,
                                stockColor: _stockColor(p.stockLevel),
                                stockBg: _stockBg(p.stockLevel),
                                onEdit: () => _openStockEditor(p),
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

class _StockSummaryBanner extends StatelessWidget {
  const _StockSummaryBanner({required this.products});
  final List<AdminWarehouseProductDTO> products;

  @override
  Widget build(BuildContext context) {
    final outOfStock = products
        .where((p) => p.stockLevel == StockLevel.outOfStock)
        .length;
    final low = products.where((p) => p.stockLevel == StockLevel.low).length;

    if (outOfStock == 0 && low == 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.sale.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.saleDeep,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                if (outOfStock > 0) '$outOfStock out of stock',
                if (low > 0) '$low low stock',
              ].join(' · '),
              style: AppTypography.captionSm.copyWith(
                color: AppColors.saleDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductStockCard extends StatelessWidget {
  const _ProductStockCard({
    required this.product,
    required this.stockColor,
    required this.stockBg,
    required this.onEdit,
  });

  final AdminWarehouseProductDTO product;
  final Color stockColor;
  final Color stockBg;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final currFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);
    final level = product.stockLevel;

    return Container(
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
                    errorBuilder: (_, __, ___) => const Icon(
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
                  style: AppTypography.captionMd.copyWith(color: AppColors.ink),
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
                      currFmt.format(product.price),
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
                        color: stockBg,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        '${product.stockQuantity} in stock',
                        style: AppTypography.utilityXs.copyWith(
                          color: stockColor,
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
                        color: stockBg,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        level.label,
                        style: AppTypography.utilityXs.copyWith(
                          color: stockColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          GestureDetector(
            onTap: onEdit,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentPink.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(
                Icons.edit_outlined,
                size: 18,
                color: AppColors.accentPinkDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StockEditSheet extends StatefulWidget {
  const _StockEditSheet({required this.product});
  final AdminWarehouseProductDTO product;

  @override
  State<_StockEditSheet> createState() => _StockEditSheetState();
}

class _StockEditSheetState extends State<_StockEditSheet> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: '${widget.product.stockQuantity}');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppRadius.lg),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
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
              'Update Stock',
              style: AppTypography.headingMd.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            Text(
              widget.product.name,
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Stock quantity',
                suffixText: 'units',
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
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
                    onPressed: () {
                      final val = int.tryParse(_ctrl.text.trim());
                      if (val != null) Navigator.of(context).pop(val);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
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
              'No products found',
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
            OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
