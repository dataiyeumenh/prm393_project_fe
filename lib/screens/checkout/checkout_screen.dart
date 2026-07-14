import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/api/address_dto.dart';
import '../../models/api/cart_dto.dart';
import '../../models/api/order_dto.dart';
import '../../services/address_service.dart';
import '../../services/order_service.dart';
import '../../services/payment_service.dart';
import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../utils/formatters.dart';
import 'address_form_sheet.dart';
import 'order_status_screen.dart';
import 'payment_webview_screen.dart';

enum PaymentMethod { vnpay, cod }

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _noteController = TextEditingController();

  List<AddressDTO> _addresses = [];
  AddressDTO? _selectedAddress;
  PaymentMethod _method = PaymentMethod.vnpay;

  bool _loadingAddresses = true;
  bool _placingOrder = false;
  String? _addressError;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loadingAddresses = true;
      _addressError = null;
    });
    final result = await AddressService.getMyAddresses();
    if (!mounted) return;
    setState(() {
      _loadingAddresses = false;
      if (result.isSuccess) {
        _addresses = result.data!;
        _selectedAddress = _addresses.isEmpty
            ? null
            : _addresses.firstWhere(
                (a) => a.isDefault,
                orElse: () => _addresses.first,
              );
      } else {
        _addressError = result.error;
      }
    });
  }

  Future<void> _pickAddress() async {
    final selected = await showModalBottomSheet<AddressDTO>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddressPickerSheet(
        addresses: _addresses,
        selectedId: _selectedAddress?.id,
      ),
    );
    if (selected == null) return;
    if (selected.id == _kAddNewSentinel) {
      await _addAddress();
    } else {
      setState(() => _selectedAddress = selected);
    }
  }

  Future<void> _addAddress() async {
    final created = await showModalBottomSheet<AddressDTO>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddressFormSheet(),
    );
    if (created == null || !mounted) return;
    setState(() {
      _addresses = [created, ..._addresses];
      _selectedAddress = created;
    });
  }

  Future<void> _placeOrder() async {
    final cart = context.read<CartState>();
    if (cart.isEmpty) return;
    if (_selectedAddress == null) {
      _snack('Vui lòng chọn địa chỉ giao hàng trước nhé.');
      return;
    }

    setState(() => _placingOrder = true);

    // 1. Mirror the local cart onto the server cart.
    final items = cart.lines
        .map((l) => CartItemRequest(productId: l.product.id, quantity: l.quantity))
        .toList();
    final sync = await OrderService.syncCart(items);
    if (!mounted) return;
    if (!sync.isSuccess) {
      setState(() => _placingOrder = false);
      _snack(sync.error ?? 'Không đồng bộ được giỏ hàng.');
      return;
    }

    // 2. Create the order.
    final checkout = await OrderService.checkout(
      CheckoutRequest(
        addressId: _selectedAddress!.id,
        note: _noteController.text,
      ),
    );
    if (!mounted) return;
    if (!checkout.isSuccess) {
      setState(() => _placingOrder = false);
      _snack(checkout.error ?? 'Đặt hàng thất bại.');
      return;
    }
    final order = checkout.data!;

    // 3. For online payment, create the VNPay URL and open it in an
    //    in-app WebView. The WebView pops with the vnp_ResponseCode.
    String? paymentUrl;
    if (_method == PaymentMethod.vnpay) {
      final pay = await PaymentService.createVnpayUrl(order.id);
      if (!mounted) return;
      if (!pay.isSuccess) {
        setState(() => _placingOrder = false);
        _snack(pay.error ?? 'Không tạo được liên kết VNPay.');
        return;
      }
      paymentUrl = pay.data!.paymentUrl;
      await Navigator.of(context).push<String>(
        MaterialPageRoute(
          builder: (_) => PaymentWebViewScreen(paymentUrl: paymentUrl!),
        ),
      );
      if (!mounted) return;
    }

    // Order is now on the server — clear the local cart and show status.
    cart.clear();
    if (!mounted) return;
    setState(() => _placingOrder = false);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => OrderStatusScreen(
          orderId: order.id,
          method: _method,
          paymentUrl: paymentUrl,
        ),
      ),
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ink,
        content: Text(message, style: AppTypography.bodyMd.copyWith(color: AppColors.onPrimary)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: AppBar(
        backgroundColor: AppColors.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Thanh toán', style: AppTypography.headingLg),
      ),
      body: AppBackground(
        child: cart.isEmpty
            ? Center(
                child: Text(
                  'Giỏ hàng của bạn đang trống.',
                  style: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _SectionLabel('Địa chỉ giao hàng'),
                        const SizedBox(height: 8),
                        _AddressSection(
                          loading: _loadingAddresses,
                          error: _addressError,
                          address: _selectedAddress,
                          onTap: _selectedAddress == null && _addresses.isEmpty
                              ? _addAddress
                              : _pickAddress,
                          onRetry: _loadAddresses,
                        ),
                        const SizedBox(height: 24),
                        _SectionLabel('Tóm tắt đơn hàng'),
                        const SizedBox(height: 8),
                        _OrderSummaryCard(lines: cart.lines),
                        const SizedBox(height: 24),
                        _SectionLabel('Ghi chú cho tài xế (không bắt buộc)'),
                        const SizedBox(height: 8),
                        _NoteField(controller: _noteController),
                        const SizedBox(height: 24),
                        _SectionLabel('Phương thức thanh toán'),
                        const SizedBox(height: 8),
                        _PaymentMethodTile(
                          selected: _method == PaymentMethod.vnpay,
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'VNPay',
                          subtitle: 'Thanh toán online qua cổng VNPay',
                          onTap: () =>
                              setState(() => _method = PaymentMethod.vnpay),
                        ),
                        const SizedBox(height: 10),
                        _PaymentMethodTile(
                          selected: _method == PaymentMethod.cod,
                          icon: Icons.payments_outlined,
                          title: 'Thanh toán khi nhận hàng',
                          subtitle: 'Trả tiền mặt cho shipper khi nhận đồ',
                          onTap: () =>
                              setState(() => _method = PaymentMethod.cod),
                        ),
                      ],
                    ),
                  ),
                  _CheckoutBar(
                    subtotal: cart.subtotal,
                    shipping: cart.shipping,
                    total: cart.total,
                    busy: _placingOrder,
                    method: _method,
                    onPlaceOrder: _placeOrder,
                  ),
                ],
              ),
      ),
    );
  }
}

const String _kAddNewSentinel = '__add_new__';

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) {
    return Text(text, style: AppTypography.headingMd);
  }
}

// ─────────────────────────────────────── Address ──────────────────────────

class _AddressSection extends StatelessWidget {
  const _AddressSection({
    required this.loading,
    required this.error,
    required this.address,
    required this.onTap,
    required this.onRetry,
  });

  final bool loading;
  final String? error;
  final AddressDTO? address;
  final VoidCallback onTap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const _Card(
        child: SizedBox(
          height: 56,
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return _Card(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.sale),
            const SizedBox(width: 10),
            Expanded(
              child: Text(error!,
                  style: AppTypography.bodyMd.copyWith(color: AppColors.ash)),
            ),
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
          ],
        ),
      );
    }

    if (address == null) {
      return _Card(
        onTap: onTap,
        child: Row(
          children: [
            const Icon(Icons.add_location_alt_outlined,
                color: AppColors.accentPinkDeep),
            const SizedBox(width: 12),
            Expanded(
              child: Text('Thêm địa chỉ giao hàng',
                  style: AppTypography.bodyStrong),
            ),
            const Icon(Icons.chevron_right, color: AppColors.stone),
          ],
        ),
      );
    }

    return _Card(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.softCloud,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Icon(Icons.location_on_outlined,
                color: AppColors.accentPinkDeep, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(address!.receiverName,
                          style: AppTypography.bodyStrong,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width: 8),
                    Text(address!.phone,
                        style: AppTypography.captionSm
                            .copyWith(color: AppColors.mute)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(address!.streetAddress,
                    style:
                        AppTypography.bodyMd.copyWith(color: AppColors.ash)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text('Đổi',
              style: AppTypography.buttonSm
                  .copyWith(color: AppColors.accentPinkDeep)),
        ],
      ),
    );
  }
}

class _AddressPickerSheet extends StatelessWidget {
  const _AddressPickerSheet({required this.addresses, required this.selectedId});
  final List<AddressDTO> addresses;
  final String? selectedId;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.hairline,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text('Chọn địa chỉ', style: AppTypography.headingMd),
              ],
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: addresses.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final a = addresses[i];
                final selected = a.id == selectedId;
                return _Card(
                  onTap: () => Navigator.of(context).pop(a),
                  border: selected ? AppColors.accentPink : null,
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        color: selected
                            ? AppColors.accentPinkDeep
                            : AppColors.stone,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${a.receiverName}  ·  ${a.phone}',
                                style: AppTypography.bodyStrong,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(a.streetAddress,
                                style: AppTypography.captionSm
                                    .copyWith(color: AppColors.mute),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: _Card(
              onTap: () => Navigator.of(context).pop(
                AddressDTO(
                    id: _kAddNewSentinel,
                    receiverName: '',
                    phone: '',
                    streetAddress: ''),
              ),
              child: Row(
                children: [
                  const Icon(Icons.add, color: AppColors.accentPinkDeep),
                  const SizedBox(width: 12),
                  Text('Thêm địa chỉ mới', style: AppTypography.bodyStrong),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────── Summary ──────────────────────────

class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.lines});
  final List<CartLine> lines;

  @override
  Widget build(BuildContext context) {
    return _Card(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          for (int i = 0; i < lines.length; i++) ...[
            if (i > 0)
              const Divider(height: 20, color: AppColors.hairlineSoft),
            _SummaryLine(line: lines[i]),
          ],
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final p = line.product;
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: SizedBox(
            width: 56,
            height: 56,
            child: CachedNetworkImage(
              imageUrl: p.imageUrl,
              fit: BoxFit.cover,
              placeholder: (_, _) => Container(color: AppColors.softCloud),
              errorWidget: (_, _, _) => Container(
                color: AppColors.softCloud,
                alignment: Alignment.center,
                child: const Icon(Icons.pets, color: AppColors.stone, size: 18),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text('SL ${line.quantity}',
                  style:
                      AppTypography.captionSm.copyWith(color: AppColors.mute)),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(Formatters.vnd(line.subtotal),
            style: AppTypography.bodyStrong
                .copyWith(color: AppColors.accentPinkDeep)),
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: 3,
      minLines: 2,
      style: AppTypography.bodyMd,
      decoration: InputDecoration(
        hintText: 'Ví dụ: Gọi cho mình khi đến cổng nhé',
        filled: true,
        fillColor: AppColors.canvas,
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.hairlineSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.hairlineSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(color: AppColors.accentPink, width: 2),
        ),
      ),
    );
  }
}

// ──────────────────────────────────── Payment method ──────────────────────

class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _Card(
      onTap: onTap,
      border: selected ? AppColors.accentPink : null,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.accentPinkSoft : AppColors.softCloud,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            alignment: Alignment.center,
            child: Icon(icon,
                color: selected ? AppColors.accentPinkDeep : AppColors.ash),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyStrong),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: AppTypography.captionSm
                        .copyWith(color: AppColors.mute)),
              ],
            ),
          ),
          Icon(
            selected ? Icons.radio_button_checked : Icons.radio_button_off,
            color: selected ? AppColors.accentPinkDeep : AppColors.stone,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────── Bottom bar ───────────────────────

class _CheckoutBar extends StatelessWidget {
  const _CheckoutBar({
    required this.subtotal,
    required this.shipping,
    required this.total,
    required this.busy,
    required this.method,
    required this.onPlaceOrder,
  });

  final double subtotal;
  final double shipping;
  final double total;
  final bool busy;
  final PaymentMethod method;
  final VoidCallback onPlaceOrder;

  @override
  Widget build(BuildContext context) {
    final label =
        method == PaymentMethod.vnpay ? 'Thanh toán với VNPay' : 'Đặt hàng';
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
        20,
        16,
        20,
        16 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Row(label: 'Tạm tính', value: subtotal),
          const SizedBox(height: 6),
          _Row(
            label: shipping == 0 ? 'Vận chuyển (Miễn phí!)' : 'Vận chuyển',
            value: shipping,
            highlight: shipping == 0,
          ),
          const Divider(height: 24, color: AppColors.hairlineSoft),
          _Row(label: 'Tổng cộng', value: total, isBold: true),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.gradientStart, AppColors.accentPinkDeep],
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: busy ? null : onPlaceOrder,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.4,
                              valueColor: AlwaysStoppedAnimation(
                                  AppColors.onPrimary),
                            ),
                          )
                        : Text(
                            '$label  •  ${Formatters.vnd(total)}',
                            style: AppTypography.buttonLg
                                .copyWith(color: AppColors.onPrimary),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.label,
    required this.value,
    this.isBold = false,
    this.highlight = false,
  });
  final String label;
  final double value;
  final bool isBold;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: (isBold ? AppTypography.bodyStrong : AppTypography.bodyMd)
                  .copyWith(color: AppColors.charcoal)),
        ),
        Text(
          value == 0 && highlight ? 'Miễn phí' : Formatters.vnd(value),
          style: (isBold ? AppTypography.bodyStrong : AppTypography.bodyMd)
              .copyWith(
            color: highlight
                ? AppColors.success
                : (isBold ? AppColors.ink : AppColors.charcoal),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────── Shared card ──────────────────────

class _Card extends StatelessWidget {
  const _Card({
    required this.child,
    this.onTap,
    this.border,
    this.padding = const EdgeInsets.all(14),
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? border;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: border ?? AppColors.hairlineSoft,
          width: border != null ? 1.6 : 1,
        ),
      ),
      padding: padding,
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: onTap,
        child: card,
      ),
    );
  }
}
