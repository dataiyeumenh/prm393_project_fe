import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../models/product.dart';
import '../../state/auth_state.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_icon_card.dart';
import '../../widgets/app_background.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/primary_nav_bar.dart';
import '../../widgets/product_card.dart';
import '../../widgets/promo_badge.dart';
import '../../widgets/scroll_to_top_fab.dart';
import '../cart/cart_screen.dart';
import '../product/all_products_screen.dart';
import '../product/product_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scrollCtrl = ScrollController();
  bool _showScrollTop = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 320;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final cart = context.watch<CartState>();
    final trending = MockData.trending();
    final sale = MockData.onSale();
    final categories = MockData.categories;

    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
          controller: _scrollCtrl,
          slivers: [
            SliverToBoxAdapter(child: _TopBar(userName: user?.fullName)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user == null
                          ? 'Hello, friend!'
                          : 'Hi, ${user.fullName.split(' ').first}!',
                      style: AppTypography.bodyMd
                          .copyWith(color: AppColors.mute),
                    ),
                    const SizedBox(height: 4),
                    const GradientHeadline(
                      'Fuel\nyour pet.',
                      fontSize: 84,
                      height: 0.88,
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 4)),
            SliverToBoxAdapter(
              child: HeroBanner(
                onShopTap: () => _push(context, const AllProductsScreen()),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Shop by category',
                emoji: '🐾',
                linkLabel: 'See all',
                onLinkTap: () => _push(context, const AllProductsScreen()),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 116,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (_, i) {
                    final c = categories[i];
                    return CategoryIconCard(
                      label: c.name,
                      icon: _categoryIcon(c.id),
                      color: _categoryColor(c.id),
                      onTap: () => _openCategory(context, c),
                    );
                  },
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Trending now',
                emoji: '✨',
                linkLabel: 'Shop all',
                onLinkTap: () => _push(context, const AllProductsScreen()),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.58,
                ),
                delegate: SliverChildBuilderDelegate(
                  (_, i) => ProductCard(
                    product: trending[i],
                    onTap: () => _openProduct(context, trending[i]),
                  ),
                  childCount: trending.length,
                ),
              ),
            ),
            if (sale.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        AppColors.accentPinkSoft,
                        AppColors.accentButter,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          PromoBadge(label: 'SALE', color: AppColors.saleDeep),
                          SizedBox(width: 10),
                          Text(
                            'Members save more 🐾',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const GradientHeadline(
                        'Endless\ndeals.',
                        fontSize: 56,
                        height: 0.92,
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 260,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: sale.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => SizedBox(
                            width: 200,
                            child: ProductCard(
                              product: sale[i],
                              onTap: () => _openProduct(context, sale[i]),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gradientStart, AppColors.accentPinkDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🐾', style: TextStyle(fontSize: 32)),
                    const SizedBox(height: 6),
                    const GradientHeadline(
                      'Join the\nPawFuel club.',
                      fontSize: 56,
                      height: 0.92,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFFD6E1),
                          Color(0xFFFFE5B4),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Free shipping on first order. Birthday treats. '
                      'Early access to drops.',
                      style: AppTypography.bodyMd.copyWith(
                        color: AppColors.onPrimary.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Material(
                      color: AppColors.canvas,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        onTap: () {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              backgroundColor: AppColors.ink,
                              behavior: SnackBarBehavior.floating,
                              content: Text(
                                'Welcome to the club! Check your inbox.',
                                style: AppTypography.captionMd
                                    .copyWith(color: AppColors.onPrimary),
                              ),
                            ),
                          );
                        },
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 22, vertical: 12),
                          child: Text(
                            'Join Us',
                            style: TextStyle(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 36)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  '© 2026 PawFuel · Made with 🐾 for furry friends',
                  textAlign: TextAlign.center,
                  style: AppTypography.utilityXs.copyWith(color: AppColors.mute),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      )),
      floatingActionButton: _HomeFabStack(
        showScrollTop: _showScrollTop,
        onScrollTop: () => _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        cartCount: cart.itemCount,
        onCart: () => _push(context, const CartScreen()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _openCategory(BuildContext context, ProductCategory c) {
    _push(context, AllProductsScreen(initialCategory: c));
  }

  void _openProduct(BuildContext context, Product p) {
    _push(context, ProductDetailScreen(product: p));
  }

  IconData _categoryIcon(String id) {
    switch (id) {
      case 'dry-food':
        return Icons.restaurant;
      case 'wet-food':
        return Icons.set_meal;
      case 'treats':
        return Icons.cake;
      case 'cat-litter':
        return Icons.grass;
      case 'bird-seed':
        return Icons.flutter_dash;
      case 'fish-food':
        return Icons.water_drop;
      case 'toys':
        return Icons.toys;
      case 'accessories':
        return Icons.inventory_2;
      default:
        return Icons.pets;
    }
  }

  Color _categoryColor(String id) {
    switch (id) {
      case 'dry-food':
        return AppColors.dogAccentSolid;
      case 'wet-food':
        return AppColors.catAccentSolid;
      case 'treats':
        return AppColors.treatsAccentSolid;
      case 'cat-litter':
        return AppColors.catLitterAccentSolid;
      case 'bird-seed':
        return AppColors.birdAccentSolid;
      case 'fish-food':
        return AppColors.fishAccentSolid;
      case 'toys':
        return AppColors.toysAccentSolid;
      case 'accessories':
        return AppColors.accessoriesAccentSolid;
      default:
        return AppColors.ink;
    }
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({this.userName});
  final String? userName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          const AppLogo(size: 36),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.ink),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const AllProductsScreen()),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.emoji,
    this.linkLabel,
    this.onLinkTap,
  });
  final String title;
  final String? emoji;
  final String? linkLabel;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 28, 16, 12),
      child: Row(
        children: [
          if (emoji != null) ...[
            Text(emoji!, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingLg.copyWith(
                color: AppColors.ink,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (linkLabel != null)
            GestureDetector(
              onTap: onLinkTap,
              child: Row(
                children: [
                  Text(
                    linkLabel!,
                    style: AppTypography.buttonSm
                        .copyWith(color: AppColors.accentPinkDeep),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.arrow_forward,
                    size: 14,
                    color: AppColors.accentPinkDeep,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeFabStack extends StatelessWidget {
  const _HomeFabStack({
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
        CartFabWithBadge(count: cartCount, onTap: onCart),
      ],
    );
  }
}

/// Same as CartFab but lets parent pass the count directly to avoid duplicate
/// listeners in tight compositions.
class CartFabWithBadge extends StatelessWidget {
  const CartFabWithBadge({super.key, required this.count, required this.onTap});
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.full),
        onTap: onTap,
        child: Container(
          width: 56,
          height: 56,
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
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.shopping_bag,
                color: AppColors.onPrimary,
                size: 24,
              ),
              if (count > 0)
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: AppColors.canvas,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.accentPink, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      count > 9 ? '9+' : '$count',
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
      ),
    );
  }
}