import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:grabbit_core/grabbit_core.dart';

import '../services/index_database.dart';

/// Provider for the index database singleton.
final indexDatabaseProvider = Provider<IndexDatabase>((ref) {
  return IndexDatabase.instance;
});

/// Provider for the current query — drives what the UI shows.
final fileQueryProvider = StateProvider<FileQuery>((ref) {
  return const FileQuery.recent();
});

/// Provider for file results — reacts to query changes.
/// This is the core reactive chain: query changes → DB query → UI updates.
final fileResultsProvider = FutureProvider<List<IndexedFile>>((ref) async {
  final db = ref.watch(indexDatabaseProvider);
  final query = ref.watch(fileQueryProvider);
  return db.query(query);
});

/// Provider for total indexed file count (shown in header).
final totalFileCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(indexDatabaseProvider);
  return db.getTotalFileCount();
});

/// Provider for scan state (last full scan timestamp).
final lastScanProvider = FutureProvider<int?>((ref) async {
  final db = ref.watch(indexDatabaseProvider);
  return db.getLastFullScan();
});

/// Provider for the search text — debounced in the UI.
final searchTextProvider = StateProvider<String>((ref) => '');

/// Provider that combines search text with current query.
/// When search text changes, it updates the fileQueryProvider.
final searchResultsProvider = FutureProvider<List<IndexedFile>>((ref) async {
  final db = ref.watch(indexDatabaseProvider);
  final searchText = ref.watch(searchTextProvider);

  if (searchText.isEmpty) {
    return db.query(const FileQuery.recent());
  }

  return db.query(FileQuery(search: searchText));
});

/// Provider for selected category filter.
final selectedCategoryProvider = StateProvider<FileCategory?>((ref) => null);

/// Combined provider: applies both search and category filter.
final filteredFilesProvider = FutureProvider<List<IndexedFile>>((ref) async {
  final db = ref.watch(indexDatabaseProvider);
  final searchText = ref.watch(searchTextProvider);
  final category = ref.watch(selectedCategoryProvider);

  final query = FileQuery(
    search: searchText.isEmpty ? null : searchText,
    categories: category != null ? {category} : null,
    sortOrder: FileSortOrder.newestFirst,
    limit: 100,
  );

  return db.query(query);
});

/// Index state notifier — handles scan operations.
class IndexStateNotifier extends StateNotifier<IndexState> {
  IndexStateNotifier(this._db) : super(const IndexState.idle());

  final IndexDatabase _db;

  /// Perform initial full scan (called via Platform Channel).
  /// The actual MediaStore query happens on the Kotlin side.
  /// This method receives the results and inserts them into SQLite.
  Future<void> performFullScan(List<IndexedFile> files) async {
    state = const IndexState.scanning(progress: 0);

    // Bulk insert in chunks of 500 for UI responsiveness
    const chunkSize = 500;
    for (var i = 0; i < files.length; i += chunkSize) {
      final chunk = files.sublist(i, (i + chunkSize).clamp(0, files.length));
      await _db.bulkInsert(chunk);
      state = IndexState.scanning(progress: (i + chunk.length) / files.length);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await _db.updateScanState(fullScan: now, totalFiles: files.length);
    state = IndexState.ready(totalFiles: files.length);
  }

  /// Perform incremental update (new/modified files since last scan).
  Future<void> performIncrementalUpdate(List<IndexedFile> newFiles, List<String> deletedPaths) async {
    state = const IndexState.updating();

    if (newFiles.isNotEmpty) {
      await _db.bulkInsert(newFiles);
    }
    if (deletedPaths.isNotEmpty) {
      await _db.removeByPaths(deletedPaths);
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final total = await _db.getTotalFileCount();
    await _db.updateScanState(incremental: now, totalFiles: total);
    state = IndexState.ready(totalFiles: total);
  }
}

/// Index lifecycle state.
sealed class IndexState {
  const IndexState();
  const factory IndexState.idle() = _Idle;
  const factory IndexState.scanning({required double progress}) = _Scanning;
  const factory IndexState.updating() = _Updating;
  const factory IndexState.ready({required int totalFiles}) = _Ready;
  const factory IndexState.error({required String message}) = _Error;
}

class _Idle extends IndexState {
  const _Idle();
}

class _Scanning extends IndexState {
  final double progress;
  const _Scanning({required this.progress});
}

class _Updating extends IndexState {
  const _Updating();
}

class _Ready extends IndexState {
  final int totalFiles;
  const _Ready({required this.totalFiles});
}

class _Error extends IndexState {
  final String message;
  const _Error({required this.message});
}

/// Provider for the index state notifier.
final indexStateProvider =
    StateNotifierProvider<IndexStateNotifier, IndexState>((ref) {
  final db = ref.watch(indexDatabaseProvider);
  return IndexStateNotifier(db);
});
