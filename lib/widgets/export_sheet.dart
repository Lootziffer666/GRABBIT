import 'package:flutter/material.dart';

import '../theme/grabbit_colors.dart';
import '../services/text_export_service.dart';

/// Bottom sheet for export options: Markdown, split by chars.
class ExportSheet extends StatefulWidget {
  const ExportSheet({
    super.key,
    required this.text,
    required this.fileName,
    required this.isSelection,
    this.paragraphs,
    this.selStart,
    this.selEnd,
  });

  final String text;
  final String fileName;
  final bool isSelection;
  final List<String>? paragraphs;
  final int? selStart;
  final int? selEnd;

  @override
  State<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<ExportSheet> {
  bool _splitEnabled = false;
  int _splitChars = 4000;
  bool _exporting = false;
  String? _resultMessage;

  final _splitOptions = [2000, 4000, 8000, 16000, 32000, 64000];

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
            // Handle bar
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

            // Title
            Text(
              widget.isSelection
                  ? 'Auswahl exportieren'
                  : 'Alles exportieren',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: GrabbitColors.t1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${widget.text.length} Zeichen'
              '${widget.isSelection && widget.selStart != null ? " · Absätze ${widget.selStart! + 1}–${widget.selEnd! + 1}" : ""}',
              style: const TextStyle(
                fontSize: 12,
                color: GrabbitColors.t3,
              ),
            ),
            const SizedBox(height: 20),

            // Export as Markdown (single file)
            _ExportOption(
              icon: Icons.description_rounded,
              label: 'Als Markdown (.md)',
              subtitle: 'Eine Datei, vollständig',
              onTap: _exportSingleMarkdown,
            ),
            const SizedBox(height: 8),

            // Split toggle
            _ExportOption(
              icon: Icons.vertical_split_rounded,
              label: 'Split in Teile',
              subtitle: _splitEnabled
                  ? 'Max $_splitChars Zeichen pro Teil'
                  : 'Für LLM-Kontextfenster, Clipboard-Limits',
              trailing: Switch(
                value: _splitEnabled,
                onChanged: (v) => setState(() => _splitEnabled = v),
                activeColor: GrabbitColors.turquoise,
              ),
              onTap: () => setState(() => _splitEnabled = !_splitEnabled),
            ),

            // Split size selector (visible when split enabled)
            if (_splitEnabled) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _splitOptions.map((size) {
                  final selected = _splitChars == size;
                  return GestureDetector(
                    onTap: () => setState(() => _splitChars = size),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? GrabbitColors.turquoise.withAlpha(30)
                            : GrabbitColors.card,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: selected
                              ? GrabbitColors.turquoise
                              : GrabbitColors.borderStrong,
                        ),
                      ),
                      child: Text(
                        _formatSize(size),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? GrabbitColors.turquoise
                              : GrabbitColors.t2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              Text(
                '→ ${(widget.text.length / _splitChars).ceil()} Teile',
                style: const TextStyle(
                  fontSize: 11,
                  color: GrabbitColors.t3,
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ],

            const SizedBox(height: 20),

            // Export button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _exporting ? null : _doExport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: GrabbitColors.turquoise,
                  foregroundColor: GrabbitColors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _exporting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: GrabbitColors.white,
                        ),
                      )
                    : Text(
                        _splitEnabled
                            ? 'Split exportieren'
                            : 'Exportieren',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),

            // Result message
            if (_resultMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                _resultMessage!,
                style: const TextStyle(
                  fontSize: 12,
                  color: GrabbitColors.stable,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _exportSingleMarkdown() async {
    setState(() => _exporting = true);
    try {
      final service = TextExportService.instance;
      String path;

      if (widget.isSelection &&
          widget.paragraphs != null &&
          widget.selStart != null &&
          widget.selEnd != null) {
        path = await service.exportSelectionToMarkdown(
          paragraphs: widget.paragraphs!,
          startIndex: widget.selStart!,
          endIndex: widget.selEnd!,
          baseFileName: widget.fileName,
        );
      } else {
        path = await service.exportToMarkdown(
          text: widget.text,
          baseFileName: widget.fileName,
          title: widget.fileName,
        );
      }

      setState(() {
        _resultMessage = 'Gespeichert: $path';
        _exporting = false;
      });
    } catch (e) {
      setState(() {
        _resultMessage = 'Fehler: $e';
        _exporting = false;
      });
    }
  }

  Future<void> _doExport() async {
    if (_splitEnabled) {
      setState(() => _exporting = true);
      try {
        final result = await TextExportService.instance.exportAllSplit(
          text: widget.text,
          baseFileName: widget.fileName,
          maxChars: _splitChars,
        );
        setState(() {
          _resultMessage =
              '${result.chunkCount} Dateien erstellt '
              '(${_formatSize(result.maxCharsPerChunk)} pro Teil)';
          _exporting = false;
        });
      } catch (e) {
        setState(() {
          _resultMessage = 'Fehler: $e';
          _exporting = false;
        });
      }
    } else {
      await _exportSingleMarkdown();
    }
  }

  String _formatSize(int chars) {
    if (chars >= 1000) return '${chars ~/ 1000}k';
    return '$chars';
  }
}

class _ExportOption extends StatelessWidget {
  const _ExportOption({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: GrabbitColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: GrabbitColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: GrabbitColors.t2),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: GrabbitColors.t1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      color: GrabbitColors.t3,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
