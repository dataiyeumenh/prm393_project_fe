import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/api/order_dto.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../utils/formatters.dart';
import 'checkout_screen.dart' show PaymentMethod;
import 'payment_webview_screen.dart';

class OrderStatusScreen extends StatefulWidget {
  const OrderStatusScreen({
    super.key,
    required this.orderId,
    required this.method,
    this.paymentUrl,
  });

  final String orderId;
  final PaymentMethod method;
  final String? paymentUrl;

  @override
  State<OrderStatusScreen> createState() => _OrderStatusScreenState();
}

class _OrderStatusScreenState extends State<OrderStatusScreen> {
  OrderDetailDTO? _order;
  bool _loading = true;
  bool _payingAgain = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await OrderService.getOrderById(widget.orderId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.isSuccess) {
        _order = result.data;
      } else {
        _error = result.error;
      }
    });
  }

  /// Requests a FRESH VNPay URL and opens it in the in-app WebView. VNPay
  /// links expire after a few minutes, so reusing the original URL would
  /// just time out — we always re-create the URL for the same (still
  /// PENDING) order. When the WebView pops, the status is reloaded.
  Future<void> _payAgain() async {
    setState(() => _payingAgain = true);
    final result = await PaymentService.createVnpayUrl(widget.orderId);
    if (!mounted) return;
    setState(() => _payingAgain = false);
    if (!result.isSuccess) {
      _snack(result.error ?? 'Không tạo được liên kết VNPay.');
      return;
    }
    await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) =>
            PaymentWebViewScreen(paymentUrl: result.data!.paymentUrl),
      ),
    );
    if (mounted) _load();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(message,
            style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _backToHome() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Đơn hàng', style: AppTypography.headingLg),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh, color: AppColors.ink),
          ),
        ],
      ),
      body: AppBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : _content(),
      ),
    );
  }

  Widget _content() {
    final order = _order!;
    final awaitingPayment = widget.method == PaymentMethod.vnpay &&
        order.status == OrderStatus.pending;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _Header(
                method: widget.method,
                status: order.status,
              ),
              const SizedBox(height: 20),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Đơn hàng', style: AppTypography.captionSm.copyWith(color: AppColors.mute)),
                        const Spacer(),
                        Text('#${_short(order.id)}',
                            style: AppTypography.bodyStrong),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Trạng thái', style: AppTypography.captionSm.copyWith(color: AppColors.mute)),
                        const Spacer(),
                        _StatusChip(status: order.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text('Đặt lúc', style: AppTypography.captionSm.copyWith(color: AppColors.mute)),
                        const Spacer(),
                        Text(
                          DateFormat('dd/MM/yyyy · HH:mm')
                              .format(order.createdAt.toLocal()),
                          style: AppTypography.bodyMd,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (order.shippingAddress != null ||
                  order.customerPhone != null) ...[
                const SizedBox(height: 12),
                _Card(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on_outlined,
                          color: AppColors.accentPinkDeep),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                '${order.customerName}  ·  ${order.customerPhone ?? ''}',
                                style: AppTypography.bodyStrong),
                            const SizedBox(height: 2),
                            Text(order.shippingAddress ?? '',
                                style: AppTypography.bodyMd
                                    .copyWith(color: AppColors.ash)),
                            if (order.notes != null &&
                                order.notes!.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text('Ghi chú: ${order.notes}',
                                  style: AppTypography.captionSm
                                      .copyWith(color: AppColors.mute)),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _Card(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    for (int i = 0; i < order.items.length; i++) ...[
                      if (i > 0)
                        const Divider(
                            height: 18, color: AppColors.hairlineSoft),
                      _ItemRow(item: order.items[i]),
                    ],
                    const Divider(height: 22, color: AppColors.hairlineSoft),
                    Row(
                      children: [
                        Text('Tổng cộng', style: AppTypography.bodyStrong),
                        const Spacer(),
                        Text(Formatters.vnd(order.totalAmount),
                            style: AppTypography.bodyStrong
                                .copyWith(color: AppColors.accentPinkDeep)),
                      ],
                    ),
                  ],
                ),
              ),
              if (awaitingPayment) ...[
                const SizedBox(height: 16),
                _InfoBanner(
                  text:
                      'Đang chờ bạn thanh toán VNPay. Sau khi thanh toán xong, bấm "Đã thanh toán" để cập nhật trạng thái nhé.',
                ),
              ],
            ],
          ),
        ),
        _BottomActions(
          awaitingPayment: awaitingPayment,
          payingAgain: _payingAgain,
          onPayAgain: _payAgain,
          onRefresh: _load,
          onDone: _backToHome,
        ),
      ],
    );
  }

  String _short(String id) =>
      id.length <= 8 ? id.toUpperCase() : id.substring(0, 8).toUpperCase();
}

// ─────────────────────────────────────── Header ───────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.method, required this.status});
  final PaymentMethod method;
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final paid = status == OrderStatus.confirmed ||
        status == OrderStatus.processing ||
        status == OrderStatus.shipped ||
        status == OrderStatus.delivered;
    final cancelled = status == OrderStatus.cancelled;

    late final IconData icon;
    late final Color color;
    late final String title;
    late final String subtitle;

    if (cancelled) {
      icon = Icons.cancel_outlined;
      color = AppColors.sale;
      title = 'Đơn hàng đã huỷ';
      subtitle = 'Đơn hàng đã huỷ hoặc thanh toán không thành công.';
    } else if (paid) {
      icon = Icons.verified_outlined;
      color = AppColors.success;
      title = 'Thanh toán thành công';
      subtitle = 'Cảm ơn bạn! Chúng tôi đang chuẩn bị đơn cho bạn.';
    } else if (method == PaymentMethod.vnpay) {
      icon = Icons.schedule;
      color = AppColors.info;
      title = 'Đang chờ thanh toán';
      subtitle = 'Hoàn tất thanh toán VNPay để xác nhận đơn hàng nhé.';
    } else {
      icon = Icons.celebration_outlined;
      color = AppColors.accentPinkDeep;
      title = 'Đặt hàng thành công!';
      subtitle = 'Bạn sẽ trả tiền mặt cho shipper khi nhận hàng.';
    }

    return Column(
      children: [
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, size: 42, color: color),
        ),
        const SizedBox(height: 14),
        Text(title, style: AppTypography.headingLg, textAlign: TextAlign.center),
        const SizedBox(height: 6),
        Text(subtitle,
            style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    final label = switch (status) {
      OrderStatus.pending => 'Chờ thanh toán',
      OrderStatus.confirmed => 'Đã xác nhận',
      OrderStatus.processing => 'Đang xử lý',
      OrderStatus.shipped => 'Đang giao',
      OrderStatus.delivered => 'Đã giao',
      OrderStatus.cancelled => 'Đã huỷ',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      child: Text(label,
          style: AppTypography.utilityXs.copyWith(color: color)),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});
  final OrderItemDTO item;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.productName,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('SL ${item.quantity} · ${Formatters.vnd(item.unitPrice)}',
                  style:
                      AppTypography.captionSm.copyWith(color: AppColors.mute)),
            ],
          ),
        ),
        Text(Formatters.vnd(item.subTotal),
            style: AppTypography.bodyStrong),
      ],
    );
  }
}

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.info, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: AppTypography.captionMd.copyWith(color: AppColors.ash)),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.awaitingPayment,
    required this.payingAgain,
    required this.onPayAgain,
    required this.onRefresh,
    required this.onDone,
  });

  final bool awaitingPayment;
  final bool payingAgain;
  final VoidCallback onPayAgain;
  final VoidCallback onRefresh;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        boxShadow: [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
          20, 14, 20, 14 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (awaitingPayment) ...[
            _FilledButton(
              label: 'Thanh toán lại bằng VNPay',
              icon: Icons.open_in_new,
              busy: payingAgain,
              onTap: onPayAgain,
            ),
            const SizedBox(height: 10),
            _FilledButton(
              label: 'Đã thanh toán — cập nhật',
              icon: Icons.refresh,
              filled: false,
              onTap: onRefresh,
            ),
            const SizedBox(height: 10),
          ],
          _FilledButton(
            label: 'Về trang chủ',
            filled: !awaitingPayment,
            onTap: onDone,
          ),
        ],
      ),
    );
  }
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({
    required this.label,
    required this.onTap,
    this.icon,
    this.filled = true,
    this.busy = false,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool filled;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? AppColors.onPrimary : AppColors.ink;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: filled ? AppColors.ink : AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: filled
            ? null
            : Border.all(color: AppColors.hairline, width: 1.4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.full),
          onTap: busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: busy
                ? SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 18, color: fg),
                        const SizedBox(width: 8),
                      ],
                      Text(label,
                          style: AppTypography.buttonMd.copyWith(color: fg)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────── Shared ───────────────────────────

class _Card extends StatelessWidget {
  const _Card({required this.child, this.padding = const EdgeInsets.all(14)});
  final Widget child;
  final EdgeInsets padding;
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      padding: padding,
      child: child,
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
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
            const Icon(Icons.error_outline, size: 44, color: AppColors.sale),
            const SizedBox(height: 12),
            Text(message,
                style: AppTypography.bodyMd.copyWith(color: AppColors.ash),
                textAlign: TextAlign.center),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      ),
    );
  }
}
