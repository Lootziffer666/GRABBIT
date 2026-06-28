import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Text export service — handles export of selections or full content
/// to Markdown, plain text, or split chunks.
///
/// Features:
/// - Export selection to .md
/// - Export all to .md
/// - Split by character count (for LLM context windows, clipboard limits)
/// - Numbered chunk files: filename_001.md, filename_002.md, ...
class TextExportService {
  TextExportService._();
  static final instance = TextExportService._();

  /// Export text as a single Markdown file.
  /// Returns the path of the created file.
  Future<String> exportToMarkdown({
    required String text,
    required String baseFileName,
    String? title,
    String? targetDir,
  }) async {
    final dir = targetDir ?? (await _exportDir()).path;
    final sanitized = _sanitizeFileName(baseFileName);
    final fileName = sanitized.endsWith('.md') ? sanitized : '$sanitized.md';
    final filePath = p.join(dir, fileName);

    final buffer = StringBuffer();
    if (title != null) {
      buffer.writeln('# $title');
      buffer.writeln();
    }
    buffer.write(text);

    await File(filePath).writeAsString(buffer.toString());
    return filePath;
  }

  /// Export text split into chunks of [maxChars] characters.
  /// Returns list of paths of created files.
  ///
  /// Splitting is paragraph-aware: prefers to split at paragraph boundaries
  /// rather than mid-word. Falls back to hard split if a single paragraph
  /// exceeds [maxChars].
  Future<List<String>> exportSplitMarkdown({
    required String text,
    required String baseFileName,
    required int maxChars,
    String? title,
    String? targetDir,
  }) async {
    if (maxChars <= 0) maxChars = 4000;
    final dir = targetDir ?? (await _exportDir()).path;
    final sanitized = _sanitizeFileName(baseFileName);
    final baseName = sanitized.replaceAll(RegExp(r'\.(md|txt)$'), '');

    final chunks = _splitIntoParagraphChunks(text, maxChars);
    final paths = <String>[];

    for (var i = 0; i < chunks.length; i++) {
      final suffix = chunks.length == 1
          ? ''
          : '_${(i + 1).toString().padLeft(3, '0')}';
      final fileName = '$baseName$suffix.md';
      final filePath = p.join(dir, fileName);

      final buffer = StringBuffer();
      if (title != null) {
        if (chunks.length > 1) {
          buffer.writeln('# $title (${i + 1}/${chunks.length})');
        } else {
          buffer.writeln('# $title');
        }
        buffer.writeln();
      }
      buffer.write(chunks[i]);

      await File(filePath).writeAsString(buffer.toString());
      paths.add(filePath);
    }

    return paths;
  }

  /// Export selected paragraphs to Markdown with paragraph numbers as headers.
  Future<String> exportSelectionToMarkdown({
    required List<String> paragraphs,
    required int startIndex,
    required int endIndex,
    required String baseFileName,
    String? targetDir,
  }) async {
    final dir = targetDir ?? (await _exportDir()).path;
    final sanitized = _sanitizeFileName(baseFileName);
    final baseName = sanitized.replaceAll(RegExp(r'\.(md|txt)$'), '');
    final fileName = '${baseName}_selection.md';
    final filePath = p.join(dir, fileName);

    final buffer = StringBuffer();
    buffer.writeln('# Auswahl aus $baseFileName');
    buffer.writeln('> Absätze ${startIndex + 1}–${endIndex + 1}');
    buffer.writeln();

    for (var i = startIndex; i <= endIndex && i < paragraphs.length; i++) {
      buffer.writeln(paragraphs[i]);
      if (i < endIndex) buffer.writeln();
    }

    await File(filePath).writeAsString(buffer.toString());
    return filePath;
  }

  /// Export full content split into chunks, with a manifest file.
  Future<ExportResult> exportAllSplit({
    required String text,
    required String baseFileName,
    required int maxChars,
    String? targetDir,
  }) async {
    final dir = targetDir ?? (await _exportDir()).path;
    final paths = await exportSplitMarkdown(
      text: text,
      baseFileName: baseFileName,
      maxChars: maxChars,
      title: baseFileName,
      targetDir: dir,
    );

    // Create manifest
    final baseName = _sanitizeFileName(baseFileName)
        .replaceAll(RegExp(r'\.(md|txt)$'), '');
    final manifestPath = p.join(dir, '${baseName}_manifest.md');
    final manifest = StringBuffer();
    manifest.writeln('# $baseFileName — Split Export');
    manifest.writeln();
    manifest.writeln('| # | Datei | Zeichen |');
    manifest.writeln('|---|-------|---------|');

    final chunks = _splitIntoParagraphChunks(text, maxChars);
    for (var i = 0; i < paths.length; i++) {
      manifest.writeln(
          '| ${i + 1} | ${p.basename(paths[i])} | ${chunks[i].length} |');
    }
    manifest.writeln();
    manifest.writeln('Gesamt: ${text.length} Zeichen in ${paths.length} Teilen');
    manifest.writeln('Max pro Teil: $maxChars Zeichen');

    await File(manifestPath).writeAsString(manifest.toString());

    return ExportResult(
      files: paths,
      manifestPath: manifestPath,
      totalChars: text.length,
      chunkCount: paths.length,
      maxCharsPerChunk: maxChars,
    );
  }

  // ── Splitting Logic ─────────────────────────────────────────────────────

  /// Split text into chunks, preferring paragraph boundaries.
  List<String> _splitIntoParagraphChunks(String text, int maxChars) {
    if (text.length <= maxChars) return [text];

    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    final chunks = <String>[];
    var current = StringBuffer();

    for (final para in paragraphs) {
      // If adding this paragraph would exceed limit
      if (current.length + para.length + 2 > maxChars) {
        if (current.isNotEmpty) {
          chunks.add(current.toString().trimRight());
          current = StringBuffer();
        }
        // If single paragraph exceeds limit, hard-split it
        if (para.length > maxChars) {
          final hardChunks = _hardSplit(para, maxChars);
          chunks.addAll(hardChunks.take(hardChunks.length - 1));
          current.write(hardChunks.last);
        } else {
          current.write(para);
        }
      } else {
        if (current.isNotEmpty) current.write('\n\n');
        current.write(para);
      }
    }

    if (current.isNotEmpty) {
      chunks.add(current.toString().trimRight());
    }

    return chunks;
  }

  /// Hard-split a string at word boundaries, falling back to char boundary.
  List<String> _hardSplit(String text, int maxChars) {
    final chunks = <String>[];
    var remaining = text;

    while (remaining.length > maxChars) {
      // Try to find a word boundary near maxChars
      var splitAt = remaining.lastIndexOf(' ', maxChars);
      if (splitAt <= maxChars ~/ 2) {
        // No good word boundary found — hard split
        splitAt = maxChars;
      }
      chunks.add(remaining.substring(0, splitAt).trimRight());
      remaining = remaining.substring(splitAt).trimLeft();
    }

    if (remaining.isNotEmpty) {
      chunks.add(remaining);
    }

    return chunks;
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Future<Directory> _exportDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final exportDir = Directory(p.join(docs.path, 'grabbit_exports'));
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^\w\s\-.]'), '_').trim();
  }
}

/// Result of a split export operation.
class ExportResult {
  final List<String> files;
  final String manifestPath;
  final int totalChars;
  final int chunkCount;
  final int maxCharsPerChunk;

  const ExportResult({
    required this.files,
    required this.manifestPath,
    required this.totalChars,
    required this.chunkCount,
    required this.maxCharsPerChunk,
  });
}
