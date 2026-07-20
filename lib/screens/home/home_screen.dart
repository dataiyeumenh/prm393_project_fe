import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api/category_dto.dart';
import '../../models/api/product_dto.dart';
import '../../services/category_service.dart';
import '../../services/product_service.dart';
import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/category_icon_card.dart';
import '../../widgets/app_background.dart';
import '../../widgets/hero_banner.dart';
import '../../widgets/primary_nav_bar.dart';
import '../../widgets/promo_badge.dart';
import '../../widgets/scroll_to_top_fab.dart';
import '../../utils/formatters.dart';
import '../chat/chatbot_screen.dart';
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

  List<ProductSummaryDTO> _trending = [];
  List<CategoryDTO> _categories = [];
  bool _loadingCategories = true;
  bool _loadingProducts = true;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _loadData();
  }

  void _onScroll() {
    final shouldShow = _scrollCtrl.offset > 320;
    if (shouldShow != _showScrollTop) {
      setState(() => _showScrollTop = shouldShow);
    }
  }

  Future<void> _loadData() async {
    await Future.wait([_loadCategories(), _loadProducts()]);
  }

  Future<void> _loadCategories() async {
    final result = await CategoryService.getAllCategories();
    if (mounted && result.isSuccess && result.data != null) {
      setState(() {
        _categories = result.data!;
        _loadingCategories = false;
      });
    } else {
      if (mounted) setState(() => _loadingCategories = false);
    }
  }

  Future<void> _loadProducts() async {
    final result = await ProductService.getProducts(page: 0, size: 10);
    if (mounted && result.isSuccess && result.data != null) {
      setState(() {
        _trending = result.data!.content;
        _loadingProducts = false;
      });
    } else {
      if (mounted) setState(() => _loadingProducts = false);
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
                            ? 'Xin chào bạn!'
                            : 'Chào ${user.fullName.split(' ').first}!',
                        style: AppTypography.bodyMd.copyWith(
                          color: AppColors.mute,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const GradientHeadline(
                        'PawFuel.',
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
                  title: 'Mua theo danh mục',
                  emoji: '🐾',
                  linkLabel: 'Xem tất cả',
                  onLinkTap: () => _push(context, const AllProductsScreen()),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 116,
                  child: _loadingCategories
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _categories.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 12),
                          itemBuilder: (_, i) {
                            final c = _categories[i];
                            return CategoryIconCard(
                              label: c.name,
                              icon: _categoryIcon(i),
                              color: _categoryColor(i),
                              onTap: () => _openCategory(context, c),
                            );
                          },
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SectionHeader(
                  title: 'Đang hot',
                  emoji: '✨',
                  linkLabel: 'Mua sắm ngay',
                  onLinkTap: () => _push(context, const AllProductsScreen()),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: _loadingProducts
                    ? const SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      )
                    : _trending.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Chưa có sản phẩm nào',
                              style: AppTypography.bodyMd.copyWith(
                                color: AppColors.mute,
                              ),
                            ),
                          ),
                        ),
                      )
                    : SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 18,
                              childAspectRatio: 0.58,
                            ),
                        delegate: SliverChildBuilderDelegate((_, i) {
                          final p = _trending[i];
                          return _ApiProductCard(
                            product: p,
                            onTap: () => _openProductDetail(context, p.id),
                          );
                        }, childCount: _trending.length),
                      ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
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
                        children: [
                          PromoBadge(label: 'SALE', color: AppColors.saleDeep),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Thành viên tiết kiệm hơn 🐾',
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const GradientHeadline(
                        'Deal\nkhông ngừng.',
                        fontSize: 56,
                        height: 0.92,
                      ),
                    ],
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 36)),
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gradientStart,
                        AppColors.accentPinkDeep,
                      ],
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
                        'Cùng nhau\nchăm boss.',
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
                        'Miễn phí vận chuyển đơn đầu tiên. Quà sinh nhật cho boss. '
                        'Mua sớm vật phẩm mới trước.',
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
                                  'Chào mừng bạn vào clb! Kiểm tra hộp thư nhé.',
                                  style: AppTypography.captionMd.copyWith(
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 12,
                            ),
                            child: Text(
                              'Tham gia ngay',
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
                    '© 2026 PawFuel · Làm với 🐾 cho các boss',
                    textAlign: TextAlign.center,
                    style: AppTypography.utilityXs.copyWith(
                      color: AppColors.mute,
                    ),
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ),
      ),
      floatingActionButton: _HomeFabStack(
        showScrollTop: _showScrollTop,
        onScrollTop: () => _scrollCtrl.animateTo(
          0,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOut,
        ),
        onChatbot: () => _push(context, const ChatbotScreen()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  void _push(BuildContext context, Widget screen) =>
      Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));

  void _openCategory(BuildContext context, CategoryDTO c) {
    _push(
      context,
      AllProductsScreen(initialCategoryId: c.id, categoryName: c.name),
    );
  }

  void _openProductDetail(BuildContext context, String productId) {
    _push(context, ProductDetailScreen(productId: productId));
  }

  IconData _categoryIcon(int index) {
    final icons = [
      Icons.restaurant,
      Icons.set_meal,
      Icons.cake,
      Icons.grass,
      Icons.flutter_dash,
      Icons.water_drop,
      Icons.toys,
      Icons.inventory_2,
    ];
    return icons[index % icons.length];
  }

  Color _categoryColor(int index) {
    final colors = [
      AppColors.dogAccentSolid,
      AppColors.catAccentSolid,
      AppColors.treatsAccentSolid,
      AppColors.catLitterAccentSolid,
      AppColors.birdAccentSolid,
      AppColors.fishAccentSolid,
      AppColors.toysAccentSolid,
      AppColors.accessoriesAccentSolid,
    ];
    return colors[index % colors.length];
  }
}

class _ApiProductCard extends StatelessWidget {
  const _ApiProductCard({required this.product, required this.onTap});

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
                        child: Icon(Icons.image, color: AppColors.mute),
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

class _TopBar extends StatelessWidget {
  const _TopBar({this.userName});
  final String? userName;

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Đăng xuất?',
          style: AppTypography.headingMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Bạn chắc chắn muốn đăng xuất?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Huỷ',
              style: AppTypography.buttonSm.copyWith(color: AppColors.mute),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Đăng xuất',
              style: AppTypography.buttonSm.copyWith(color: AppColors.sale),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await context.read<AuthState>().logout();
    }
  }

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
          PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, color: AppColors.ink),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            color: AppColors.canvas,
            itemBuilder: (_) => [
              if (userName != null)
                PopupMenuItem(
                  enabled: false,
                  value: 'user',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName!,
                        style: AppTypography.bodyStrong.copyWith(
                          color: AppColors.ink,
                        ),
                      ),
                      Divider(color: AppColors.hairlineSoft, height: 16),
                    ],
                  ),
                ),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 18, color: AppColors.sale),
                    const SizedBox(width: 10),
                    Text(
                      'Đăng xuất',
                      style: AppTypography.buttonSm.copyWith(
                        color: AppColors.sale,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (value) {
              if (value == 'logout') _confirmLogout(context);
            },
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
                    style: AppTypography.buttonSm.copyWith(
                      color: AppColors.accentPinkDeep,
                    ),
                  ),
                  const SizedBox(width: 2),
                  Icon(
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
    required this.onChatbot,
  });
  final bool showScrollTop;
  final VoidCallback onScrollTop;
  final VoidCallback onChatbot;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        ScrollToTopFab(visible: showScrollTop, onTap: onScrollTop),
        const SizedBox(height: 12),
        ChatbotFab(onTap: onChatbot),
      ],
    );
  }
}

class ChatbotFab extends StatelessWidget {
  const ChatbotFab({super.key, required this.onTap});
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
            gradient: LinearGradient(
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
                Icons.smart_toy_outlined,
                color: AppColors.onPrimary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
