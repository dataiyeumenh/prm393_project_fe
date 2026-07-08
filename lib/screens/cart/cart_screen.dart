import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';

import '../../state/cart_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/app_background.dart';
import '../../utils/formatters.dart';
import '../checkout/checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final lines = cart.lines;

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
        title: Text('Giỏ hàng', style: AppTypography.headingLg),
        actions: [
          if (!cart.isEmpty)
            TextButton(
              onPressed: cart.clear,
              child: Text(
                'Xóa hết',
                style: AppTypography.buttonSm.copyWith(color: AppColors.sale),
              ),
            ),
        ],
      ),
      body: AppBackground(
        child: cart.isEmpty
            ? const _EmptyCart()
            : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: lines.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _CartTile(line: lines[i]),
                  ),
                ),
                _CheckoutBar(),
              ],
            ),
      ),
    );
  }
}

class _CartTile extends StatelessWidget {
  const _CartTile({required this.line});
  final CartLine line;

  @override
  Widget build(BuildContext context) {
    final cart = context.read<CartState>();
    final p = line.product;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.canvas,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.hairlineSoft),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: 84,
              height: 84,
              child: CachedNetworkImage(
                imageUrl: p.imageUrl,
                fit: BoxFit.cover,
                placeholder: (_, _) => Container(color: AppColors.softCloud),
                errorWidget: (_, _, _) => Container(
                  color: AppColors.softCloud,
                  alignment: Alignment.center,
                  child: const Icon(Icons.pets, color: AppColors.stone),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: AppTypography.bodyStrong,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  p.subtitle,
                  style: AppTypography.captionSm.copyWith(color: AppColors.mute),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      Formatters.vnd(p.price),
                      style: AppTypography.bodyStrong
                          .copyWith(color: AppColors.accentPinkDeep),
                    ),
                    const Spacer(),
                    _QtyStepper(
                      qty: line.quantity,
                      onMinus: () => cart.decrement(p.id),
                      onPlus: () => cart.increment(p.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.qty,
    required this.onMinus,
    required this.onPlus,
  });
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.softCloud,
        borderRadius: BorderRadius.circular(AppRadius.full),
      ),
      padding: const EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QtyBtn(icon: Icons.remove, onTap: onMinus),
          SizedBox(
            width: 28,
            child: Center(
              child: Text(
                '$qty',
                style: AppTypography.buttonSm,
              ),
            ),
          ),
          _QtyBtn(icon: Icons.add, onTap: onPlus),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.full),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.canvas,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: AppColors.ink),
      ),
    );
  }
}

class _CheckoutBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
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
          _SummaryRow(label: 'Tạm tính', value: cart.subtotal),
          const SizedBox(height: 6),
          _SummaryRow(
            label: cart.shipping == 0 ? 'Vận chuyển (Miễn phí!)' : 'Vận chuyển',
            value: cart.shipping,
            highlight: cart.shipping == 0,
          ),
          const Divider(height: 24, color: AppColors.hairlineSoft),
          _SummaryRow(
            label: 'Tổng cộng',
            value: cart.total,
            isBold: true,
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.gradientStart,
                  AppColors.accentPinkDeep,
                ],
              ),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppRadius.full),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const CheckoutScreen(),
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: Text(
                      'Thanh toán  •  ${Formatters.vnd(cart.total)}',
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

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
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
          child: Text(
            label,
            style: (isBold ? AppTypography.bodyStrong : AppTypography.bodyMd)
                .copyWith(color: AppColors.charcoal),
          ),
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

class _EmptyCart extends StatelessWidget {
  const _EmptyCart();

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
                Icons.shopping_bag_outlined,
                size: 44,
                color: AppColors.accentPinkDeep,
              ),
            ),
            const SizedBox(height: 16),
            Text('Giỏ hàng của bạn đang trống',
                style: AppTypography.headingLg, textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              'Khám phá thêm sản phẩm và chọn vài món cho thú cưng của bạn nhé.',
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
                onTap: () => Navigator.of(context).pop(),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  child: Text(
                    'Mua sắm ngay',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
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