import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/api/order_dto.dart';
import '../../../services/order_service.dart';
import '../../../theme/app_theme.dart';
import '../admin_shell.dart';
import 'order_detail_screen.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  OrderStatus? _filterStatus;
  List<OrderSummaryDTO> _orders = [];
  bool _loading = true;
  bool _hasMore = true;
  int _page = 0;
  String? _error;

  static const _pageSize = 20;

  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _fetch(reset: true);
  }

  @override
  void dispose() {
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
    final result = await OrderService.getOrders(
      status: _filterStatus?.apiValue,
      page: page,
      size: _pageSize,
    );

    if (!mounted) return;
    setState(() {
      if (result.isSuccess && result.data != null) {
        final newItems = result.data!.content;
        _orders = reset ? newItems : [..._orders, ...newItems];
        _hasMore = !result.data!.last;
        _page = page + 1;
        _error = null;
      } else {
        _error = result.error;
        if (reset) _orders = [];
      }
      _loading = false;
    });
  }

  void _setFilter(OrderStatus? status) {
    if (_filterStatus == status) return;
    setState(() => _filterStatus = status);
    _fetch(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AdminAppBar(subtitle: 'Admin Panel', title: 'Orders'),
      body: Column(
        children: [
          // Filter chips
          _FilterRow(selected: _filterStatus, onSelect: _setFilter),
          const Divider(height: 1),
          Expanded(
            child: _error != null && _orders.isEmpty
                ? _ErrorState(
                    message: _error!,
                    onRetry: () => _fetch(reset: true),
                  )
                : RefreshIndicator(
                    onRefresh: () => _fetch(reset: true),
                    color: AppColors.accentPinkDeep,
                    child: _orders.isEmpty && !_loading
                        ? const _EmptyOrders()
                        : ListView.separated(
                            controller: _scrollCtrl,
                            padding: const EdgeInsets.all(16),
                            itemCount: _orders.length + (_hasMore ? 1 : 0),
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (ctx, i) {
                              if (i == _orders.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              }
                              return _OrderCard(
                                order: _orders[i],
                                onTap: () =>
                                    _openDetail(context, _orders[i].id),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, String orderId) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminOrderDetailScreen(orderId: orderId),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.selected, required this.onSelect});
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelect;

  static const _filters = [
    null, // All
    OrderStatus.pending,
    OrderStatus.confirmed,
    OrderStatus.processing,
    OrderStatus.shipped,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  String _label(OrderStatus? s) => s == null ? 'All' : s.label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final f = _filters[i];
          final isSelected = f == selected;
          final color = f == null ? AppColors.ink : f.color;
          return GestureDetector(
            onTap: () => onSelect(f),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (f == null
                          ? AppColors.ink
                          : f.bgColor.withValues(alpha: 0.5))
                    : AppColors.softCloud,
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                ),
              ),
              child: Text(
                _label(f),
                style: AppTypography.captionSm.copyWith(
                  color: isSelected
                      ? (f == null ? AppColors.onPrimary : color)
                      : AppColors.ash,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});
  final OrderSummaryDTO order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('MMM d, yyyy · HH:mm');
    final currFmt = NumberFormat.currency(symbol: '\$', decimalDigits: 2);

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
              color: Color(0x05000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderCode,
                    style: AppTypography.bodyStrong.copyWith(
                      color: AppColors.ink,
                    ),
                  ),
                ),
                StatusChip(
                  label: order.status.label,
                  color: order.status.color,
                  bgColor: order.status.bgColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 14,
                  color: AppColors.mute,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: AppTypography.captionSm.copyWith(
                      color: AppColors.charcoal,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: AppColors.mute,
                ),
                const SizedBox(width: 4),
                Text(
                  dateFmt.format(order.createdAt),
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.stone,
                  ),
                ),
                const Spacer(),
                Text(
                  '${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.mute,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  currFmt.format(order.totalAmount),
                  style: AppTypography.captionMd.copyWith(
                    color: AppColors.accentPinkDeep,
                    fontWeight: FontWeight.w700,
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

class _EmptyOrders extends StatelessWidget {
  const _EmptyOrders();

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Column(
          children: [
            const Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: AppColors.hairline,
            ),
            const SizedBox(height: 16),
            Text(
              'No orders found',
              style: AppTypography.headingMd.copyWith(color: AppColors.ash),
            ),
            const SizedBox(height: 8),
            Text(
              'Orders will appear here once placed.',
              style: AppTypography.bodyMd.copyWith(color: AppColors.stone),
            ),
          ],
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
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
