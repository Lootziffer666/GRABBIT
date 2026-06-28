import 'package:flutter/material.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/border_beam.dart';
import '../theme/grabbit_colors.dart';
import '../theme/grabbit_design_bridge.dart';

/// Universal file card — the core UI primitive of GRABBIT.
/// Renders any IndexedFile with FLUBBER design tokens.
/// Shows: icon/thumbnail dot, filename, metadata, category chip.
/// BorderBeam activates on urgent states.
class FileCard extends StatelessWidget {
  const FileCard({
    super.key,
    required this.file,
    this.state = FileState.stable,
    this.onTap,
    this.onLongPress,
    this.selected = false,
  });

  final IndexedFile file;
  final FileState state;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool selected;

  static const _bridge = GrabbitDesignBridge.instance;

  @override
  Widget build(BuildContext context) {
    final catColor = _bridge.categoryColor(file.category);
    final catIcon = _bridge.categoryIcon(file.category);
    final showBeam = _bridge.stateBeamActive(state);
    final beamColor = _bridge.stateColor(state);

    return BorderBeam(
      active: showBeam,
      color: beamColor,
      child: Card(
        color: selected ? GrabbitColors.card.withAlpha(200) : GrabbitColors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: selected
                ? GrabbitColors.turquoise.withAlpha(180)
                : GrabbitColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // Category icon dot
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(catIcon, color: catColor, size: 20),
                ),
                const SizedBox(width: 12),
                // File info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        file.name,
                        style: Theme.of(context).textTheme.labelLarge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _subtitle(),
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Size + time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      file.sizeFormatted,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: GrabbitColors.t2,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _timeAgo(),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle() {
    final parts = <String>[];
    if (file.source != null && file.source!.isNotEmpty) {
      parts.add(FileSource.values
          .firstWhere(
            (s) => s.name == file.source,
            orElse: () => FileSource.unknown,
          )
          .label);
    }
    parts.add(file.extension.toUpperCase());
    return parts.join(' · ');
  }

  String _timeAgo() {
    final diff = DateTime.now().millisecondsSinceEpoch - file.modified;
    final minutes = diff ~/ 60000;
    if (minutes < 1) return 'gerade eben';
    if (minutes < 60) return 'vor $minutes min';
    final hours = minutes ~/ 60;
    if (hours < 24) return 'vor $hours Std';
    final days = hours ~/ 24;
    if (days == 1) return 'gestern';
    if (days < 7) return 'vor $days Tagen';
    if (days < 30) return 'vor ${days ~/ 7} Wochen';
    return 'vor ${days ~/ 30} Monaten';
  }
}
