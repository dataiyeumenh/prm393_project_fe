import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../models/api/order_dto.dart';
import '../../../services/order_service.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../admin_shell.dart';

class AdminOrderDetailScreen extends StatefulWidget {
  const AdminOrderDetailScreen({super.key, required this.orderId});
  final String orderId;

  @override
  State<AdminOrderDetailScreen> createState() => _AdminOrderDetailScreenState();
}

class _AdminOrderDetailScreenState extends State<AdminOrderDetailScreen> {
  OrderDetailDTO? _order;
  bool _loading = true;
  bool _updating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() => _loading = true);
    final result = await OrderService.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _order = result.data;
      _error = result.isSuccess ? null : result.error;
      _loading = false;
    });
  }

  Future<void> _updateStatus(OrderStatus newStatus) async {
    setState(() => _updating = true);
    final result = await OrderService.updateOrderStatus(
      widget.orderId,
      newStatus,
    );
    if (!mounted) return;
    setState(() => _updating = false);

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Đã cập nhật đơn sang ${newStatus.viLabel}',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
      await _loadOrder();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.sale,
          behavior: SnackBarBehavior.floating,
          content: Text(
            result.error ?? 'Cập nhật trạng thái thất bại',
            style: AppTypography.captionMd.copyWith(color: AppColors.onPrimary),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        title: Text(
          _order?.orderCode ?? 'Chi tiết đơn hàng',
          style: AppTypography.headingMd,
        ),
        leading: const BackButton(),
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null && _order == null
          ? _ErrorBody(message: _error!, onRetry: _loadOrder)
          : _OrderBody(
              order: _order!,
              updating: _updating,
              onUpdateStatus: _updateStatus,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _OrderBody extends StatelessWidget {
  const _OrderBody({
    required this.order,
    required this.updating,
    required this.onUpdateStatus,
  });

  final OrderDetailDTO order;
  final bool updating;
  final ValueChanged<OrderStatus> onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy · HH:mm');

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status + date
          Row(
            children: [
              StatusChip(
                label: order.status.viLabel,
                color: order.status.color,
                bgColor: order.status.bgColor,
              ),
              const SizedBox(width: 10),
              Text(
                dateFmt.format(order.createdAt),
                style: AppTypography.captionSm.copyWith(color: AppColors.mute),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Customer info
          _Section(
            title: 'Khách hàng',
            child: _InfoGrid(
              items: [
                _InfoItem(
                  label: 'Họ tên',
                  value: order.customerName,
                  icon: Icons.person_outline,
                ),
                _InfoItem(
                  label: 'Email',
                  value: order.customerEmail,
                  icon: Icons.email_outlined,
                ),
                if (order.customerPhone != null)
                  _InfoItem(
                    label: 'Số điện thoại',
                    value: order.customerPhone!,
                    icon: Icons.phone_outlined,
                  ),
                if (order.shippingAddress != null)
                  _InfoItem(
                    label: 'Địa chỉ',
                    value: order.shippingAddress!,
                    icon: Icons.location_on_outlined,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Items
          _Section(
            title: 'Sản phẩm (${order.items.length})',
            child: Column(
              children: order.items
                  .map((item) => _OrderItemRow(item: item))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),

          // Totals
          _Section(
            title: 'Thanh toán',
            child: Column(
              children: [
                _TotalRow(
                  label: 'Tạm tính',
                  value: Formatters.vnd(
                    order.totalAmount - (order.shippingFee ?? 0),
                  ),
                ),
                if (order.shippingFee != null)
                  _TotalRow(
                    label: 'Vận chuyển',
                    value: order.shippingFee == 0
                        ? 'Miễn phí'
                        : Formatters.vnd(order.shippingFee!),
                  ),
                const Divider(height: 16),
                _TotalRow(
                  label: 'Tổng cộng',
                  value: Formatters.vnd(order.totalAmount),
                  bold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Status actions
          if (order.status.nextStatuses.isNotEmpty) ...[
            Text(
              'Cập nhật trạng thái',
              style: AppTypography.headingMd.copyWith(
                color: AppColors.charcoal,
              ),
            ),
            const SizedBox(height: 12),
            updating
                ? const Center(child: CircularProgressIndicator())
                : Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: order.status.nextStatuses
                        .map(
                          (s) => _StatusActionButton(
                            status: s,
                            onTap: () => onUpdateStatus(s),
                          ),
                        )
                        .toList(),
                  ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTypography.captionMd.copyWith(color: AppColors.mute),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _InfoGrid extends StatelessWidget {
  const _InfoGrid({required this.items});
  final List<_InfoItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(children: items.map((item) => item).toList());
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem({
    required this.label,
    required this.value,
    required this.icon,
  });
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.stone),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.mute,
                  ),
                ),
                Text(
                  value,
                  style: AppTypography.captionMd.copyWith(color: AppColors.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  const _OrderItemRow({required this.item});
  final OrderItemDTO item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.softCloud,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            clipBehavior: Clip.antiAlias,
            child: item.productImageUrl != null
                ? Image.network(
                    item.productImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image,
                      color: AppColors.mute,
                      size: 20,
                    ),
                  )
                : const Icon(Icons.image, color: AppColors.mute, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.captionMd.copyWith(color: AppColors.ink),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'x${item.quantity}  ·  ${Formatters.vnd(item.unitPrice)}/sp',
                  style: AppTypography.utilityXs.copyWith(
                    color: AppColors.mute,
                  ),
                ),
              ],
            ),
          ),
          Text(
            Formatters.vnd(item.subTotal),
            style: AppTypography.captionMd.copyWith(
              color: AppColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.label,
    required this.value,
    this.bold = false,
  });
  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: bold
                ? AppTypography.bodyStrong.copyWith(color: AppColors.ink)
                : AppTypography.bodyMd.copyWith(color: AppColors.mute),
          ),
          const Spacer(),
          Text(
            value,
            style: bold
                ? AppTypography.bodyStrong.copyWith(
                    color: AppColors.accentPinkDeep,
                  )
                : AppTypography.captionMd.copyWith(color: AppColors.ink),
          ),
        ],
      ),
    );
  }
}

class _StatusActionButton extends StatelessWidget {
  const _StatusActionButton({required this.status, required this.onTap});
  final OrderStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: status.bgColor,
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(color: status.color.withValues(alpha: 0.4)),
        ),
        child: Text(
          'Đánh dấu: ${status.viLabel}',
          style: AppTypography.buttonSm.copyWith(
            color: status.color,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onRetry});
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
