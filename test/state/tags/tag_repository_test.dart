import 'dart:async';

import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/db/db_write_protocol.dart';
import 'package:memos_flutter_app/data/db/desktop_db_write_gateway.dart';
import 'package:memos_flutter_app/data/db/serialized_workspace_write_runner.dart';
import 'package:memos_flutter_app/data/db/workspace_write_host.dart';
import 'package:memos_flutter_app/data/models/tag.dart';
import 'package:memos_flutter_app/data/models/tag_snapshot.dart';
import 'package:memos_flutter_app/state/tags/tag_repository.dart';

import '../../test_support.dart';

void main() {
  late TestSupport support;

  setUpAll(() async {
    support = await initializeTestSupport();
  });

  tearDownAll(() async {
    await support.dispose();
  });

  test(
    'applySnapshot preserves metadata for memo tags missing from a stale snapshot',
    () async {
      final dbName = uniqueDbName('tag_repository_apply_snapshot');
      final db = AppDatabase(dbName: dbName);
      final repository = TagRepository(db: db);
      final now = DateTime.now().toUtc();

      await repository.createTag(
        name: 'projects',
        pinned: true,
        colorHex: '#AABBCC',
      );
      await db.upsertMemo(
        uid: 'memo-1',
        content: 'hello world',
        visibility: 'PRIVATE',
        pinned: false,
        state: 'NORMAL',
        createTimeSec: now.millisecondsSinceEpoch ~/ 1000,
        updateTimeSec: now.millisecondsSinceEpoch ~/ 1000,
        tags: const ['projects'],
        attachments: const [],
        location: null,
        relationCount: 0,
        syncState: 0,
        lastError: null,
      );

      await repository.applySnapshot(const TagSnapshot(tags: [], aliases: []));

      final restored = await repository.getTagByPath('projects');
      expect(restored, isNotNull);
      expect(restored!.pinned, isTrue);
      expect(restored.colorHex, '#AABBCC');

      final memo = await db.getMemoByUid('memo-1');
      expect(memo?['tags'], 'projects');

      await db.close();
      await deleteTestDatabase(dbName);
    },
  );

  test('updateTag uses remote gateway and decodes returned tag', () async {
    final dbName = uniqueDbName('tag_repository_remote_update');
    final db = AppDatabase(dbName: dbName, workspaceKey: 'workspace-tags');
    final response = TagEntity(
      id: 11,
      name: 'projects',
      path: 'projects',
      parentId: null,
      pinned: true,
      colorHex: '#AABBCC',
      createTimeSec: 10,
      updateTimeSec: 20,
    );
    final gateway = _CapturingRemoteGateway(responseValue: response.toJson());
    final repository = TagRepository(db: db, writeGateway: gateway);

    final updated = await repository.updateTag(id: 11, colorHex: '#AABBCC');

    expect(updated.id, 11);
    expect(updated.colorHex, '#AABBCC');
    expect(gateway.localExecuteCalled, isFalse);
    expect(gateway.workspaceKey, 'workspace-tags');
    expect(gateway.dbName, dbName);
    expect(gateway.commandType, tagRepositoryWriteCommandType);
    expect(gateway.operation, 'updateTag');
    expect(gateway.payload['id'], 11);
    expect(gateway.payload['colorHex'], '#AABBCC');
    expect(await repository.listTags(), isEmpty);

    await db.close();
    await deleteTestDatabase(dbName);
  });

  test(
    'updateTag surfaces retryable remote owner-unavailable errors',
    () async {
      final dbName = uniqueDbName('tag_repository_remote_owner_unavailable');
      final db = AppDatabase(dbName: dbName, workspaceKey: 'workspace-tags');
      final repository = TagRepository(
        db: db,
        writeGateway: _ThrowingRemoteGateway(
          const DbWriteException(
            code: 'main_window_unavailable',
            message: 'Main window is unavailable for database writes.',
            retryable: true,
          ),
        ),
      );

      await expectLater(
        repository.updateTag(id: 5, colorHex: '#112233'),
        throwsA(
          isA<DbWriteException>()
              .having((error) => error.code, 'code', 'main_window_unavailable')
              .having((error) => error.retryable, 'retryable', isTrue),
        ),
      );

      await db.close();
      await deleteTestDatabase(dbName);
    },
  );

  test(
    'tag repository preserves original envelope metadata on owner execution',
    () async {
      final dbName = uniqueDbName('tag_repository_owner_envelope');
      final host = _CapturingWorkspaceWriteHost();
      final gateway = LocalDesktopDbWriteGateway(
        host: host,
        originRole: 'main_app',
        originWindowId: 0,
      );
      final db = AppDatabase(
        dbName: dbName,
        workspaceKey: 'workspace-tags',
        writeGateway: gateway,
      );
      final repository = TagRepository(db: db, writeGateway: gateway);
      const request = DbWriteEnvelope(
        requestId: 'request-tag-1',
        workspaceKey: 'workspace-tags',
        dbName: 'placeholder.db',
        commandType: tagRepositoryWriteCommandType,
        operation: 'createTag',
        payload: <String, dynamic>{'name': 'projects'},
        originRole: 'desktop_settings',
        originWindowId: 7,
      );
      final envelope = DbWriteEnvelope(
        requestId: request.requestId,
        workspaceKey: request.workspaceKey,
        dbName: dbName,
        commandType: request.commandType,
        operation: request.operation,
        payload: request.payload,
        originRole: request.originRole,
        originWindowId: request.originWindowId,
      );

      try {
        await repository.executeWriteEnvelopeLocally(envelope);

        expect(host.lastEnvelope, isNotNull);
        expect(host.lastEnvelope?.requestId, 'request-tag-1');
        expect(host.lastEnvelope?.originRole, 'desktop_settings');
        expect(host.lastEnvelope?.originWindowId, 7);
        expect(await repository.getTagByPath('projects'), isNotNull);
      } finally {
        await db.close();
        await deleteTestDatabase(dbName);
      }
    },
  );

  test(
    'child-window tag update waits for owner sync-like write and succeeds',
    () async {
      final dbName = uniqueDbName('tag_repository_sync_write_serialization');
      const workspaceKey = 'workspace-tag-sync';
      final runner = SerializedWorkspaceWriteRunner();
      final localGateway = LocalDesktopDbWriteGateway(
        runner: runner,
        broadcaster: const DesktopDbChangeBroadcaster(),
        originRole: 'main_app',
        originWindowId: 0,
      );
      final ownerDb = AppDatabase(
        dbName: dbName,
        workspaceKey: workspaceKey,
        writeGateway: localGateway,
      );
      final ownerTagRepository = TagRepository(
        db: ownerDb,
        writeGateway: localGateway,
      );
      final syncWriterDb = AppDatabase(
        dbName: dbName,
        workspaceKey: workspaceKey,
      );
      final childDb = AppDatabase(dbName: dbName, workspaceKey: workspaceKey);
      final childTagRepository = TagRepository(
        db: childDb,
        writeGateway: _LoopbackRemoteGateway((envelope) async {
          switch (envelope.commandType) {
            case tagRepositoryWriteCommandType:
              return ownerTagRepository.executeWriteEnvelopeLocally(envelope);
            case appDatabaseWriteCommandType:
              return ownerDb.executeWriteEnvelopeLocally(envelope);
          }
          throw UnsupportedError(
            'Unsupported test command type: ${envelope.commandType}',
          );
        }),
      );

      try {
        final tag = await ownerTagRepository.createTag(name: 'projects');
        final syncWriteEntered = Completer<void>();
        final releaseSyncWrite = Completer<void>();
        var childUpdateCompleted = false;

        final syncWrite = localGateway.execute<void>(
          workspaceKey: workspaceKey,
          dbName: dbName,
          commandType: appDatabaseWriteCommandType,
          operation: 'upsertMemo',
          payload: const <String, dynamic>{},
          localExecute: () async {
            syncWriteEntered.complete();
            await releaseSyncWrite.future;
            final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
            await syncWriterDb.upsertMemo(
              uid: 'memo-sync',
              content: 'sync write',
              visibility: 'PRIVATE',
              pinned: false,
              state: 'NORMAL',
              createTimeSec: nowSec,
              updateTimeSec: nowSec,
              tags: const ['projects'],
              attachments: const [],
              location: null,
              relationCount: 0,
              syncState: 0,
              lastError: null,
            );
            return null;
          },
          decode: (_) {},
        );

        await syncWriteEntered.future;

        final childUpdate = childTagRepository
            .updateTag(id: tag.id, colorHex: '#123456')
            .then((value) {
              childUpdateCompleted = true;
              return value;
            });

        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(childUpdateCompleted, isFalse);

        releaseSyncWrite.complete();

        final updatedTag = await childUpdate;
        await syncWrite;

        final persistedTag = await ownerTagRepository.getTagByPath('projects');
        final memoRow = await ownerDb.getMemoByUid('memo-sync');

        expect(updatedTag.colorHex, '#123456');
        expect(persistedTag?.colorHex, '#123456');
        expect(memoRow, isNotNull);
        expect(memoRow?['tags'], 'projects');
      } finally {
        await childDb.close();
        await syncWriterDb.close();
        await ownerDb.close();
        await deleteTestDatabase(dbName);
      }
    },
  );
}

class _CapturingRemoteGateway implements DesktopDbWriteGateway {
  _CapturingRemoteGateway({this.responseValue});

  final Object? responseValue;

  bool localExecuteCalled = false;
  String? workspaceKey;
  String? dbName;
  String? commandType;
  String? operation;
  Map<String, dynamic> payload = const <String, dynamic>{};

  @override
  bool get isRemote => true;

  @override
  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    this.workspaceKey = workspaceKey;
    this.dbName = dbName;
    this.commandType = commandType;
    this.operation = operation;
    this.payload = Map<String, dynamic>.from(payload);
    return decode(responseValue);
  }
}

class _ThrowingRemoteGateway implements DesktopDbWriteGateway {
  _ThrowingRemoteGateway(this.error);

  final DbWriteException error;

  @override
  bool get isRemote => true;

  @override
  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) {
    throw error;
  }
}

class _LoopbackRemoteGateway implements DesktopDbWriteGateway {
  _LoopbackRemoteGateway(this.handler);

  final Future<Object?> Function(DbWriteEnvelope envelope) handler;

  @override
  bool get isRemote => true;

  @override
  Future<T> execute<T>({
    required String workspaceKey,
    required String dbName,
    required String commandType,
    required String operation,
    required Map<String, dynamic> payload,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    final raw = await handler(
      DbWriteEnvelope(
        requestId: 'test-$commandType-$operation',
        workspaceKey: workspaceKey,
        dbName: dbName,
        commandType: commandType,
        operation: operation,
        payload: Map<String, dynamic>.from(payload),
        originRole: 'desktop_settings',
        originWindowId: 7,
      ),
    );
    return decode(raw);
  }
}

class _CapturingWorkspaceWriteHost implements WorkspaceWriteHost {
  DbWriteEnvelope? lastEnvelope;

  @override
  Future<T> execute<T>({
    required DbWriteEnvelope envelope,
    required Future<Object?> Function() localExecute,
    required T Function(Object? raw) decode,
  }) async {
    lastEnvelope = envelope;
    final raw = await localExecute();
    return decode(raw);
  }
}
