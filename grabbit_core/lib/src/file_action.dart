/// Actions that can be performed on files.
/// Pure enum — execution is in the Flutter/platform layer.
enum FileAction {
  open,
  openWith,
  share,
  shareAs, // share as text vs. file vs. link
  move,
  copy,
  rename,
  delete,
  extract, // unzip/unrar
  compress, // zip selected
  viewContent, // text viewer / preview
  extractText, // OCR or PDF text extraction
  addToBundle, // group for batch operations
  setTarget, // choose app target (Sharesheet Brain)
}

/// Copy semantics from the GRABBIT spec.
enum CopyResult {
  /// Full text was copied to clipboard.
  fullTextCopy,

  /// Content too large — file reference was copied instead.
  fileReferenceCopy,

  /// Content saved to file but not placed in clipboard.
  savedOnly,

  /// Android blocked the clipboard operation.
  clipboardFailed,

  /// User must manually open target app.
  manualActionNeeded,
}

/// Batch operation on multiple files.
class BatchAction {
  final FileAction action;
  final List<String> filePaths;
  final String? targetPath; // for move/copy

  const BatchAction({
    required this.action,
    required this.filePaths,
    this.targetPath,
  });
}
