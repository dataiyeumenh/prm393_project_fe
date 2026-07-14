import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class DisclosureRow extends StatefulWidget {
  const DisclosureRow({
    super.key,
    required this.label,
    required this.child,
    this.initiallyOpen = false,
  });

  final String label;
  final Widget child;
  final bool initiallyOpen;

  @override
  State<DisclosureRow> createState() => _DisclosureRowState();
}

class _DisclosureRowState extends State<DisclosureRow> {
  late bool _open = widget.initiallyOpen;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _open = !_open),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.bodyStrong,
                  ),
                ),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 180),
                  turns: _open ? 0.5 : 0,
                  child: const Icon(
                    Icons.keyboard_arrow_down,
                    color: AppColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _open
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SizedBox(
                width: double.infinity,
                child: widget.child,
              ),
            ),
          ),
        ),
        const Divider(height: 1, color: AppColors.hairline),
      ],
    );
  }
}
