import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/grabbit_colors.dart';

/// Batch action bar — appears at the bottom when multi-select is active.
///
/// Shows: selected count + actions (Move, Copy, Delete, Share, Zip, Rename).
/// Designed per GRABBIT spec: Batch-Aktionen for files and folders.
class MultiSelectBar extends StatelessWidget {
  const MultiSelectBar({
    super.key,
    required this.selectedCount,
    required this.onMove,
    required this.onCopy,
    required this.onDelete,
    required this.onShare,
    required this.onMore,
    required this.onClearSelection,
  });

  final int selectedCount;
  final VoidCallback onMove;
  final VoidCallback onCopy;
  final VoidCallback onDelete;
  final VoidCallback onShare;
  final VoidCallback onMore;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: GrabbitColors.surface,
        border: const Border(
          top: BorderSide(color: GrabbitColors.borderStrong),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Selection badge
            GestureDetector(
              onTap: onClearSelection,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: GrabbitColors.turquoise.withAlpha(25),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                      color: GrabbitColors.turquoise.withAlpha(80)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selectedCount',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.turquoise,
                        fontFamily: 'JetBrains Mono',
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.close_rounded,
                        size: 14, color: GrabbitColors.turquoise),
                  ],
                ),
              ),
            ),
            const Spacer(),
            // Actions
            _ActionButton(
              icon: Icons.drive_file_move_rounded,
              label: 'Move',
              onTap: onMove,
            ),
            _ActionButton(
              icon: Icons.copy_rounded,
              label: 'Copy',
              onTap: onCopy,
            ),
            _ActionButton(
              icon: Icons.share_rounded,
              label: 'Share',
              onTap: onShare,
            ),
            _ActionButton(
              icon: Icons.delete_outline_rounded,
              label: 'Delete',
              onTap: onDelete,
              color: GrabbitColors.red,
            ),
            _ActionButton(
              icon: Icons.more_horiz_rounded,
              label: 'Mehr',
              onTap: onMore,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? GrabbitColors.t1;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: c),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: c,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
