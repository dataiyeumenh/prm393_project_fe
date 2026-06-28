import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class PrimaryNavBar extends StatelessWidget {
  const PrimaryNavBar({
    super.key,
    required this.title,
    this.leading,
    this.actions,
    this.showSearch = false,
    this.searchChild,
    this.bottom,
  });

  final String title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showSearch;
  final Widget? searchChild;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.canvas,
      surfaceTintColor: AppColors.canvas,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: 64,
      leading: leading,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: AppTypography.headingLg,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      actions: actions,
      bottom: bottom ??
          (showSearch
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: searchChild ?? const SizedBox.shrink(),
                  ),
                )
              : null),
    );
  }
}

class AppLogo extends StatelessWidget {
  const AppLogo({super.key, this.size = 32});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.pets,
            color: AppColors.onPrimary,
            size: size * 0.55,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          'PAWFUEL',
          style: AppTypography.bodyStrong.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
