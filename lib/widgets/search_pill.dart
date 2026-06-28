import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SearchPill extends StatelessWidget {
  const SearchPill({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onSubmitted,
    this.autoFocus = false,
    this.onTap,
    this.readOnly = false,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autoFocus;
  final VoidCallback? onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final inner = Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.softCloud,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          const Icon(Icons.search, color: AppColors.ink, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              autofocus: autoFocus,
              readOnly: readOnly,
              onChanged: onChanged,
              onSubmitted: onSubmitted,
              onTap: onTap,
              style: AppTypography.bodyMd.copyWith(color: AppColors.ink),
              cursorColor: AppColors.ink,
              decoration: InputDecoration(
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                hintText: hint,
                hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.mute),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
    return inner;
  }
}
