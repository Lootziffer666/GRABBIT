import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';
import '../widgets/file_card.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/category_chip.dart';

/// The GRABBIT start screen: Recent files first.
/// Not a folder tree. An Arbeitsstrom — newest files always on top.
/// Instant search via FTS5 index.
class RecentScreen extends StatefulWidget {
  const RecentScreen({super.key});

  @override
  State<RecentScreen> createState() => _RecentScreenState();
}

class _RecentScreenState extends State<RecentScreen> {
  final _searchController = TextEditingController();
  FileCategory? _selectedCategory;

  // Demo data — will be replaced by Riverpod + SQLite provider
  late final List<IndexedFile> _demoFiles;

  @override
  void initState() {
    super.initState();
    _demoFiles = _generateDemoFiles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredFiles();

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Text(
                    'GRABBIT',
                    style: GoogleFonts.lilitaOne(
                      fontSize: 28,
                      color: GrabbitColors.t1,
                    ),
                  ),
                  const Spacer(),
                  // File count badge
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GrabbitColors.turquoise.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: GrabbitColors.turquoise.withAlpha(60)),
                    ),
                    child: Text(
                      '${_demoFiles.length} Dateien',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.turquoise,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Search bar
            GrabbitSearchBar(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
            ),

            // Category filter chips
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
                          onTap: () => _onFileTap(filtered[i]),
                          onLongPress: () => _onFileLongPress(filtered[i]),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(FileCategory? cat, String? label) {
    if (cat == null) {
      // "All" chip
      return Padding(
        padding: const EdgeInsets.only(right: 6),
        child: GestureDetector(
          onTap: () => setState(() => _selectedCategory = null),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _selectedCategory == null
                  ? GrabbitColors.turquoise.withAlpha(30)
                  : GrabbitColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: _selectedCategory == null
                    ? GrabbitColors.turquoise
                    : GrabbitColors.borderStrong,
              ),
            ),
            child: Text(
              label ?? 'Alle',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _selectedCategory == null
                    ? GrabbitColors.turquoise
                    : GrabbitColors.t3,
              ),
            ),
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
          Icon(Icons.search_off_rounded, size: 48, color: GrabbitColors.t4),
          const SizedBox(height: 12),
          Text(
            'Keine Dateien gefunden',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ],
      ),
    );
  }

  List<IndexedFile> _filteredFiles() {
    var files = _demoFiles;

    // Category filter
    if (_selectedCategory != null) {
      files = files.where((f) => f.category == _selectedCategory).toList();
    }

    // Search filter (simple name match for demo — real version uses FTS5)
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      files = files
          .where((f) =>
              f.name.toLowerCase().contains(query) ||
              (f.contentText?.toLowerCase().contains(query) ?? false))
          .toList();
    }

    return files;
  }

  void _onFileTap(IndexedFile file) {
    // TODO: Open file / show detail
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Öffne: ${file.name}')),
    );
  }

  void _onFileLongPress(IndexedFile file) {
    // TODO: Show action sheet (Sharesheet Brain)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Aktionen für: ${file.name}')),
    );
  }

  /// Generate demo files for the prototype.
  List<IndexedFile> _generateDemoFiles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      IndexedFile(id: 1, path: '/storage/emulated/0/Download/Rechnung_2026.pdf', name: 'Rechnung_2026.pdf', ext: 'pdf', size: 2100000, modified: now - 120000, created: now - 120000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/pdf', contentText: 'Rechnung Nr. 4421 Versicherung monatlich'),
      IndexedFile(id: 2, path: '/storage/emulated/0/DCIM/Camera/IMG_20260628.jpg', name: 'IMG_20260628.jpg', ext: 'jpg', size: 4800000, modified: now - 300000, created: now - 300000, parent: '/storage/emulated/0/DCIM/Camera', source: 'camera', mime: 'image/jpeg'),
      IndexedFile(id: 3, path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_1642.png', name: 'Screenshot_1642.png', ext: 'png', size: 1800000, modified: now - 600000, created: now - 600000, parent: '/storage/emulated/0/Pictures/Screenshots', source: 'screenshot', mime: 'image/png', contentIndexed: 2, contentText: 'API Key: sk-1234 Token Balance 42.50'),
      IndexedFile(id: 4, path: '/storage/emulated/0/Download/project_notes.md', name: 'project_notes.md', ext: 'md', size: 15000, modified: now - 900000, created: now - 3600000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/markdown', contentIndexed: 1, contentText: 'GRABBIT MVP architecture decisions flutter sqlite fts5'),
      IndexedFile(id: 5, path: '/storage/emulated/0/Download/backup_2026.zip', name: 'backup_2026.zip', ext: 'zip', size: 156000000, modified: now - 1800000, created: now - 1800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/zip'),
      IndexedFile(id: 6, path: '/storage/emulated/0/WhatsApp/Media/Audio/voice_note.ogg', name: 'voice_note.ogg', ext: 'ogg', size: 340000, modified: now - 3600000, created: now - 3600000, parent: '/storage/emulated/0/WhatsApp/Media/Audio', source: 'whatsapp', mime: 'audio/ogg'),
      IndexedFile(id: 7, path: '/storage/emulated/0/Download/app-release.apk', name: 'app-release.apk', ext: 'apk', size: 45000000, modified: now - 7200000, created: now - 7200000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/vnd.android.package-archive'),
      IndexedFile(id: 8, path: '/storage/emulated/0/Documents/chatgpt_export.json', name: 'chatgpt_export.json', ext: 'json', size: 890000, modified: now - 10800000, created: now - 10800000, parent: '/storage/emulated/0/Documents', source: 'chatgpt', mime: 'application/json', contentIndexed: 1, contentText: 'conversation about flutter design systems animations'),
      IndexedFile(id: 9, path: '/storage/emulated/0/DCIM/Camera/VID_20260627.mp4', name: 'VID_20260627.mp4', ext: 'mp4', size: 98000000, modified: now - 86400000, created: now - 86400000, parent: '/storage/emulated/0/DCIM/Camera', source: 'camera', mime: 'video/mp4'),
      IndexedFile(id: 10, path: '/storage/emulated/0/Download/shader_code.dart', name: 'shader_code.dart', ext: 'dart', size: 4200, modified: now - 172800000, created: now - 172800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/x-dart', contentIndexed: 1, contentText: 'import package flutter material shader fragment program'),
      IndexedFile(id: 11, path: '/storage/emulated/0/Telegram/Documents/invoice_may.pdf', name: 'invoice_may.pdf', ext: 'pdf', size: 520000, modified: now - 259200000, created: now - 259200000, parent: '/storage/emulated/0/Telegram/Documents', source: 'telegram', mime: 'application/pdf', contentIndexed: 1, contentText: 'Invoice May 2026 hosting services total EUR 49.90'),
      IndexedFile(id: 12, path: '/storage/emulated/0/Music/podcast_ep42.mp3', name: 'podcast_ep42.mp3', ext: 'mp3', size: 67000000, modified: now - 345600000, created: now - 345600000, parent: '/storage/emulated/0/Music', source: 'download', mime: 'audio/mpeg'),
    ];
  }
}
