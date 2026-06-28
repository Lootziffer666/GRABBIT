import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../theme/grabbit_colors.dart';

/// Sharesheet Brain — GRABBIT's custom share dialog.
///
/// Not Android's chaos Sharesheet. Instead:
/// - Rollen statt Kategorien (Öffnen/Bearbeiten/Teilen/Exportieren)
/// - Häufige Ziele oben
/// - Falsche Ziele ausblendbar
/// - Datei vorher prüfen (Typ, Größe, Inhaltstyp)
/// - Text statt Datei senden wenn sinnvoll
/// - Multiple Dateien als Bundle
class SharesheetBrain extends StatelessWidget {
  const SharesheetBrain({
    super.key,
    required this.file,
    required this.onDismiss,
  });

  final IndexedFile file;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: GrabbitColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: GrabbitColors.t4,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // File info header
            _buildFileHeader(),
            const SizedBox(height: 20),

            // Roles section
            const Text(
              'AKTION WÄHLEN',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: GrabbitColors.t3,
              ),
            ),
            const SizedBox(height: 10),

            // Role-based actions (not app categories!)
            _buildRoleGrid(),
            const SizedBox(height: 20),

            // Frequent targets
            const Text(
              'HÄUFIGE ZIELE',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
                color: GrabbitColors.t3,
              ),
            ),
            const SizedBox(height: 10),
            _buildFrequentTargets(),
            const SizedBox(height: 16),

            // Smart suggestion
            _buildSmartSuggestion(),
          ],
        ),
      ),
    );
  }

  Widget _buildFileHeader() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrabbitColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: GrabbitColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: GrabbitColors.orange.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.insert_drive_file_rounded,
                size: 20, color: GrabbitColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: GrabbitColors.t1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${file.extension.toUpperCase()} · ${file.sizeFormatted}',
                  style: const TextStyle(
                      fontSize: 11, color: GrabbitColors.t3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleGrid() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _roleChip(
          Icons.open_in_new_rounded,
          'Öffnen mit',
          GrabbitColors.turquoise,
          'Datei ansehen',
        ),
        _roleChip(
          Icons.edit_rounded,
          'Bearbeiten mit',
          GrabbitColors.orange,
          'Datei verändern',
        ),
        _roleChip(
          Icons.send_rounded,
          'Teilen an',
          GrabbitColors.violet,
          'Datei weitergeben',
        ),
        _roleChip(
          Icons.save_alt_rounded,
          'Exportieren nach',
          GrabbitColors.lime,
          'Format/Ziel ändern',
        ),
        _roleChip(
          Icons.folder_rounded,
          'Speichern in',
          GrabbitColors.yellow,
          'Datei ablegen',
        ),
        _roleChip(
          Icons.content_cut_rounded,
          'Extrahieren mit',
          GrabbitColors.cyan,
          'Inhalt herausziehen',
        ),
      ],
    );
  }

  Widget _roleChip(
      IconData icon, String label, Color color, String subtitle) {
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                      fontSize: 9, color: GrabbitColors.t3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFrequentTargets() {
    // Demo targets — will be learned from usage
    final targets = [
      _TargetApp('Telegram', Icons.send_rounded, GrabbitColors.cyan),
      _TargetApp('Files', Icons.folder_rounded, GrabbitColors.orange),
      _TargetApp('Gmail', Icons.email_rounded, GrabbitColors.red),
      _TargetApp('Drive', Icons.cloud_rounded, GrabbitColors.lime),
      _TargetApp('Copy Link', Icons.link_rounded, GrabbitColors.t2),
    ];

    return Row(
      children: targets
          .map((t) => Expanded(
                child: GestureDetector(
                  onTap: () => HapticFeedback.selectionClick(),
                  child: Column(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: t.color.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: t.color.withAlpha(60)),
                        ),
                        child:
                            Icon(t.icon, size: 20, color: t.color),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        t.label,
                        style: const TextStyle(
                            fontSize: 9,
                            color: GrabbitColors.t3,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildSmartSuggestion() {
    // Context-aware suggestion based on file type
    final suggestion = _getSuggestion();
    if (suggestion == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: GrabbitColors.turquoise.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: GrabbitColors.turquoise.withAlpha(40)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline_rounded,
              size: 16, color: GrabbitColors.turquoise),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              suggestion,
              style: const TextStyle(
                  fontSize: 12, color: GrabbitColors.t2),
            ),
          ),
        ],
      ),
    );
  }

  String? _getSuggestion() {
    if (file.size > 10 * 1024 * 1024) {
      return 'Große Datei — Link/Verweis statt Vollinhalt senden?';
    }
    if (file.contentText != null && file.contentText!.length < 5000) {
      return 'Textinhalt erkannt — als Text statt Datei teilen?';
    }
    if (file.extension == 'apk') {
      return 'APK erkannt — installieren oder als Datei teilen?';
    }
    return null;
  }
}

class _TargetApp {
  final String label;
  final IconData icon;
  final Color color;
  const _TargetApp(this.label, this.icon, this.color);
}
