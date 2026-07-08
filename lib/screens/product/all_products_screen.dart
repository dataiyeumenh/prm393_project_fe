import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api/product_dto.dart';
import '../../services/product_service.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chip_pill.dart';
import '../../widgets/app_background.dart';
import '../../widgets/scroll_to_top_fab.dart';
import '../../utils/formatters.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.initialCategoryId, this.categoryName});

  final int? initialCategoryId;
  final String? categoryName;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

enum _SortOption { featured, priceLow, priceHigh }

extension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.featured:
        return 'Nổi bật';
      case _SortOption.priceLow:
        return 'Giá tăng dần';
      case _SortOption.priceHigh:
        return 'Giá giảm dần';
    }
  }

  String get apiSortBy {
    switch (this) {
      case _SortOption.featured:
        return 'createdAt';
      case _SortOption.priceLow:
        return 'price';
      case _SortOption.priceHigh:
        return 'price';
    }
  }

  String get apiSortDir {
    switch (this) {
      case _SortOption.featured:
        return 'DESC';
      case _SortOption.priceLow:
        return 'ASC';
      case _SortOption.priceHigh:
        return 'DESC';
    }
  }
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  static const int _pageSize = 10;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  int? _selectedCategoryId;
  _SortOption _sort = _SortOption.featured;
  bool _showScrollTop = false;
  
  List<ProductSummaryDTO> _products = [];
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  int _currentPage = 0;
  int _totalElements = 0;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.initialCategoryId;
    _scrollCtrl.addListener(_onScroll);
    _loadProducts(reset: true);
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 240;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  Future<void> _loadProducts({bool reset = false}) async {
    if (_loading && !reset) return;
    
    setState(() {
      if (reset) {
        _loading = true;
        _products = [];
        _currentPage = 0;
      }
    });

    final result = await ProductService.getProducts(
      categoryId: _selectedCategoryId,
      page: reset ? 0 : _currentPage,
      size: _pageSize,
      sortBy: _sort.apiSortBy,
      sortDir: _sort.apiSortDir,
    );

    if (mounted && result.isSuccess && result.data != null) {
      setState(() {
        if (reset) {
          _products = result.data!.content;
        } else {
          _products.addAll(result.data!.content);
        }
        _hasMore = !result.data!.last;
        _totalElements = result.data!.totalElements;
        _loading = false;
        _loadingMore = false;
      });
    } else {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadingMore = false;
        });
      }
    }
  }

  void _loadMore() {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    _currentPage++;
    _loadProducts();
  }

  void _onFilterChange() {
    setState(() {
      _currentPage = 0;
      _hasMore = true;
    });
    _loadProducts(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _selectedCategoryId = null;
      _sort = _SortOption.featured;
    });
    _onFilterChange();
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _FilterSheet(
        selectedCategoryId: _selectedCategoryId,
        onCategory: (id) {
          setState(() => _selectedCategoryId = id);
        },
        onReset: _reset,
        onApply: () {
          Navigator.pop(context);
          _onFilterChange();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = context.watch<CartState>().itemCount;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: NestedScrollView(
          controller: _scrollCtrl,
          headerSliverBuilder: (context, inner) => [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.canvas,
            elevation: 0,
            scrolledUnderElevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.categoryName ?? 'Tất cả sản phẩm',
              style: AppTypography.headingLg,
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: AppColors.ink),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: _ProductSearchDelegate(
                      onProductSelected: (product) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ProductDetailScreen(productId: product.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 4),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(56),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: _PillButton(
                        icon: Icons.tune,
                        label: 'Bộ lọc',
                        active: _selectedCategoryId != null,
                        onTap: _openFilters,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _PillButton(
                        icon: Icons.swap_vert,
                        label: _sort.label,
                        active: false,
                        onTap: _pickSort,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _products.isEmpty
                ? _EmptyState(onReset: _reset)
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Row(
                          children: [
                            Text(
                              '$_totalElements sản phẩm',
                              style: AppTypography.captionMd
                                  .copyWith(color: AppColors.mute),
                            ),
                            const Spacer(),
                            if (widget.categoryName != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accentPinkSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.full),
                                ),
                                child: Text(
                                  widget.categoryName!,
                                  style: AppTypography.captionSm.copyWith(
                                    color: AppColors.accentPinkDeep,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 18,
                            childAspectRatio: 0.58,
                          ),
                          itemCount: _products.length + (_hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _products.length) {
                              return const _LoadMoreTile();
                            }
                            final p = _products[i];
                            return _ApiProductCard(
                              product: p,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: p.id),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      if (_hasMore)
                        _PaginationFooter(
                          shown: _products.length,
                          total: _totalElements,
                          hasMore: _hasMore,
                          onLoadMore: _loadMore,
                        ),
                    ],
                  ),
      )),
      floatingActionButton: _FabStack(
        showScrollTop: _showScrollTop,
        onScrollTop: () => _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        cartCount: cartCount,
        onCart: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Future<void> _pickSort() async {
    final picked = await showModalBottomSheet<_SortOption>(
      context: context,
      backgroundColor: AppColors.canvas,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hairline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ..._SortOption.values.map(
              (o) => ListTile(
                title: Text(o.label, style: AppTypography.bodyStrong),
                trailing: _sort == o
                    ? Icon(Icons.check, color: AppColors.accentPinkDeep)
                    : null,
                onTap: () => Navigator.of(ctx).pop(o),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      setState(() => _sort = picked);
      _onFilterChange();
    }
  }
}

class _ApiProductCard extends StatelessWidget {
  const _ApiProductCard({
    required this.product,
    required this.onTap,
  });

  final ProductSummaryDTO product;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.softCloud,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.md),
                  ),
                ),
                child: product.primaryImageUrl != null
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.md),
                        ),
                        child: Image.network(
                          product.primaryImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Center(
                            child: Icon(Icons.image, color: AppColors.mute),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.image, color: AppColors.mute, size: 40),
                      ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: AppTypography.bodyStrong.copyWith(
                        color: AppColors.ink,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    if (product.brandName != null)
                      Text(
                        product.brandName!,
                        style: AppTypography.captionSm.copyWith(
                          color: AppColors.mute,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          Formatters.vnd(product.price),
                          style: AppTypography.bodyStrong.copyWith(
                            color: AppColors.ink,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: product.stockQuantity > 0
                                ? AppColors.success.withValues(alpha: 0.1)
                                : AppColors.sale.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.stockQuantity > 0 ? 'Còn hàng' : 'Hết',
                            style: AppTypography.utilityXs.copyWith(
                              color: product.stockQuantity > 0
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
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? AppColors.ink : AppColors.softCloud,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.full),
        side: BorderSide(
          color: active ? AppColors.ink : AppColors.hairlineSoft,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? AppColors.onPrimary : AppColors.ink,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.buttonSm.copyWith(
                    color: active ? AppColors.onPrimary : AppColors.ink,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down,
                size: 16,
                color: active ? AppColors.onPrimary : AppColors.ink,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.shown,
    required this.total,
    required this.hasMore,
    required this.onLoadMore,
  });
  final int shown;
  final int total;
  final bool hasMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0.0 : shown / total;
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        border: Border(top: BorderSide(color: AppColors.hairlineSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Đang hiển thị $shown / $total',
                  style: AppTypography.captionMd.copyWith(color: AppColors.mute),
                ),
                const Spacer(),
                Text(
                  '${(percent * 100).round()}%',
                  style: AppTypography.captionSm
                      .copyWith(color: AppColors.accentPinkDeep),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 4,
                backgroundColor: AppColors.hairlineSoft,
                valueColor: const AlwaysStoppedAnimation(
                  AppColors.accentPinkDeep,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Material(
                color: hasMore ? AppColors.ink : AppColors.softCloud,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.full),
                  onTap: hasMore ? onLoadMore : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Center(
                      child: Text(
                        hasMore ? 'Tải thêm ↓' : 'Bạn đã xem hết 🎉',
                        style: AppTypography.buttonSm.copyWith(
                          color: hasMore
                              ? AppColors.onPrimary
                              : AppColors.mute,
                          fontWeight: FontWeight.w700,
                        ),
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

class _LoadMoreTile extends StatelessWidget {
  const _LoadMoreTile();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accentPinkDeep,
          ),
        ),
      ),
    );
  }
}

class _FabStack extends StatelessWidget {
  const _FabStack({
    required this.showScrollTop,
    required this.onScrollTop,
    required this.cartCount,
    required this.onCart,
  });
  final bool showScrollTop;
  final VoidCallback onScrollTop;
  final int cartCount;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScrollToTopFab(visible: showScrollTop, onTap: onScrollTop),
        const SizedBox(height: 12),
        SizedBox(
          width: 56,
          height: 56,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const CartFab(),
              if (cartCount > 0)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      borderRadius: BorderRadius.circular(99),
                      border:
                          Border.all(color: AppColors.accentPink, width: 2),
                    ),
                    child: Text(
                      '$cartCount',
                      style: AppTypography.utilityXs.copyWith(
                        color: AppColors.accentPinkDeep,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({
    required this.selectedCategoryId,
    required this.onCategory,
    required this.onReset,
    required this.onApply,
  });

  final int? selectedCategoryId;
  final ValueChanged<int?> onCategory;
  final VoidCallback onReset;
  final VoidCallback onApply;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  int? _tempCategoryId;

  @override
  void initState() {
    super.initState();
    _tempCategoryId = widget.selectedCategoryId;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: Column(
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
            const SizedBox(height: 16),
            Row(
              children: [
                Text('Bộ lọc', style: AppTypography.headingLg),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    setState(() => _tempCategoryId = null);
                    widget.onReset();
                  },
                  child: Text(
                    'Đặt lại',
                    style: AppTypography.buttonSm
                        .copyWith(color: AppColors.sale),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Danh mục', style: AppTypography.captionMd),
            const SizedBox(height: 8),
            Expanded(
              child: ListView(
                children: [
                  FilterChipPill(
                    label: 'Tất cả',
                    active: _tempCategoryId == null,
                    onTap: () => setState(() => _tempCategoryId = null),
                  ),
                  const SizedBox(height: 8),
                  ...['Thức ăn khô', 'Thức ăn ướt', 'Đồ ăn vặt', 'Cát mèo', 'Thức ăn chim', 'Thức ăn cá', 'Đồ chơi', 'Phụ kiện']
                      .asMap()
                      .entries
                      .map((e) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: FilterChipPill(
                              label: e.value,
                              active: _tempCategoryId == e.key + 1,
                              onTap: () => setState(() => _tempCategoryId = e.key + 1),
                            ),
                          )),
                ],
              ),
            ),
            Material(
              color: AppColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: () {
                  widget.onCategory(_tempCategoryId);
                  widget.onApply();
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Áp dụng',
                      style: TextStyle(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
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

class _ProductSearchDelegate extends SearchDelegate<ProductSummaryDTO?> {
  _ProductSearchDelegate({required this.onProductSelected});

  final void Function(ProductSummaryDTO) onProductSelected;
  List<ProductSummaryDTO> _results = [];
  bool _loading = false;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            _results = [];
            showSuggestions(context);
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, null),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildSearchResults(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildSearchResults(context);

  Widget _buildSearchResults(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Nhập để tìm kiếm…'));
    }

    return FutureBuilder<List<ProductSummaryDTO>>(
      future: _searchProducts(query),
      builder: (context, snapshot) {
        if (_loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (_results.isEmpty) {
          return const Center(child: Text('Không có kết quả phù hợp'));
        }

        return ListView.separated(
          itemCount: _results.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (_, i) {
            final p = _results[i];
            return ListTile(
              leading: p.primaryImageUrl != null
                  ? Image.network(
                      p.primaryImageUrl!,
                      width: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 50,
                        color: AppColors.softCloud,
                        child: const Icon(Icons.image),
                      ),
                    )
                  : Container(
                      width: 50,
                      color: AppColors.softCloud,
                      child: const Icon(Icons.image),
                    ),
              title: Text(p.name),
              subtitle: Text(p.brandName ?? ''),
              trailing: Text(Formatters.vnd(p.price)),
              onTap: () {
                onProductSelected(p);
                close(context, p);
              },
            );
          },
        );
      },
    );
  }

  Future<List<ProductSummaryDTO>> _searchProducts(String query) async {
    _loading = true;
    final result = await ProductService.getProducts(page: 0, size: 20);
    _loading = false;
    
    if (result.isSuccess && result.data != null) {
      _results = result.data!.content
          .where((p) =>
              p.name.toLowerCase().contains(query.toLowerCase()) ||
              (p.brandName?.toLowerCase().contains(query.toLowerCase()) ?? false))
          .toList();
    }
    return _results;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.softCloud,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.search_off,
                size: 40,
                color: AppColors.accentPinkDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không tìm thấy sản phẩm',
              style: AppTypography.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Thử bỏ bộ lọc hoặc chọn danh mục khác nhé.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Material(
              color: AppColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: onReset,
                child: const Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: 22, vertical: 12),
                  child: Text(
                    'Đặt lại bộ lọc',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
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
