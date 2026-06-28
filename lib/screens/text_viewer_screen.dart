import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/grabbit_colors.dart';
import '../widgets/text_toolbar.dart';

/// GRABBIT Text Viewer — the power-user text handling screen.
///
/// Features:
/// - Longpress Anfang/Ende paragraph selection
/// - Paragraph-based selection with +/- to extend
/// - Find & Replace (Windows-standard: Ctrl+F / Ctrl+H)
/// - Line break handling (show/convert CR/LF/CRLF)
/// - Copy semantics (Full Text / File Reference / Saved)
/// - Export selection as .txt, .md, .json
class TextViewerScreen extends StatefulWidget {
  const TextViewerScreen({
    super.key,
    required this.content,
    required this.fileName,
    this.filePath,
  });

  final String content;
  final String fileName;
  final String? filePath;

  @override
  State<TextViewerScreen> createState() => _TextViewerScreenState();
}

class _TextViewerScreenState extends State<TextViewerScreen> {
  /// Paragraphs split by double-newline or single-newline.
  late List<String> _paragraphs;

  /// Selection state: start and end paragraph indices (inclusive).
  int? _selStart;
  int? _selEnd;

  /// Find & Replace state.
  bool _showFindBar = false;
  bool _showReplaceBar = false;
  final _findController = TextEditingController();
  final _replaceController = TextEditingController();
  List<int> _findMatches = []; // paragraph indices with matches
  int _currentMatchIndex = -1;

  /// Line break display mode.
  bool _showLineBreaks = false;

  /// Editable content (for Replace operations).
  late String _editableContent;

  @override
  void initState() {
    super.initState();
    _editableContent = widget.content;
    _splitParagraphs();
  }

  void _splitParagraphs() {
    // Split on double newlines (paragraph breaks) or keep
    // single-newline blocks as separate paragraphs
    _paragraphs = _editableContent
        .split(RegExp(r'\n\s*\n'))
        .where((p) => p.trim().isNotEmpty)
        .toList();
    if (_paragraphs.isEmpty) {
      _paragraphs = [_editableContent];
    }
  }

  @override
  void dispose() {
    _findController.dispose();
    _replaceController.dispose();
    super.dispose();
  }

  // ── Selection Logic ───────────────────────────────────────

  void _onParagraphLongPress(int index) {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_selStart == null) {
        // First longpress = set start
        _selStart = index;
        _selEnd = index;
      } else {
        // Second longpress = set end
        _selEnd = index;
        // Normalize: start <= end
        if (_selEnd! < _selStart!) {
          final tmp = _selStart;
          _selStart = _selEnd;
          _selEnd = tmp;
        }
      }
    });
  }

  void _expandSelectionUp() {
    if (_selStart == null) return;
    setState(() {
      if (_selStart! > 0) _selStart = _selStart! - 1;
    });
  }

  void _expandSelectionDown() {
    if (_selEnd == null) return;
    setState(() {
      if (_selEnd! < _paragraphs.length - 1) _selEnd = _selEnd! + 1;
    });
  }

  void _shrinkSelectionTop() {
    if (_selStart == null || _selEnd == null) return;
    setState(() {
      if (_selStart! < _selEnd!) _selStart = _selStart! + 1;
    });
  }

  void _shrinkSelectionBottom() {
    if (_selStart == null || _selEnd == null) return;
    setState(() {
      if (_selEnd! > _selStart!) _selEnd = _selEnd! - 1;
    });
  }

  void _clearSelection() {
    setState(() {
      _selStart = null;
      _selEnd = null;
    });
  }

  String get _selectedText {
    if (_selStart == null || _selEnd == null) return '';
    return _paragraphs
        .sublist(_selStart!, _selEnd! + 1)
        .join('\n\n');
  }

  bool _isSelected(int index) {
    if (_selStart == null || _selEnd == null) return false;
    return index >= _selStart! && index <= _selEnd!;
  }

  // ── Find & Replace ────────────────────────────────────────

  void _performFind() {
    final query = _findController.text;
    if (query.isEmpty) {
      setState(() {
        _findMatches = [];
        _currentMatchIndex = -1;
      });
      return;
    }
    setState(() {
      _findMatches = [];
      for (var i = 0; i < _paragraphs.length; i++) {
        if (_paragraphs[i]
            .toLowerCase()
            .contains(query.toLowerCase())) {
          _findMatches.add(i);
        }
      }
      _currentMatchIndex = _findMatches.isEmpty ? -1 : 0;
    });
  }

  void _findNext() {
    if (_findMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex + 1) % _findMatches.length;
    });
  }

  void _findPrevious() {
    if (_findMatches.isEmpty) return;
    setState(() {
      _currentMatchIndex =
          (_currentMatchIndex - 1 + _findMatches.length) %
              _findMatches.length;
    });
  }

  void _replaceCurrentMatch() {
    if (_currentMatchIndex < 0 || _findMatches.isEmpty) return;
    final paraIdx = _findMatches[_currentMatchIndex];
    setState(() {
      _paragraphs[paraIdx] = _paragraphs[paraIdx].replaceFirst(
        RegExp(RegExp.escape(_findController.text),
            caseSensitive: false),
        _replaceController.text,
      );
      _editableContent = _paragraphs.join('\n\n');
      _performFind(); // refresh matches
    });
  }

  void _replaceAll() {
    if (_findController.text.isEmpty) return;
    setState(() {
      _editableContent = _editableContent.replaceAll(
        RegExp(RegExp.escape(_findController.text),
            caseSensitive: false),
        _replaceController.text,
      );
      _splitParagraphs();
      _performFind();
    });
  }

  // ── Line Break Handling ───────────────────────────────────

  String _displayText(String text) {
    if (!_showLineBreaks) return text;
    return text
        .replaceAll('\r\n', '\u23CE\r\n') // CRLF → show symbol
        .replaceAll('\n', '\u21B5\n') // LF → show symbol
        .replaceAll('\r', '\u240D\r'); // CR → show symbol
  }

  // ── Actions on Selection ──────────────────────────────────

  Future<void> _copySelection() async {
    final text = _selectedText;
    if (text.isEmpty) return;

    if (text.length > 100000) {
      // Too large for clipboard — file reference copy
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Zu groß für Clipboard — '
                'Dateiverweis kopiert')),
      );
      await Clipboard.setData(ClipboardData(
          text: '[File: ${widget.fileName}] '
              '${text.length} chars'));
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'Kopiert: ${text.length} Zeichen')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GrabbitColors.void_,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Find bar (if active)
          if (_showFindBar) _buildFindBar(),
          if (_showReplaceBar) _buildReplaceBar(),

          // Selection expansion controls (top +)
          if (_selStart != null) _buildTopExpander(),

          // Paragraph list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              itemCount: _paragraphs.length,
              itemBuilder: (_, i) =>
                  _buildParagraph(i),
            ),
          ),

          // Selection expansion controls (bottom +)
          if (_selEnd != null) _buildBottomExpander(),

          // Action toolbar (when selection active)
          if (_selStart != null)
            TextToolbar(
              onCopy: _copySelection,
              onShare: () {}, // TODO
              onSaveAs: () {}, // TODO
              onClear: _clearSelection,
              selectedCount:
                  (_selEnd ?? 0) - (_selStart ?? 0) + 1,
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: GrabbitColors.surface,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.fileName,
              style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700)),
          Text(
            '${_paragraphs.length} Absätze · '
            '${_editableContent.length} Zeichen',
            style: const TextStyle(
                fontSize: 11, color: GrabbitColors.t3),
          ),
        ],
      ),
      actions: [
        // Line break toggle
        IconButton(
          icon: Icon(
            Icons.wrap_text_rounded,
            color: _showLineBreaks
                ? GrabbitColors.turquoise
                : GrabbitColors.t3,
          ),
          tooltip: 'Zeilenumbrüche anzeigen',
          onPressed: () =>
              setState(() => _showLineBreaks = !_showLineBreaks),
        ),
        // Find
        IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: _showFindBar
                ? GrabbitColors.turquoise
                : GrabbitColors.t3,
          ),
          tooltip: 'Suchen (Ctrl+F)',
          onPressed: () => setState(() {
            _showFindBar = !_showFindBar;
            if (!_showFindBar) {
              _showReplaceBar = false;
              _findMatches = [];
              _currentMatchIndex = -1;
            }
          }),
        ),
        // Replace
        IconButton(
          icon: Icon(
            Icons.find_replace_rounded,
            color: _showReplaceBar
                ? GrabbitColors.orange
                : GrabbitColors.t3,
          ),
          tooltip: 'Ersetzen (Ctrl+H)',
          onPressed: () => setState(() {
            _showFindBar = true;
            _showReplaceBar = !_showReplaceBar;
          }),
        ),
      ],
    );
  }

  Widget _buildFindBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      color: GrabbitColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _findController,
              onChanged: (_) => _performFind(),
              style: const TextStyle(
                  fontSize: 14, color: GrabbitColors.t1),
              decoration: InputDecoration(
                hintText: 'Suchen...',
                isDense: true,
                filled: true,
                fillColor: GrabbitColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Match count
          if (_findMatches.isNotEmpty)
            Text(
              '${_currentMatchIndex + 1}/${_findMatches.length}',
              style: const TextStyle(
                  fontSize: 12, color: GrabbitColors.t2),
            ),
          IconButton(
            icon: const Icon(Icons.arrow_upward_rounded,
                size: 18, color: GrabbitColors.t2),
            onPressed: _findPrevious,
          ),
          IconButton(
            icon: const Icon(Icons.arrow_downward_rounded,
                size: 18, color: GrabbitColors.t2),
            onPressed: _findNext,
          ),
        ],
      ),
    );
  }

  Widget _buildReplaceBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: 12, vertical: 6),
      color: GrabbitColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _replaceController,
              style: const TextStyle(
                  fontSize: 14, color: GrabbitColors.t1),
              decoration: InputDecoration(
                hintText: 'Ersetzen mit...',
                isDense: true,
                filled: true,
                fillColor: GrabbitColors.card,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: _replaceCurrentMatch,
            child: const Text('Ersetzen',
                style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: _replaceAll,
            child: Text('Alle',
                style: TextStyle(
                    fontSize: 12,
                    color: GrabbitColors.orange)),
          ),
        ],
      ),
    );
  }

  Widget _buildTopExpander() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _expandButton(
            icon: Icons.add_rounded,
            label: '+1 oben',
            onTap: _expandSelectionUp,
            enabled: _selStart != null && _selStart! > 0,
          ),
          const SizedBox(width: 12),
          _expandButton(
            icon: Icons.remove_rounded,
            label: '-1 oben',
            onTap: _shrinkSelectionTop,
            enabled: _selStart != null &&
                _selEnd != null &&
                _selStart! < _selEnd!,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomExpander() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _expandButton(
            icon: Icons.add_rounded,
            label: '+1 unten',
            onTap: _expandSelectionDown,
            enabled: _selEnd != null &&
                _selEnd! < _paragraphs.length - 1,
          ),
          const SizedBox(width: 12),
          _expandButton(
            icon: Icons.remove_rounded,
            label: '-1 unten',
            onTap: _shrinkSelectionBottom,
            enabled: _selStart != null &&
                _selEnd != null &&
                _selEnd! > _selStart!,
          ),
        ],
      ),
    );
  }

  Widget _expandButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool enabled,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: enabled
              ? GrabbitColors.turquoise.withAlpha(20)
              : GrabbitColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: enabled
                ? GrabbitColors.turquoise.withAlpha(100)
                : GrabbitColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: enabled
                    ? GrabbitColors.turquoise
                    : GrabbitColors.t4),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: enabled
                    ? GrabbitColors.turquoise
                    : GrabbitColors.t4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(int index) {
    final selected = _isSelected(index);
    final isMatchHighlight = _findMatches.contains(index);
    final isCurrentMatch = _currentMatchIndex >= 0 &&
        _currentMatchIndex < _findMatches.length &&
        _findMatches[_currentMatchIndex] == index;

    return GestureDetector(
      onLongPress: () => _onParagraphLongPress(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? GrabbitColors.turquoise.withAlpha(20)
              : isCurrentMatch
                  ? GrabbitColors.orange.withAlpha(20)
                  : isMatchHighlight
                      ? GrabbitColors.yellow.withAlpha(10)
                      : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? GrabbitColors.turquoise.withAlpha(120)
                : isCurrentMatch
                    ? GrabbitColors.orange.withAlpha(120)
                    : Colors.transparent,
            width: selected || isCurrentMatch ? 1.5 : 0,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Paragraph number
            SizedBox(
              width: 28,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontFamily: 'JetBrains Mono',
                  fontSize: 10,
                  color: selected
                      ? GrabbitColors.turquoise
                      : GrabbitColors.t4,
                ),
              ),
            ),
            // Paragraph content
            Expanded(
              child: Text(
                _displayText(_paragraphs[index]),
                style: TextStyle(
                  fontSize: 14,
                  height: 1.55,
                  color: selected
                      ? GrabbitColors.t1
                      : GrabbitColors.t2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
