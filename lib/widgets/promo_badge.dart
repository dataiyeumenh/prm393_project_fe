import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PromoBadge extends StatelessWidget {
  const PromoBadge({super.key, required this.label, this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.ink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Text(
        label,
        style: AppTypography.captionSm.copyWith(color: AppColors.onPrimary),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.link,
    this.onLinkTap,
  });

  final String title;
  final String? link;
  final VoidCallback? onLinkTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: AppTypography.headingLg)),
          if (link != null)
            GestureDetector(
              onTap: onLinkTap,
              child: Text(
                link!,
                style: AppTypography.linkMd.copyWith(color: AppColors.ink),
              ),
            ),
        ],
      ),
    );
  }
}
