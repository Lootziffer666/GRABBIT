import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../animations/scroll_reveal.dart';
import '../theme/grabbit_colors.dart';
import '../widgets/file_card.dart';

/// Downloads screen — the "Eingangsschleuse".
///
/// Not a dump. An inbox. Files arrive here and need triage:
/// - Neu (ungesehen)
/// - Bereits geöffnet
/// - Noch nicht einsortiert
/// - Nach Typ gruppiert (ZIP/APK/PDF/Bild/Text/Audio/Video)
/// - Wahrscheinlich Müll vs. wahrscheinlich wichtig
/// - Groß / Doppelt
class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

enum DownloadFilter {
  all,
  neu, // unseen
  archive, // zip/rar/7z
  apk,
  pdf,
  image,
  audio,
  video,
  text,
  large; // >50MB

  String get label => switch (this) {
        all => 'Alle',
        neu => 'Neu',
        archive => 'Archive',
        apk => 'APK',
        pdf => 'PDF',
        image => 'Bilder',
        audio => 'Audio',
        video => 'Video',
        text => 'Text',
        large => 'Groß',
      };

  IconData get icon => switch (this) {
        all => Icons.inbox_rounded,
        neu => Icons.fiber_new_rounded,
        archive => Icons.folder_zip_rounded,
        apk => Icons.android_rounded,
        pdf => Icons.picture_as_pdf_rounded,
        image => Icons.image_rounded,
        audio => Icons.audiotrack_rounded,
        video => Icons.videocam_rounded,
        text => Icons.text_snippet_rounded,
        large => Icons.storage_rounded,
      };
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  DownloadFilter _filter = DownloadFilter.all;

  // Demo data — will be Riverpod-driven from index
  late final List<IndexedFile> _downloadFiles;

  @override
  void initState() {
    super.initState();
    _downloadFiles = _generateDemoDownloads();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _applyFilter(_downloadFiles);

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
                    'Downloads',
                    style: GoogleFonts.lilitaOne(
                      fontSize: 28,
                      color: GrabbitColors.t1,
                    ),
                  ),
                  const Spacer(),
                  // Stats badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: GrabbitColors.orange.withAlpha(20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                          color: GrabbitColors.orange.withAlpha(60)),
                    ),
                    child: Text(
                      '${_downloadFiles.length} Dateien',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: GrabbitColors.orange,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: DownloadFilter.values.map((f) {
                  final selected = _filter == f;
                  final count = _applyFilter(
                    _downloadFiles,
                    override: f,
                  ).length;
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
                              ? GrabbitColors.orange.withAlpha(30)
                              : GrabbitColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: selected
                                ? GrabbitColors.orange
                                : GrabbitColors.borderStrong,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(f.icon,
                                size: 14,
                                color: selected
                                    ? GrabbitColors.orange
                                    : GrabbitColors.t3),
                            const SizedBox(width: 6),
                            Text(
                              '${f.label} ($count)',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: selected
                                    ? GrabbitColors.orange
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

            // Batch action bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _quickAction(Icons.cleaning_services_rounded, 'Aufräumen'),
                  const SizedBox(width: 8),
                  _quickAction(Icons.sort_rounded, 'Sortieren'),
                  const SizedBox(width: 8),
                  _quickAction(Icons.select_all_rounded, 'Alle wählen'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // File list
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.only(bottom: 80),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => ScrollReveal(
                        delay: Duration(milliseconds: i * 35),
                        child: FileCard(
                          file: filtered[i],
                          onTap: () {},
                          onLongPress: () {},
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickAction(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: GrabbitColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: GrabbitColors.borderStrong),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: GrabbitColors.t2),
          const SizedBox(width: 6),
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GrabbitColors.t2)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_done_rounded,
              size: 48, color: GrabbitColors.stable),
          const SizedBox(height: 12),
          Text(
            'Download-Inbox leer',
            style: GoogleFonts.lilitaOne(
                fontSize: 24, color: GrabbitColors.t1),
          ),
          const SizedBox(height: 4),
          const Text(
            'Keine Dateien in diesem Filter.',
            style: TextStyle(color: GrabbitColors.t3),
          ),
        ],
      ),
    );
  }

  List<IndexedFile> _applyFilter(List<IndexedFile> files,
      {DownloadFilter? override}) {
    final f = override ?? _filter;
    return switch (f) {
      DownloadFilter.all => files,
      DownloadFilter.neu => files.where((file) =>
          DateTime.now().millisecondsSinceEpoch - file.modified < 86400000)
          .toList(),
      DownloadFilter.archive =>
        files.where((file) => file.category == FileCategory.archive).toList(),
      DownloadFilter.apk =>
        files.where((file) => file.extension == 'apk' || file.extension == 'xapk').toList(),
      DownloadFilter.pdf =>
        files.where((file) => file.extension == 'pdf').toList(),
      DownloadFilter.image =>
        files.where((file) => file.category == FileCategory.image).toList(),
      DownloadFilter.audio =>
        files.where((file) => file.category == FileCategory.audio).toList(),
      DownloadFilter.video =>
        files.where((file) => file.category == FileCategory.video).toList(),
      DownloadFilter.text => files.where((file) =>
          file.category == FileCategory.document ||
          file.category == FileCategory.code).toList(),
      DownloadFilter.large =>
        files.where((file) => file.size > 50 * 1024 * 1024).toList(),
    };
  }

  List<IndexedFile> _generateDemoDownloads() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final base = '/storage/emulated/0/Download';
    return [
      IndexedFile(id: 20, path: '$base/contract_2026.pdf', name: 'contract_2026.pdf', ext: 'pdf', size: 3200000, modified: now - 60000, created: now - 60000, parent: base, source: 'download', mime: 'application/pdf'),
      IndexedFile(id: 21, path: '$base/photo_export.zip', name: 'photo_export.zip', ext: 'zip', size: 245000000, modified: now - 180000, created: now - 180000, parent: base, source: 'download', mime: 'application/zip'),
      IndexedFile(id: 22, path: '$base/app-debug.apk', name: 'app-debug.apk', ext: 'apk', size: 67000000, modified: now - 3600000, created: now - 3600000, parent: base, source: 'download', mime: 'application/vnd.android.package-archive'),
      IndexedFile(id: 23, path: '$base/meeting_notes.md', name: 'meeting_notes.md', ext: 'md', size: 8400, modified: now - 7200000, created: now - 7200000, parent: base, source: 'download', mime: 'text/markdown', contentIndexed: 1, contentText: 'Sprint planning notes architecture decisions GRABBIT MVP'),
      IndexedFile(id: 24, path: '$base/design_mockup.png', name: 'design_mockup.png', ext: 'png', size: 4200000, modified: now - 14400000, created: now - 14400000, parent: base, source: 'download', mime: 'image/png'),
      IndexedFile(id: 25, path: '$base/podcast_interview.mp3', name: 'podcast_interview.mp3', ext: 'mp3', size: 89000000, modified: now - 28800000, created: now - 28800000, parent: base, source: 'download', mime: 'audio/mpeg'),
      IndexedFile(id: 26, path: '$base/chatgpt_conversation.json', name: 'chatgpt_conversation.json', ext: 'json', size: 1200000, modified: now - 43200000, created: now - 43200000, parent: base, source: 'chatgpt', mime: 'application/json', contentIndexed: 1, contentText: 'flutter design system animation elastic liquid gooey'),
      IndexedFile(id: 27, path: '$base/video_recording.mp4', name: 'video_recording.mp4', ext: 'mp4', size: 340000000, modified: now - 86400000, created: now - 86400000, parent: base, source: 'download', mime: 'video/mp4'),
      IndexedFile(id: 28, path: '$base/old_backup.tar.gz', name: 'old_backup.tar.gz', ext: 'gz', size: 520000000, modified: now - 604800000, created: now - 604800000, parent: base, source: 'download', mime: 'application/gzip'),
    ];
  }
}
