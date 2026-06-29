import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../models/api/admin_dto.dart';
import '../../../models/api/order_dto.dart';
import '../../../services/admin_service.dart';
import '../../../services/order_service.dart';
import '../../../state/auth_state.dart';
import '../../../theme/app_theme.dart';
import '../admin_shell.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  DashboardStatsDTO? _stats;
  List<OrderSummaryDTO> _recentOrders = [];
  bool _loadingStats = true;
  bool _loadingOrders = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await Future.wait([_loadStats(), _loadRecentOrders()]);
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    final result = await AdminService.getDashboardStats();
    if (!mounted) return;
    setState(() {
      _stats = result.data ?? DashboardStatsDTO.empty();
      _statsError = result.isSuccess ? null : result.error;
      _loadingStats = false;
    });
  }

  Future<void> _loadRecentOrders() async {
    setState(() => _loadingOrders = true);
    final result = await OrderService.getOrders(size: 5);
    if (!mounted) return;
    setState(() {
      _recentOrders = result.data?.content ?? [];
      _loadingOrders = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthState>().user;
    final currFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(
        subtitle: 'Admin Panel',
        title: 'Dashboard',
        showLogout: true,
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        color: AppColors.accentPinkDeep,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Greeting ──────────────────────────────────────────
            _GreetingCard(userName: user?.fullName ?? 'Admin'),
            const SizedBox(height: 24),

            // ── Stats grid ────────────────────────────────────────
            Text(
              'Overview',
              style: AppTypography.headingMd.copyWith(
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            _loadingStats
                ? const _LoadingGrid()
                : GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      AdminStatCard(
                        label: 'Total Orders',
                        value: '${_stats?.totalOrders ?? 0}',
                        icon: Icons.receipt_long_rounded,
                        iconColor: AppColors.info,
                        iconBg: AppColors.info.withValues(alpha: 0.12),
                      ),
                      AdminStatCard(
                        label: 'Revenue',
                        value: currFmt.format(_stats?.totalRevenue ?? 0),
                        icon: Icons.attach_money_rounded,
                        iconColor: AppColors.success,
                        iconBg: AppColors.success.withValues(alpha: 0.12),
                      ),
                      AdminStatCard(
                        label: 'Total Users',
                        value: '${_stats?.totalUsers ?? 0}',
                        icon: Icons.group_rounded,
                        iconColor: AppColors.accentPinkDeep,
                        iconBg: AppColors.accentPinkDeep.withValues(
                          alpha: 0.12,
                        ),
                      ),
                      AdminStatCard(
                        label: 'Low Stock',
                        value: '${_stats?.lowStockProducts ?? 0}',
                        icon: Icons.warning_amber_rounded,
                        iconColor: AppColors.saleDeep,
                        iconBg: AppColors.sale.withValues(alpha: 0.12),
                      ),
                    ],
                  ),

            if (_statsError != null) ...[
              const SizedBox(height: 8),
              _InfoBanner(
                message: 'Dashboard stats unavailable: $_statsError',
                icon: Icons.info_outline_rounded,
                color: AppColors.mute,
              ),
            ],

            const SizedBox(height: 28),

            // ── Recent orders ─────────────────────────────────────
            Row(
              children: [
                Text(
                  'Recent Orders',
                  style: AppTypography.headingMd.copyWith(
                    color: AppColors.charcoal,
                  ),
                ),
                const Spacer(),
                if (!_loadingOrders)
                  Text(
                    'Live',
                    style: AppTypography.utilityXs.copyWith(
                      color: AppColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _loadingOrders
                ? const _OrdersLoadingList()
                : _recentOrders.isEmpty
                ? const _EmptyState(
                    icon: Icons.receipt_long_outlined,
                    message: 'No orders yet',
                  )
                : Column(
                    children: _recentOrders
                        .map((o) => _RecentOrderTile(order: o))
                        .toList(),
                  ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Private widgets
// ─────────────────────────────────────────────────────────────────────────────

class _GreetingCard extends StatelessWidget {
  const _GreetingCard({required this.userName});
  final String userName;

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.gradientStart, AppColors.accentButter],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentPink.withValues(alpha: 0.20),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_greeting,',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.ash),
                ),
                const SizedBox(height: 2),
                Text(
                  userName.split(' ').first,
                  style: AppTypography.headingLg.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentPinkDeep.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.full),
                  ),
                  child: Text(
                    '🐾 Admin',
                    style: AppTypography.utilityXs.copyWith(
                      color: AppColors.accentPinkDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.40),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              size: 32,
              color: AppColors.accentPinkDeep,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  const _RecentOrderTile({required this.order});
  final OrderSummaryDTO order;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  order.orderCode,
                  style: AppTypography.captionMd.copyWith(color: AppColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  order.customerName,
                  style: AppTypography.captionSm.copyWith(
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(
                label: order.status.label,
                color: order.status.color,
                bgColor: order.status.bgColor,
              ),
              const SizedBox(height: 4),
              Text(
                dateFmt.format(order.createdAt),
                style: AppTypography.utilityXs.copyWith(color: AppColors.stone),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LoadingGrid extends StatelessWidget {
  const _LoadingGrid();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: List.generate(4, (_) => const _SkeletonCard()),
    );
  }
}

class _OrdersLoadingList extends StatelessWidget {
  const _OrdersLoadingList();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(3, (_) => const _SkeletonOrderTile()),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softCloud,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _SkeletonOrderTile extends StatelessWidget {
  const _SkeletonOrderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.softCloud,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({
    required this.message,
    required this.icon,
    required this.color,
  });
  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.utilityXs.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.message});
  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.hairline),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTypography.bodyMd.copyWith(color: AppColors.stone),
          ),
        ],
      ),
    );
  }
}
