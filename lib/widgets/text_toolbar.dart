import 'package:flutter/material.dart';

import '../theme/grabbit_colors.dart';

/// Action toolbar shown when text paragraphs are selected.
/// Appears at the bottom — actions on the current selection.
class TextToolbar extends StatelessWidget {
  const TextToolbar({
    super.key,
    required this.onCopy,
    required this.onShare,
    required this.onSaveAs,
    required this.onClear,
    required this.selectedCount,
  });

  final VoidCallback onCopy;
  final VoidCallback onShare;
  final VoidCallback onSaveAs;
  final VoidCallback onClear;
  final int selectedCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: GrabbitColors.surface,
        border: const Border(
          top: BorderSide(color: GrabbitColors.border),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection badge
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: GrabbitColors.turquoise.withAlpha(25),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$selectedCount Absätze',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: GrabbitColors.turquoise,
                ),
              ),
            ),
            const Spacer(),
            // Copy
            _ToolbarButton(
              icon: Icons.copy_rounded,
              label: 'Kopieren',
              onTap: onCopy,
            ),
            const SizedBox(width: 8),
            // Share
            _ToolbarButton(
              icon: Icons.share_rounded,
              label: 'Teilen',
              onTap: onShare,
            ),
            const SizedBox(width: 8),
            // Save as
            _ToolbarButton(
              icon: Icons.save_alt_rounded,
              label: 'Speichern',
              onTap: onSaveAs,
            ),
            const SizedBox(width: 12),
            // Clear selection
            GestureDetector(
              onTap: onClear,
              child: const Icon(
                Icons.close_rounded,
                size: 20,
                color: GrabbitColors.t3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: GrabbitColors.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: GrabbitColors.borderStrong),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: GrabbitColors.t1),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GrabbitColors.t1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
