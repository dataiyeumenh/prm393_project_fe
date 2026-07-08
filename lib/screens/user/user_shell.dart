import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../cart/cart_screen.dart';
import '../home/home_screen.dart';
import '../product/all_products_screen.dart';
import 'profile_screen.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const AllProductsScreen(),
    const CartScreen(embedded: true),
    const UserProfileScreen(),
  ];

  static const _navItems = [
    _UserNavItem(
      icon: Icons.home_rounded,
      activeIcon: Icons.home_rounded,
      label: 'Trang chủ',
    ),
    _UserNavItem(
      icon: Icons.storefront_outlined,
      activeIcon: Icons.storefront_rounded,
      label: 'Sản phẩm',
    ),
    _UserNavItem(
      icon: Icons.shopping_bag_outlined,
      activeIcon: Icons.shopping_bag_rounded,
      label: 'Giỏ hàng',
      showCartBadge: true,
    ),
    _UserNavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Cá nhân',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _UserBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _UserNavItem {
  const _UserNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.showCartBadge = false,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool showCartBadge;
}

class _UserBottomNav extends StatelessWidget {
  const _UserBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<_UserNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        border: Border(
          top: BorderSide(color: AppColors.hairlineSoft, width: 1),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final selected = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: selected
                          ? AppColors.accentPink.withValues(alpha: 0.10)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _NavIcon(
                          icon: selected ? item.activeIcon : item.icon,
                          selected: selected,
                          badge: item.showCartBadge
                              ? context.watch<CartState>().itemCount
                              : 0,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.label,
                          style: AppTypography.utilityXs.copyWith(
                            color: selected
                                ? AppColors.accentPinkDeep
                                : AppColors.stone,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon({
    required this.icon,
    required this.selected,
    this.badge = 0,
  });

  final IconData icon;
  final bool selected;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 28,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          AnimatedScale(
            scale: selected ? 1.15 : 1.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              icon,
              size: 22,
              color: selected ? AppColors.accentPinkDeep : AppColors.stone,
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -4,
              top: -2,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 5,
                  vertical: 1,
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: BoxDecoration(
                  color: AppColors.sale,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.canvas, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
