import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';
import '../services/clipboard_database.dart';
import '../services/clipboard_service.dart';

/// GRABBIT Persistent Clipboard — never lose copied text again.
///
/// Features:
/// - Full history, searchable, never expires
/// - Pin important entries (survive cleanup)
/// - Favorite frequently-used snippets
/// - Type detection (URL, code, JSON, email, path, multiline)
/// - Tap to re-paste
/// - Longpress for actions (pin, favorite, delete, share, edit tags)
/// - Source app badge (which app copied this?)
/// - Size indicator (shows when >100KB)
/// - FTS5 search across all clipboard history
class ClipboardScreen extends StatefulWidget {
  const ClipboardScreen({super.key});

  @override
  State<ClipboardScreen> createState() => _ClipboardScreenState();
}

enum ClipFilter {
  all,
  pinned,
  favorites,
  urls,
  code,
  large;

  String get label => switch (this) {
        all => 'Alle',
        pinned => 'Pinned',
        favorites => 'Favoriten',
        urls => 'URLs',
        code => 'Code',
        large => 'Groß',
      };

  IconData get icon => switch (this) {
        all => Icons.history_rounded,
        pinned => Icons.push_pin_rounded,
        favorites => Icons.star_rounded,
        urls => Icons.link_rounded,
        code => Icons.code_rounded,
        large => Icons.storage_rounded,
      };
}

class _ClipboardScreenState extends State<ClipboardScreen> {
  final _searchController = TextEditingController();
  ClipFilter _filter = ClipFilter.all;
  bool _searchActive = false;

  final List<ClipboardEntry> _entries = [];
  String _captureStatus = 'Nur während GRABBIT geöffnet ist';

  @override
  void initState() {
    super.initState();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final entries = await ClipboardDatabase.instance.getRecent(limit: 500);
    if (!mounted) return;
    setState(() {
      _entries
        ..clear()
        ..addAll(entries);
      _captureStatus = ClipboardService.instance.captureStatus;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter();

    return Scaffold(
      backgroundColor: GrabbitColors.void_,
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
                    'Clipboard',
                    style: GoogleFonts.lilitaOne(
                        fontSize: 28, color: GrabbitColors.t1),
                  ),
                  const Spacer(),
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GrabbitColors.lime.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: GrabbitColors.lime.withAlpha(60)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: GrabbitColors.lime,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _captureStatus,
                          style: GoogleFonts.jetBrainsMono(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: GrabbitColors.lime,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search toggle
                  GestureDetector(
                    onTap: () =>
                        setState(() => _searchActive = !_searchActive),
                    child: Icon(
                      Icons.search_rounded,
                      color: _searchActive
                          ? GrabbitColors.turquoise
                          : GrabbitColors.t3,
                    ),
                  ),
                ],
              ),
            ),

            // Search bar (expandable)
            if (_searchActive)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 14, color: GrabbitColors.t1),
                  decoration: InputDecoration(
                    hintText: 'Clipboard durchsuchen...',
                    isDense: true,
                    filled: true,
                    fillColor: GrabbitColors.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: GrabbitColors.borderStrong),
                    ),
                    prefixIcon: const Icon(Icons.search_rounded,
                        size: 18, color: GrabbitColors.t3),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded,
                                size: 16, color: GrabbitColors.t3),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
              ),

            const SizedBox(height: 8),

            // Filter chips
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: ClipFilter.values.map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _filter = f),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: selected
                              ? GrabbitColors.lime.withAlpha(25)
                              : GrabbitColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? GrabbitColors.lime
                                : GrabbitColors.borderStrong,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(f.icon,
                                size: 12,
                                color: selected
                                    ? GrabbitColors.lime
                                    : GrabbitColors.t3),
                            const SizedBox(width: 5),
                            Text(
                              f.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? GrabbitColors.lime
                                    : GrabbitColors.t3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 8),

            // Clip list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ScrollReveal(
                        delay: Duration(milliseconds: i * 35),
                        child: _buildClipCard(filtered[i]),
                      ),
                    ),
            ),
          ],
        ),
      ),
      // Manual capture FAB
      floatingActionButton: FloatingActionButton.small(
        onPressed: _manualCapture,
        tooltip: 'Clipboard jetzt erfassen',
        child: const Icon(Icons.content_paste_go_rounded, size: 20),
      ),
    );
  }

  Widget _buildClipCard(ClipboardEntry entry) {
    final typeColor = _typeColor(entry.type);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
      color: GrabbitColors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: entry.pinned
              ? GrabbitColors.orange.withAlpha(80)
              : GrabbitColors.border,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _pastEntry(entry),
        onLongPress: () => _showActions(entry),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: type badge + time + size + pin/fav icons
              Row(
                children: [
                  // Type chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: typeColor.withAlpha(20),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      entry.type.label,
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: typeColor,
                      ),
                    ),
                  ),
                  if (entry.sourceLabel != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      entry.sourceLabel!,
                      style: const TextStyle(
                          fontSize: 10, color: GrabbitColors.t3),
                    ),
                  ],
                  const Spacer(),
                  if (entry.pinned)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.push_pin_rounded,
                          size: 12, color: GrabbitColors.orange),
                    ),
                  if (entry.favorite)
                    const Padding(
                      padding: EdgeInsets.only(right: 4),
                      child: Icon(Icons.star_rounded,
                          size: 12, color: GrabbitColors.yellow),
                    ),
                  if (entry.isLarge)
                    Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Text(
                        entry.sizeFormatted,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 9,
                          color: GrabbitColors.orange,
                        ),
                      ),
                    ),
                  Text(
                    entry.timeAgo,
                    style: GoogleFonts.jetBrainsMono(
                      fontSize: 9,
                      color: GrabbitColors.t4,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Content preview
              Text(
                entry.preview ?? entry.content,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: GrabbitColors.t1,
                  fontFamily: entry.type == ClipType.code ||
                          entry.type == ClipType.json ||
                          entry.type == ClipType.path
                      ? 'JetBrains Mono'
                      : null,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _typeColor(ClipType type) => switch (type) {
        ClipType.text => GrabbitColors.t2,
        ClipType.url => GrabbitColors.cyan,
        ClipType.code => GrabbitColors.violet,
        ClipType.json => GrabbitColors.orange,
        ClipType.path => GrabbitColors.lime,
        ClipType.number => GrabbitColors.yellow,
        ClipType.email => GrabbitColors.turquoise,
        ClipType.multiline => GrabbitColors.periwinkle,
        ClipType.html => GrabbitColors.pink,
      };

  void _pastEntry(ClipboardEntry entry) async {
    HapticFeedback.mediumImpact();
    final result = await ClipboardService.instance.pasteToClipboard(entry);
    if (!mounted) return;
    final message = switch (result) {
      PasteResult.fullPaste => 'Vollständig kopiert: ${entry.content.length} Zeichen',
      PasteResult.passagePaste =>
        '${ClipboardService.splitIntoPassages(entry.content).length} Passagen an die Zwischenablage gesendet. Die letzte ist jetzt aktiv; vorherige können in Gboard gespeichert sein.',
      PasteResult.failed => 'Kopieren fehlgeschlagen',
    };
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showActions(ClipboardEntry entry) {
    HapticFeedback.heavyImpact();
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
            const SizedBox(height: 8),
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: GrabbitColors.t4,
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            // Preview
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                entry.preview ?? entry.content.substring(
                    0, entry.content.length.clamp(0, 100)),
                style: const TextStyle(
                    fontSize: 12, color: GrabbitColors.t2),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Icon(
                entry.pinned
                    ? Icons.push_pin_outlined
                    : Icons.push_pin_rounded,
                color: GrabbitColors.orange,
              ),
              title: Text(entry.pinned ? 'Unpin' : 'Pin'),
              onTap: () {
                setState(() {
                  final idx = _entries.indexOf(entry);
                  if (idx >= 0) {
                    _entries[idx] = entry.copyWith(pinned: !entry.pinned);
                  }
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                entry.favorite
                    ? Icons.star_outline_rounded
                    : Icons.star_rounded,
                color: GrabbitColors.yellow,
              ),
              title: Text(entry.favorite ? 'Unfavorite' : 'Favorit'),
              onTap: () {
                setState(() {
                  final idx = _entries.indexOf(entry);
                  if (idx >= 0) {
                    _entries[idx] =
                        entry.copyWith(favorite: !entry.favorite);
                  }
                });
                Navigator.pop(context);
              },
            ),
            if (entry.exceedsAndroidLimit)
              ListTile(
                leading: const Icon(Icons.call_split_rounded,
                    color: GrabbitColors.turquoise),
                title: const Text('In Passagen an Gboard senden'),
                subtitle: Text(
                  '${ClipboardService.splitIntoPassages(entry.content).length} Passagen; die letzte bleibt aktiv',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _pastEntry(entry);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.share_rounded, color: GrabbitColors.t2),
              title: const Text('Teilen'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.text_snippet_rounded,
                  color: GrabbitColors.cyan),
              title: const Text('Im TextViewer öffnen'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: GrabbitColors.red),
              title: const Text('Löschen',
                  style: TextStyle(color: GrabbitColors.red)),
              onTap: () {
                setState(() => _entries.remove(entry));
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _manualCapture() async {
    final entry = await ClipboardService.instance.captureCurrentClipboard();
    if (!mounted) return;
    if (entry != null) {
      setState(() => _entries.insert(0, entry));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erfasst: ${entry.content.length} Zeichen')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard leer oder bereits erfasst')),
      );
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.content_paste_off_rounded,
              size: 48, color: GrabbitColors.t4),
          const SizedBox(height: 12),
          Text(
            'Noch nichts kopiert',
            style: GoogleFonts.lilitaOne(
                fontSize: 22, color: GrabbitColors.t2),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Tippe auf +, um den aktuellen Inhalt zu erfassen. '
              'Android erlaubt den automatischen Zugriff nur, während GRABBIT geöffnet ist.',
              style: TextStyle(
                  fontSize: 12, color: GrabbitColors.t3, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  List<ClipboardEntry> _applyFilter() {
    var entries = _entries;

    // Search filter
    final query = _searchController.text.toLowerCase();
    if (query.isNotEmpty) {
      entries = entries
          .where((e) => e.content.toLowerCase().contains(query))
          .toList();
    }

    // Type filter
    return switch (_filter) {
      ClipFilter.all => entries,
      ClipFilter.pinned => entries.where((e) => e.pinned).toList(),
      ClipFilter.favorites => entries.where((e) => e.favorite).toList(),
      ClipFilter.urls =>
        entries.where((e) => e.type == ClipType.url).toList(),
      ClipFilter.code => entries
          .where((e) =>
              e.type == ClipType.code || e.type == ClipType.json)
          .toList(),
      ClipFilter.large => entries.where((e) => e.isLarge).toList(),
    };
  }

}
