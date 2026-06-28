import 'package:flutter/material.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../theme/grabbit_colors.dart';
import '../theme/grabbit_design_bridge.dart';

/// Filter chip for file categories — used on the Recent screen.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.category,
    required this.selected,
    required this.onTap,
    this.label,
  });

  final FileCategory category;
  final bool selected;
  final VoidCallback onTap;
  final String? label;

  static const _bridge = GrabbitDesignBridge.instance;

  @override
  Widget build(BuildContext context) {
    final color = _bridge.categoryColor(category);
    final icon = _bridge.categoryIcon(category);
    final text = label ?? _bridge.categoryLabel(category);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : GrabbitColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? color : GrabbitColors.borderStrong,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : GrabbitColors.t3),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? color : GrabbitColors.t3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
