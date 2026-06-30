import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/auth_state.dart';
import '../../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'orders/orders_screen.dart';
import 'users/users_screen.dart';
import 'warehouse/warehouse_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    AdminDashboardScreen(),
    AdminOrdersScreen(),
    AdminWarehouseScreen(),
    AdminUsersScreen(),
  ];

  static const _navItems = [
    _AdminNavItem(icon: Icons.dashboard_rounded, label: 'Dashboard'),
    _AdminNavItem(icon: Icons.receipt_long_rounded, label: 'Orders'),
    _AdminNavItem(icon: Icons.inventory_2_rounded, label: 'Warehouse'),
    _AdminNavItem(icon: Icons.group_rounded, label: 'Users'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _AdminBottomNav(
        currentIndex: _currentIndex,
        items: _navItems,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({required this.icon, required this.label});
  final IconData icon;
  final String label;
}

class _AdminBottomNav extends StatelessWidget {
  const _AdminBottomNav({
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<_AdminNavItem> items;
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
                        AnimatedScale(
                          scale: selected ? 1.15 : 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? AppColors.accentPinkDeep
                                : AppColors.stone,
                          ),
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

/// Reusable admin app bar.
class AdminAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdminAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showLogout = false,
  });

  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showLogout;

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.canvas,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 8, 8),
          child: Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: AppTypography.utilityXs.copyWith(
                        color: AppColors.mute,
                      ),
                    ),
                  Text(
                    title,
                    style: AppTypography.headingLg.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              if (actions != null) ...actions!,
              if (showLogout)
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: AppColors.sale),
                  onPressed: () => _confirmLogout(context),
                  tooltip: 'Log out',
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.canvas,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        title: Text(
          'Log out?',
          style: AppTypography.headingMd.copyWith(color: AppColors.ink),
        ),
        content: Text(
          'Are you sure you want to log out from the admin panel?',
          style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(
              'Cancel',
              style: AppTypography.buttonSm.copyWith(color: AppColors.mute),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(
              'Log out',
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
}

/// Status chip widget reused across admin screens.
class StatusChip extends StatelessWidget {
  const StatusChip({
    super.key,
    required this.label,
    required this.color,
    required this.bgColor,
  });

  final String label;
  final Color color;
  final Color bgColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(
        label,
        style: AppTypography.utilityXs.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Stat card reused in dashboard and other summaries.
class AdminStatCard extends StatelessWidget {
  const AdminStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.canvas,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.hairlineSoft),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: AppTypography.headingLg.copyWith(color: AppColors.ink),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.captionSm.copyWith(color: AppColors.mute),
            ),
          ],
        ),
      ),
    );
  }
}
