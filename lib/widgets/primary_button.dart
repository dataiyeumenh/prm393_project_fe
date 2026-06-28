import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

enum PrimaryButtonVariant { primary, secondary, outlineOnImage, danger }

class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = PrimaryButtonVariant.primary,
    this.expand = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final PrimaryButtonVariant variant;
  final bool expand;
  final IconData? icon;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _pressed = false;

  Color _bg() {
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
      case PrimaryButtonVariant.danger:
        return AppColors.ink;
      case PrimaryButtonVariant.secondary:
        return AppColors.softCloud;
      case PrimaryButtonVariant.outlineOnImage:
        return AppColors.canvas;
    }
  }

  Color _fg() {
    switch (widget.variant) {
      case PrimaryButtonVariant.primary:
      case PrimaryButtonVariant.danger:
        return AppColors.onPrimary;
      case PrimaryButtonVariant.secondary:
      case PrimaryButtonVariant.outlineOnImage:
        return AppColors.ink;
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    final btn = AnimatedScale(
      scale: _pressed ? 0.96 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: AnimatedOpacity(
        opacity: _pressed ? 0.7 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Material(
          color: disabled ? AppColors.stone : _bg(),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: disabled
                ? null
                : () {
                    setState(() => _pressed = true);
                    Future.delayed(const Duration(milliseconds: 120), () {
                      if (mounted) setState(() => _pressed = false);
                      widget.onPressed?.call();
                    });
                  },
            child: Container(
              height: 48,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, size: 18, color: _fg()),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    widget.label,
                    style: AppTypography.buttonMd.copyWith(color: _fg()),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return widget.expand ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
