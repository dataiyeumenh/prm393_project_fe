import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/product.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/filter_chip_pill.dart';
import '../../widgets/app_background.dart';
import '../../widgets/product_card.dart';
import '../../widgets/scroll_to_top_fab.dart';
import '../cart/cart_screen.dart';
import 'product_detail_screen.dart';

class AllProductsScreen extends StatefulWidget {
  const AllProductsScreen({super.key, this.initialCategory});

  final ProductCategory? initialCategory;

  @override
  State<AllProductsScreen> createState() => _AllProductsScreenState();
}

enum _SortOption { featured, priceLow, priceHigh, topRated }

extension on _SortOption {
  String get label {
    switch (this) {
      case _SortOption.featured:
        return 'Featured';
      case _SortOption.priceLow:
        return 'Price ↑';
      case _SortOption.priceHigh:
        return 'Price ↓';
      case _SortOption.topRated:
        return 'Top Rated';
    }
  }
}

class _AllProductsScreenState extends State<AllProductsScreen> {
  static const int _pageSize = 6;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _selectedCategoryId = 'all';
  Set<PetType> _selectedPetTypes = {};
  bool _onSaleOnly = false;
  _SortOption _sort = _SortOption.featured;
  bool _showScrollTop = false;
  int _visibleCount = _pageSize;

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategoryId = widget.initialCategory!.id;
      _selectedPetTypes = {widget.initialCategory!.petType};
    }
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 240;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
    // Infinite scroll
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 240) {
      _loadMore();
    }
  }

  void _loadMore() {
    final total = _filtered.length;
    if (_visibleCount >= total) return;
    setState(() => _visibleCount = (_visibleCount + _pageSize).clamp(0, total));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  List<Product> get _filtered {
    final q = _searchCtrl.text.trim().toLowerCase();
    var list = MockData.products.where((p) {
      if (_selectedCategoryId != 'all' && p.categoryId != _selectedCategoryId) {
        return false;
      }
      if (_selectedPetTypes.isNotEmpty &&
          !_selectedPetTypes.contains(p.petType)) {
        return false;
      }
      if (_onSaleOnly && !p.onSale) return false;
      if (q.isNotEmpty) {
        return p.name.toLowerCase().contains(q) ||
            p.subtitle.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    switch (_sort) {
      case _SortOption.featured:
        break;
      case _SortOption.priceLow:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case _SortOption.priceHigh:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      case _SortOption.topRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
        break;
    }
    return list;
  }

  void _reset() {
    setState(() {
      _selectedCategoryId = 'all';
      _selectedPetTypes = {};
      _onSaleOnly = false;
      _sort = _SortOption.featured;
      _visibleCount = _pageSize;
    });
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
        categories: MockData.categories,
        selectedCategoryId: _selectedCategoryId,
        onCategory: (id) => setState(() => _selectedCategoryId = id),
        selectedPetTypes: _selectedPetTypes,
        onPetType: (t) => setState(() {
          if (_selectedPetTypes.contains(t)) {
            _selectedPetTypes.remove(t);
          } else {
            _selectedPetTypes.add(t);
          }
        }),
        onSaleOnly: _onSaleOnly,
        onToggleSale: (v) => setState(() => _onSaleOnly = v),
        onReset: _reset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final total = filtered.length;
    final shown = filtered.take(_visibleCount).toList();
    final hasMore = _visibleCount < total;
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
              icon: const Icon(Icons.arrow_back, color: AppColors.ink),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Text(
              widget.initialCategory?.name ?? 'All Products',
              style: AppTypography.headingLg,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.ink),
                onPressed: () {
                  showSearch(
                    context: context,
                    delegate: _InlineSearchDelegate(
                      controller: _searchCtrl,
                      onChanged: () => setState(() {
                        _visibleCount = _pageSize;
                      }),
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
                        label: 'Filters',
                        active: _hasActiveFilter,
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
        body: filtered.isEmpty
            ? _EmptyState(onReset: _reset)
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          '$total results',
                          style: AppTypography.captionMd
                              .copyWith(color: AppColors.mute),
                        ),
                        const Spacer(),
                        if (widget.initialCategory != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentPinkSoft,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.full),
                            ),
                            child: Text(
                              widget.initialCategory!.name,
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
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 18,
                        childAspectRatio: 0.58,
                      ),
                      itemCount: shown.length + (hasMore ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (i >= shown.length) {
                          return const _LoadMoreTile();
                        }
                        final p = shown[i];
                        return ProductCard(
                          product: p,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ProductDetailScreen(product: p),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  _PaginationFooter(
                    shown: shown.length,
                    total: total,
                    hasMore: hasMore,
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

  bool get _hasActiveFilter =>
      _selectedCategoryId != 'all' ||
      _selectedPetTypes.isNotEmpty ||
      _onSaleOnly;

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
                    ? const Icon(Icons.check, color: AppColors.accentPinkDeep)
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
      setState(() {
        _sort = picked;
        _visibleCount = _pageSize;
      });
    }
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
                  'Showing $shown of $total',
                  style: AppTypography.captionMd.copyWith(color: AppColors.mute),
                ),
                const Spacer(),
                if (hasMore)
                  Text(
                    '${(percent * 100).round()}%',
                    style: AppTypography.captionSm
                        .copyWith(color: AppColors.accentPinkDeep),
                  )
                else
                  Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppColors.success,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'All loaded',
                        style: AppTypography.captionSm
                            .copyWith(color: AppColors.success),
                      ),
                    ],
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
                        hasMore ? 'Load more ↓' : 'You reached the end 🎉',
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

class _FilterSheet extends StatelessWidget {
  const _FilterSheet({
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategory,
    required this.selectedPetTypes,
    required this.onPetType,
    required this.onSaleOnly,
    required this.onToggleSale,
    required this.onReset,
  });

  final List<ProductCategory> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategory;
  final Set<PetType> selectedPetTypes;
  final ValueChanged<PetType> onPetType;
  final bool onSaleOnly;
  final ValueChanged<bool> onToggleSale;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, ctrl) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        child: ListView(
          controller: ctrl,
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
                Text('Filters', style: AppTypography.headingLg),
                const Spacer(),
                TextButton(
                  onPressed: onReset,
                  child: Text(
                    'Reset',
                    style: AppTypography.buttonSm
                        .copyWith(color: AppColors.sale),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Category', style: AppTypography.captionMd),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilterChipPill(
                  label: 'All',
                  active: selectedCategoryId == 'all',
                  onTap: () => onCategory('all'),
                ),
                for (final c in categories)
                  FilterChipPill(
                    label: c.name,
                    active: selectedCategoryId == c.id,
                    onTap: () => onCategory(c.id),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Pet type', style: AppTypography.captionMd),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in PetType.values)
                  FilterChipPill(
                    label: t.label,
                    icon: t.icon,
                    active: selectedPetTypes.contains(t),
                    onTap: () => onPetType(t),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: AppColors.softCloud,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.accentPinkDeep,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Show only items on sale',
                        style: AppTypography.bodyStrong),
                  ),
                  Switch(
                    value: onSaleOnly,
                    activeThumbColor: AppColors.accentPinkDeep,
                    onChanged: onToggleSale,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Material(
              color: AppColors.ink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Apply',
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

class _InlineSearchDelegate extends SearchDelegate<String> {
  _InlineSearchDelegate({
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () {
            query = '';
            controller.text = '';
            onChanged();
          },
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () => close(context, ''),
    );
  }

  @override
  Widget buildResults(BuildContext ctx) => _build(ctx);

  @override
  Widget buildSuggestions(BuildContext ctx) => _build(ctx);

  Widget _build(BuildContext context) {
    final q = query.trim().toLowerCase();
    final results = q.isEmpty
        ? <Product>[]
        : MockData.products.where((p) {
            return p.name.toLowerCase().contains(q) ||
                p.subtitle.toLowerCase().contains(q) ||
                p.brand.toLowerCase().contains(q);
          }).toList();

    if (q.isEmpty) {
      return const Center(
        child: Text('Type to search…'),
      );
    }

    if (results.isEmpty) {
      return const Center(child: Text('No matches'));
    }

    return ListView.separated(
      itemCount: results.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (_, i) {
        final p = results[i];
        return ListTile(
          title: Text(p.name),
          subtitle: Text(p.brand),
          onTap: () {
            controller.text = p.name;
            onChanged();
            close(context, p.name);
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: p),
              ),
            );
          },
        );
      },
    );
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
              'No matches found',
              style: AppTypography.headingLg,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Try removing some filters or adjusting your search.',
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
                    'Reset Filters',
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