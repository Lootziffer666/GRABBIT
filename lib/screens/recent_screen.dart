import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';
import '../services/platform_index_service.dart';
import '../widgets/file_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chip.dart';
import '../widgets/multi_select_bar.dart';
import '../widgets/sharesheet_brain.dart';
import 'text_viewer_screen.dart';

/// The GRABBIT start screen: Recent files first.
/// Now with Multi-Select mode (Longpress → Selection) and
/// TextViewer integration (tap on text files → opens viewer).
class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final _searchController = TextEditingController();
  FileCategory? _selectedCategory;

  // Multi-select state
  bool _multiSelectActive = false;
  final Set<int> _selectedFileIds = {};

  final List<IndexedFile> _files = [];
  bool _scanning = true;
  String? _scanError;

  // Text-viewable extensions
  static const _textExtensions = {
    'txt', 'md', 'json', 'yaml', 'yml', 'xml', 'csv',
    'dart', 'kt', 'java', 'py', 'js', 'ts', 'html', 'css', 'sh',
    'log', 'ini', 'conf', 'toml', 'env', 'gitignore',
  };

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFiles() async {
    setState(() { _scanning = true; _scanError = null; });
    try {
      final scanned = await PlatformIndexService.instance.scanAll();
      if (!mounted) return;
      setState(() {
        _files
          ..clear()
          ..addAll(scanned.indexed.map((item) => IndexedFile(
            id: item.$1 + 1,
            path: item.$2.path,
            name: item.$2.name,
            ext: item.$2.ext,
            size: item.$2.size,
            modified: item.$2.modified,
            created: item.$2.created,
            parent: item.$2.parent,
            source: item.$2.source,
            mime: item.$2.mime,
          )));
        _scanning = false;
      });
    } catch (error) {
      if (mounted) setState(() { _scanning = false; _scanError = error.toString(); });
    }
  }

  // ── Multi-Select Logic ──────────────────────────────────────────────────

  void _enterMultiSelect(IndexedFile file) {
    HapticFeedback.mediumImpact();
    setState(() {
      _multiSelectActive = true;
      _selectedFileIds.add(file.id);
    });
  }

  void _toggleSelection(IndexedFile file) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedFileIds.contains(file.id)) {
        _selectedFileIds.remove(file.id);
        if (_selectedFileIds.isEmpty) _multiSelectActive = false;
      } else {
        _selectedFileIds.add(file.id);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _multiSelectActive = false;
      _selectedFileIds.clear();
    });
  }

  void _selectRange(IndexedFile file) {
    // Range select: from last selected to this file
    final filtered = _filteredFiles();
    if (_selectedFileIds.isEmpty) return;

    final lastIdx = filtered.indexWhere(
        (f) => f.id == _selectedFileIds.last);
    final thisIdx = filtered.indexOf(file);
    if (lastIdx < 0 || thisIdx < 0) return;

    final start = lastIdx < thisIdx ? lastIdx : thisIdx;
    final end = lastIdx < thisIdx ? thisIdx : lastIdx;

    setState(() {
      for (var i = start; i <= end; i++) {
        _selectedFileIds.add(filtered[i].id);
      }
    });
  }

  // ── File Tap Actions ────────────────────────────────────────────────────

  void _onFileTap(IndexedFile file) {
    if (_multiSelectActive) {
      _toggleSelection(file);
      return;
    }

    // Check if text-viewable
    if (_textExtensions.contains(file.extension)) {
      _openTextViewer(file);
    } else {
      // For non-text files: show snackbar (will be platform intent later)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Öffne: ${file.name}')),
      );
    }
  }

  void _onFileLongPress(IndexedFile file) {
    if (_multiSelectActive) {
      // Range select when already in multi-select
      _selectRange(file);
    } else {
      // Enter multi-select mode
      _enterMultiSelect(file);
    }
  }

  void _openTextViewer(IndexedFile file) {
    // For demo: use contentText or a placeholder
    final content = file.contentText ??
        'Dateiinhalt von ${file.name}\n\n'
            'Diese Datei ist ${file.sizeFormatted} groß.\n\n'
            'In der echten App wird der Dateiinhalt hier geladen.';

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TextViewerScreen(
          content: content,
          fileName: file.name,
          filePath: file.path,
        ),
      ),
    );
  }

  void _showSharesheet(IndexedFile file) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SharesheetBrain(
        file: file,
        onDismiss: () => Navigator.pop(context),
      ),
    );
  }

  // ── Batch Actions ───────────────────────────────────────────────────────

  void _batchMove() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedFileIds.length} Dateien verschieben...')),
    );
    _clearSelection();
  }

  void _batchCopy() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${_selectedFileIds.length} Dateien kopieren...')),
    );
    _clearSelection();
  }

  void _batchDelete() {
    // Show confirmation with GooeyButton-style hold
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: GrabbitColors.surface,
        title: const Text('Löschen?',
            style: TextStyle(color: GrabbitColors.t1)),
        content: Text(
          '${_selectedFileIds.length} Dateien endgültig löschen?',
          style: const TextStyle(color: GrabbitColors.t2),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${_selectedFileIds.length} Dateien gelöscht')),
              );
              _clearSelection();
            },
            child: const Text('Löschen',
                style: TextStyle(color: GrabbitColors.red)),
          ),
        ],
      ),
    );
  }

  void _batchShare() {
    if (_selectedFileIds.length == 1) {
      final file = _files.firstWhere((f) => f.id == _selectedFileIds.first);
      _showSharesheet(file);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedFileIds.length} Dateien als Bundle teilen...')),
      );
    }
    _clearSelection();
  }

  void _batchMore() {
    showModalBottomSheet(
      context: context,
      backgroundColor: GrabbitColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: GrabbitColors.t4, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            ListTile(leading: const Icon(Icons.folder_zip_rounded, color: GrabbitColors.yellow), title: const Text('Als ZIP komprimieren'), onTap: () { Navigator.pop(context); _clearSelection(); }),
            ListTile(leading: const Icon(Icons.drive_file_rename_outline_rounded, color: GrabbitColors.orange), title: const Text('Umbenennen'), onTap: () { Navigator.pop(context); _clearSelection(); }),
            ListTile(leading: const Icon(Icons.content_copy_rounded, color: GrabbitColors.cyan), title: const Text('Duplikate prüfen'), onTap: () { Navigator.pop(context); _clearSelection(); }),
            ListTile(leading: const Icon(Icons.folder_rounded, color: GrabbitColors.lime), title: const Text('In Projektordner sortieren'), onTap: () { Navigator.pop(context); _clearSelection(); }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header (changes in multi-select mode)
            _multiSelectActive
                ? _buildMultiSelectHeader()
                : _buildNormalHeader(),

            // Search bar (hidden in multi-select)
            if (!_multiSelectActive)
              GrabbitSearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
              ),

            // Category filter chips (hidden in multi-select)
            if (!_multiSelectActive)
              SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _buildFilterChip(null, 'Alle'),
                    for (final cat in FileCategory.values)
                      if (cat != FileCategory.other)
                        _buildFilterChip(cat, null),
                  ],
                ),
              ),

            const SizedBox(height: 4),

            // File list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ScrollReveal(
                        delay: Duration(milliseconds: i * 40),
                        child: FileCard(
                          file: filtered[i],
                          selected: _selectedFileIds.contains(filtered[i].id),
                          onTap: () => _onFileTap(filtered[i]),
                          onLongPress: () => _onFileLongPress(filtered[i]),
                        ),
                      ),
                    ),
            ),

            // Multi-select batch action bar
            if (_multiSelectActive)
              MultiSelectBar(
                selectedCount: _selectedFileIds.length,
                onMove: _batchMove,
                onCopy: _batchCopy,
                onDelete: _batchDelete,
                onShare: _batchShare,
                onMore: _batchMore,
                onClearSelection: _clearSelection,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNormalHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Text(
            'GRABBIT',
            style: GoogleFonts.lilitaOne(fontSize: 28, color: GrabbitColors.t1),
          ),
          const Spacer(),
          GestureDetector(
            onTap: _loadFiles,
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: GrabbitColors.turquoise.withAlpha(20),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: GrabbitColors.turquoise.withAlpha(60)),
            ),
            child: Text(
              _scanning ? 'Scanne…' : '${_files.length} Dateien',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11, fontWeight: FontWeight.w700, color: GrabbitColors.turquoise,
              ),
            ),
          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiSelectHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: _clearSelection,
            child: const Icon(Icons.close_rounded, color: GrabbitColors.t1, size: 24),
          ),
          const SizedBox(width: 16),
          Text(
            '${_selectedFileIds.length} ausgewählt',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: GrabbitColors.t1),
          ),
          const Spacer(),
          // Select all button
          GestureDetector(
            onTap: () {
              setState(() {
                final filtered = _filteredFiles();
                _selectedFileIds.addAll(filtered.map((f) => f.id));
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: GrabbitColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: GrabbitColors.borderStrong),
              ),
              child: const Text('Alle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: GrabbitColors.t2)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(FileCategory? cat, String? label) {
    if (cat == null) {
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() => _selectedCategory = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedCategory == null ? GrabbitColors.turquoise.withAlpha(30) : GrabbitColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _selectedCategory == null ? GrabbitColors.turquoise : GrabbitColors.borderStrong),
            ),
            child: Text(label ?? 'Alle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _selectedCategory == null ? GrabbitColors.turquoise : GrabbitColors.t3)),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: CategoryChip(
        category: cat,
        selected: _selectedCategory == cat,
        onTap: () => setState(() {
          _selectedCategory = _selectedCategory == cat ? null : cat;
        }),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off_rounded, size: 48, color: GrabbitColors.t4),
          const SizedBox(height: 12),
          Text('Keine Dateien gefunden', style: Theme.of(context).textTheme.bodyLarge),
        ],
      ),
    );
  }

  List<IndexedFile> _filteredFiles() {
    var files = _files;
    if (_selectedCategory != null) {
      files = files.where((f) => f.category == _selectedCategory).toList();
    }
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      files = files.where((f) => f.name.toLowerCase().contains(query) || (f.contentText?.toLowerCase().contains(query) ?? false)).toList();
    }
    return files;
  }

  List<IndexedFile> _generateDemoFiles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      IndexedFile(id: 1, path: '/storage/emulated/0/Download/Rechnung_2026.pdf', name: 'Rechnung_2026.pdf', ext: 'pdf', size: 2100000, modified: now - 120000, created: now - 120000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/pdf', contentText: 'Rechnung Nr. 4421 Versicherung monatlich'),
      IndexedFile(id: 2, path: '/storage/emulated/0/DCIM/Camera/IMG_20260628.jpg', name: 'IMG_20260628.jpg', ext: 'jpg', size: 4800000, modified: now - 300000, created: now - 300000, parent: '/storage/emulated/0/DCIM/Camera', source: 'camera', mime: 'image/jpeg'),
      IndexedFile(id: 3, path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_1642.png', name: 'Screenshot_1642.png', ext: 'png', size: 1800000, modified: now - 600000, created: now - 600000, parent: '/storage/emulated/0/Pictures/Screenshots', source: 'screenshot', mime: 'image/png', contentIndexed: 2, contentText: 'API Key: sk-1234 Token Balance 42.50'),
      IndexedFile(id: 4, path: '/storage/emulated/0/Download/project_notes.md', name: 'project_notes.md', ext: 'md', size: 15000, modified: now - 900000, created: now - 3600000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/markdown', contentIndexed: 1, contentText: 'GRABBIT MVP architecture decisions flutter sqlite fts5\n\nDer Index wird einmal aufgebaut und dann nur noch inkrementell aktualisiert.\n\nDas Everything-Prinzip bedeutet: nie wieder wartet der Nutzer auf Filesystem-Reads.\n\nAlle Queries laufen gegen SQLite mit FTS5 — Ergebnisse in unter 5ms.'),
      IndexedFile(id: 5, path: '/storage/emulated/0/Download/backup_2026.zip', name: 'backup_2026.zip', ext: 'zip', size: 156000000, modified: now - 1800000, created: now - 1800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/zip'),
      IndexedFile(id: 6, path: '/storage/emulated/0/WhatsApp/Media/Audio/voice_note.ogg', name: 'voice_note.ogg', ext: 'ogg', size: 340000, modified: now - 3600000, created: now - 3600000, parent: '/storage/emulated/0/WhatsApp/Media/Audio', source: 'whatsapp', mime: 'audio/ogg'),
      IndexedFile(id: 7, path: '/storage/emulated/0/Download/app-release.apk', name: 'app-release.apk', ext: 'apk', size: 45000000, modified: now - 7200000, created: now - 7200000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/vnd.android.package-archive'),
      IndexedFile(id: 8, path: '/storage/emulated/0/Documents/chatgpt_export.json', name: 'chatgpt_export.json', ext: 'json', size: 890000, modified: now - 10800000, created: now - 10800000, parent: '/storage/emulated/0/Documents', source: 'chatgpt', mime: 'application/json', contentIndexed: 1, contentText: 'conversation about flutter design systems animations\n\nUser: Wie baue ich elastic liquid motion in Flutter?\n\nAssistant: Die FLUBBER Motion Grammar definiert 18 Animationskomponenten...'),
      IndexedFile(id: 9, path: '/storage/emulated/0/DCIM/Camera/VID_20260627.mp4', name: 'VID_20260627.mp4', ext: 'mp4', size: 98000000, modified: now - 86400000, created: now - 86400000, parent: '/storage/emulated/0/DCIM/Camera', source: 'camera', mime: 'video/mp4'),
      IndexedFile(id: 10, path: '/storage/emulated/0/Download/shader_code.dart', name: 'shader_code.dart', ext: 'dart', size: 4200, modified: now - 172800000, created: now - 172800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/x-dart', contentIndexed: 1, contentText: 'import \'package:flutter/material.dart\';\n\n/// Custom shader for liquid blob effect.\nclass LiquidBlobShader extends CustomPainter {\n  @override\n  void paint(Canvas canvas, Size size) {\n    // Gooey blob implementation\n  }\n}'),
      IndexedFile(id: 11, path: '/storage/emulated/0/Telegram/Documents/invoice_may.pdf', name: 'invoice_may.pdf', ext: 'pdf', size: 520000, modified: now - 259200000, created: now - 259200000, parent: '/storage/emulated/0/Telegram/Documents', source: 'telegram', mime: 'application/pdf', contentIndexed: 1, contentText: 'Invoice May 2026 hosting services total EUR 49.90'),
      IndexedFile(id: 12, path: '/storage/emulated/0/Music/podcast_ep42.mp3', name: 'podcast_ep42.mp3', ext: 'mp3', size: 67000000, modified: now - 345600000, created: now - 345600000, parent: '/storage/emulated/0/Music', source: 'download', mime: 'audio/mpeg'),
    ];
  }
}
