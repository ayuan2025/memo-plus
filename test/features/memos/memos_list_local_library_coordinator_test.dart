import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/local_library_scan_service.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/data/local_library/local_library_fs.dart';
import 'package:memos_flutter_app/features/memos/memos_list_local_library_coordinator.dart';

void main() {
  testWidgets(
    'maybeAutoScan aborts when coordinator is disposed before frame callback',
    (tester) async {
      await tester.pumpWidget(const SizedBox());

      final adapter = _FakeLocalLibraryAdapter(
        scanner: _FakeLocalLibraryScanService(
          fileSystem: _FakeLocalLibraryFileSystem(
            memos: const <LocalLibraryFileEntry>[
              LocalLibraryFileEntry(
                relativePath: 'memos/a.md',
                name: 'a.md',
                isDir: false,
                length: 1,
                lastModified: null,
              ),
            ],
          ),
        ),
      );
      final coordinator = MemosListLocalLibraryCoordinator(
        read: _unusedRead,
        adapterOverride: adapter,
      );

      await coordinator.maybeAutoScan(
        hasCurrentLibrary: true,
        normalMemoCount: 0,
        syncRunning: false,
      );
      coordinator.dispose();

      await tester.pump();

      expect(adapter.hasAnyLocalMemosCount, 0);
      expect(adapter.requestMemosSyncCount, 0);
    },
  );

}

Never _unusedRead<T>(Object provider) {
  throw UnimplementedError('read should not be used in this test');
}

class _FakeLocalLibraryAdapter implements MemosListLocalLibraryAdapter {
  _FakeLocalLibraryAdapter({
    this.scanner,
    Future<bool>? hasAnyLocalMemosResult,
  }) : _hasAnyLocalMemosResult = hasAnyLocalMemosResult ?? Future.value(false);

  final LocalLibraryScanService? scanner;
  final Future<bool> _hasAnyLocalMemosResult;

  int hasAnyLocalMemosCount = 0;
  int requestMemosSyncCount = 0;

  @override
  LocalLibraryScanService? currentScanner() => scanner;

  @override
  SyncFlowStatus currentSyncStatus() => SyncFlowStatus.idle;

  @override
  Future<bool> hasAnyLocalMemos() {
    hasAnyLocalMemosCount++;
    return _hasAnyLocalMemosResult;
  }

  @override
  Future<void> requestMemosSync() async {
    requestMemosSyncCount++;
  }
}

class _FakeLocalLibraryScanService extends Fake
    implements LocalLibraryScanService {
  _FakeLocalLibraryScanService({required this.fileSystem});

  @override
  final LocalLibraryFileSystem fileSystem;
}

class _FakeLocalLibraryFileSystem extends Fake
    implements LocalLibraryFileSystem {
  _FakeLocalLibraryFileSystem({required List<LocalLibraryFileEntry> memos})
    : _memos = memos;

  final List<LocalLibraryFileEntry> _memos;

  @override
  Future<List<LocalLibraryFileEntry>> listMemos() async => _memos;
}
