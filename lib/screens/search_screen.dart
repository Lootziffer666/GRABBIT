import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';
import '../widgets/file_card.dart';

/// Dedicated search screen — full-screen instant search.
/// Searches filenames AND content (FTS5).
/// Shows recent searches, type/source/size/date quick-filters.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  // Search state
  List<IndexedFile> _results = [];
  bool _hasSearched = false;

  // Quick filters
  String? _sourceFilter;
  int? _minSizeFilter;
  int? _modifiedAfterFilter;

  // Demo data (will be replaced by DB query)
  final _allFiles = <IndexedFile>[];

  @override
  void initState() {
    super.initState();
    _allFiles.addAll(_generateAllFiles());
    // Auto-focus search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _controller.text.trim().toLowerCase();
    if (query.isEmpty) {
      setState(() {
        _results = [];
        _hasSearched = false;
      });
      return;
    }

    setState(() {
      _hasSearched = true;
      _results = _allFiles.where((f) {
        // Name match
        final nameMatch = f.name.toLowerCase().contains(query);
        // Content match
        final contentMatch =
            f.contentText?.toLowerCase().contains(query) ?? false;
        // Path match
        final pathMatch = f.path.toLowerCase().contains(query);

        if (!nameMatch && !contentMatch && !pathMatch) return false;

        // Apply filters
        if (_sourceFilter != null && f.source != _sourceFilter) return false;
        if (_minSizeFilter != null && f.size < _minSizeFilter!) return false;
        if (_modifiedAfterFilter != null &&
            f.modified < _modifiedAfterFilter!) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrabbitColors.void_,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: GrabbitColors.surface,
              child: Column(
                children: [
                  // Search input
                  Container(
                    decoration: BoxDecoration(
                      color: GrabbitColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: GrabbitColors.borderStrong),
                    ),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      onChanged: (_) => _performSearch(),
                      style: const TextStyle(
                          fontSize: 15, color: GrabbitColors.t1),
                      decoration: InputDecoration(
                        hintText: 'Dateiname, Inhalt, Pfad...',
                        hintStyle:
                            const TextStyle(color: GrabbitColors.t4),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: GrabbitColors.turquoise, size: 22),
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded,
                                    color: GrabbitColors.t3, size: 18),
                                onPressed: () {
                                  _controller.clear();
                                  _performSearch();
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Quick filters
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _quickFilter(
                          'Heute',
                          _modifiedAfterFilter != null,
                          () => setState(() {
                            _modifiedAfterFilter =
                                _modifiedAfterFilter != null
                                    ? null
                                    : DateTime.now()
                                        .subtract(
                                            const Duration(hours: 24))
                                        .millisecondsSinceEpoch;
                            _performSearch();
                          }),
                        ),
                        _quickFilter(
                          '>10 MB',
                          _minSizeFilter != null,
                          () => setState(() {
                            _minSizeFilter = _minSizeFilter != null
                                ? null
                                : 10 * 1024 * 1024;
                            _performSearch();
                          }),
                        ),
                        _quickFilter(
                          'Download',
                          _sourceFilter == 'download',
                          () => setState(() {
                            _sourceFilter =
                                _sourceFilter == 'download'
                                    ? null
                                    : 'download';
                            _performSearch();
                          }),
                        ),
                        _quickFilter(
                          'Screenshot',
                          _sourceFilter == 'screenshot',
                          () => setState(() {
                            _sourceFilter =
                                _sourceFilter == 'screenshot'
                                    ? null
                                    : 'screenshot';
                            _performSearch();
                          }),
                        ),
                        _quickFilter(
                          'Kamera',
                          _sourceFilter == 'camera',
                          () => setState(() {
                            _sourceFilter =
                                _sourceFilter == 'camera'
                                    ? null
                                    : 'camera';
                            _performSearch();
                          }),
                        ),
                        _quickFilter(
                          'ChatGPT',
                          _sourceFilter == 'chatgpt',
                          () => setState(() {
                            _sourceFilter =
                                _sourceFilter == 'chatgpt'
                                    ? null
                                    : 'chatgpt';
                            _performSearch();
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Results
            Expanded(
              child: _buildResults(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickFilter(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: active
                ? GrabbitColors.turquoise.withAlpha(25)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: active
                  ? GrabbitColors.turquoise
                  : GrabbitColors.borderStrong,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color:
                  active ? GrabbitColors.turquoise : GrabbitColors.t3,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResults() {
    if (!_hasSearched) {
      return _buildSearchHints();
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 48, color: GrabbitColors.t4),
            const SizedBox(height: 12),
            Text(
              'Keine Treffer',
              style: GoogleFonts.lilitaOne(
                  fontSize: 22, color: GrabbitColors.t2),
            ),
            const SizedBox(height: 4),
            Text(
              '"${_controller.text}" nicht gefunden',
              style: const TextStyle(
                  fontSize: 13, color: GrabbitColors.t3),
            ),
          ],
        ),
      );
    }

    // Split results into name matches and content matches
    final query = _controller.text.trim().toLowerCase();
    final nameMatches = _results
        .where((f) => f.name.toLowerCase().contains(query))
        .toList();
    final contentMatches = _results
        .where((f) =>
            !f.name.toLowerCase().contains(query) &&
            (f.contentText?.toLowerCase().contains(query) ?? false))
        .toList();

    return ListView(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      children: [
        if (nameMatches.isNotEmpty) ...[
          _sectionHeader(
              'Dateiname', nameMatches.length),
          for (var i = 0; i < nameMatches.length; i++)
            ScrollReveal(
              delay: Duration(milliseconds: i * 40),
              child: FileCard(
                file: nameMatches[i],
                onTap: () {},
                onLongPress: () {},
              ),
            ),
        ],
        if (contentMatches.isNotEmpty) ...[
          _sectionHeader(
              'Inhaltstreffer', contentMatches.length),
          for (var i = 0; i < contentMatches.length; i++)
            ScrollReveal(
              delay: Duration(
                  milliseconds:
                      (nameMatches.length + i) * 40),
              child: _buildContentMatchCard(
                  contentMatches[i], query),
            ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
              color: GrabbitColors.t3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: GrabbitColors.turquoise.withAlpha(20),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.jetBrainsMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: GrabbitColors.turquoise,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// File card with content snippet highlighted.
  Widget _buildContentMatchCard(IndexedFile file, String query) {
    final snippet = _extractSnippet(file.contentText ?? '', query);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: GrabbitColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: GrabbitColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: GrabbitColors.cyan.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.text_snippet_rounded,
                        size: 16, color: GrabbitColors.cyan),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file.name,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.t1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    file.sizeFormatted,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 10,
                      color: GrabbitColors.t3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Snippet with highlight
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: GrabbitColors.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: GrabbitColors.cyan.withAlpha(40)),
                ),
                child: Text.rich(
                  _highlightSnippet(snippet, query),
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: GrabbitColors.t2,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _extractSnippet(String text, String query) {
    final lower = text.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) return text.substring(0, text.length.clamp(0, 150));
    final start = (idx - 40).clamp(0, text.length);
    final end = (idx + query.length + 80).clamp(0, text.length);
    final prefix = start > 0 ? '...' : '';
    final suffix = end < text.length ? '...' : '';
    return '$prefix${text.substring(start, end)}$suffix';
  }

  TextSpan _highlightSnippet(String snippet, String query) {
    final lower = snippet.toLowerCase();
    final idx = lower.indexOf(query);
    if (idx < 0) return TextSpan(text: snippet);

    return TextSpan(children: [
      TextSpan(text: snippet.substring(0, idx)),
      TextSpan(
        text: snippet.substring(idx, idx + query.length),
        style: const TextStyle(
          color: GrabbitColors.turquoise,
          fontWeight: FontWeight.w700,
          backgroundColor: Color(0x201DB8AC),
        ),
      ),
      TextSpan(text: snippet.substring(idx + query.length)),
    ]);
  }

  Widget _buildSearchHints() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            'Suche über alles',
            style: GoogleFonts.lilitaOne(
                fontSize: 22, color: GrabbitColors.t2),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dateinamen, Pfade und Dateiinhalte werden durchsucht. '
            'FTS5-Index liefert Ergebnisse in <5ms.',
            style: TextStyle(fontSize: 13, color: GrabbitColors.t3),
          ),
          const SizedBox(height: 24),
          _searchHint(Icons.description_rounded, 'rechnung versicherung'),
          _searchHint(Icons.code_rounded, 'flutter sqlite fts5'),
          _searchHint(Icons.image_rounded, 'screenshot api key'),
          _searchHint(Icons.folder_zip_rounded, 'backup 2026'),
        ],
      ),
    );
  }

  Widget _searchHint(IconData icon, String example) {
    return GestureDetector(
      onTap: () {
        _controller.text = example;
        _performSearch();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 16, color: GrabbitColors.t4),
            const SizedBox(width: 12),
            Text(
              '"$example"',
              style: const TextStyle(
                fontSize: 13,
                color: GrabbitColors.t3,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<IndexedFile> _generateAllFiles() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return [
      IndexedFile(id: 1, path: '/storage/emulated/0/Download/Rechnung_2026.pdf', name: 'Rechnung_2026.pdf', ext: 'pdf', size: 2100000, modified: now - 120000, created: now - 120000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/pdf', contentIndexed: 1, contentText: 'Rechnung Nr. 4421 Versicherung monatlich Beitrag EUR 89.50'),
      IndexedFile(id: 2, path: '/storage/emulated/0/DCIM/Camera/IMG_20260628.jpg', name: 'IMG_20260628.jpg', ext: 'jpg', size: 4800000, modified: now - 300000, created: now - 300000, parent: '/storage/emulated/0/DCIM/Camera', source: 'camera', mime: 'image/jpeg'),
      IndexedFile(id: 3, path: '/storage/emulated/0/Pictures/Screenshots/Screenshot_1642.png', name: 'Screenshot_1642.png', ext: 'png', size: 1800000, modified: now - 600000, created: now - 600000, parent: '/storage/emulated/0/Pictures/Screenshots', source: 'screenshot', mime: 'image/png', contentIndexed: 2, contentText: 'API Key sk-1234 Token Balance 42.50 remaining credits'),
      IndexedFile(id: 4, path: '/storage/emulated/0/Download/project_notes.md', name: 'project_notes.md', ext: 'md', size: 15000, modified: now - 900000, created: now - 3600000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/markdown', contentIndexed: 1, contentText: 'GRABBIT MVP architecture decisions flutter sqlite fts5 everything principle'),
      IndexedFile(id: 5, path: '/storage/emulated/0/Download/backup_2026.zip', name: 'backup_2026.zip', ext: 'zip', size: 156000000, modified: now - 1800000, created: now - 1800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'application/zip'),
      IndexedFile(id: 6, path: '/storage/emulated/0/Documents/chatgpt_export.json', name: 'chatgpt_export.json', ext: 'json', size: 890000, modified: now - 10800000, created: now - 10800000, parent: '/storage/emulated/0/Documents', source: 'chatgpt', mime: 'application/json', contentIndexed: 1, contentText: 'conversation about flutter design systems animations elastic liquid gooey FLUBBER'),
      IndexedFile(id: 7, path: '/storage/emulated/0/Download/shader_code.dart', name: 'shader_code.dart', ext: 'dart', size: 4200, modified: now - 172800000, created: now - 172800000, parent: '/storage/emulated/0/Download', source: 'download', mime: 'text/x-dart', contentIndexed: 1, contentText: 'import package flutter material shader fragment program opengl webgl'),
      IndexedFile(id: 8, path: '/storage/emulated/0/Telegram/Documents/invoice_may.pdf', name: 'invoice_may.pdf', ext: 'pdf', size: 520000, modified: now - 259200000, created: now - 259200000, parent: '/storage/emulated/0/Telegram/Documents', source: 'telegram', mime: 'application/pdf', contentIndexed: 1, contentText: 'Invoice May 2026 hosting services total EUR 49.90 payment due June'),
    ];
  }
}
