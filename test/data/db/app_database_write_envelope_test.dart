import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/db/db_write_protocol.dart';
import 'package:memos_flutter_app/data/db/desktop_db_write_gateway.dart';
import 'package:memos_flutter_app/data/db/workspace_write_host.dart';

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
    'app database preserves original envelope metadata on owner execution',
    () async {
      final dbName = uniqueDbName('app_database_write_envelope');
      final host = _CapturingWorkspaceWriteHost();
      final gateway = LocalDesktopDbWriteGateway(
        host: host,
        originRole: 'main_app',
        originWindowId: 0,
      );
      final db = AppDatabase(
        dbName: dbName,
        workspaceKey: 'workspace-app',
        writeGateway: gateway,
      );
      const envelope = DbWriteEnvelope(
        requestId: 'request-app-1',
        workspaceKey: 'workspace-app',
        dbName: '',
        commandType: appDatabaseWriteCommandType,
        operation: 'upsertComposeDraftRow',
        payload: <String, dynamic>{},
        originRole: 'desktop_settings',
        originWindowId: 11,
      );

      final request = DbWriteEnvelope(
        requestId: envelope.requestId,
        workspaceKey: envelope.workspaceKey,
        dbName: dbName,
        commandType: envelope.commandType,
        operation: envelope.operation,
        payload: <String, dynamic>{
          'row': <String, Object?>{
            'uid': 'draft-1',
            'workspace_key': 'workspace-app',
            'content': 'hello',
            'visibility': 'PRIVATE',
            'relations_json': '[]',
            'attachments_json': '[]',
            'created_time': 1,
            'updated_time': 2,
          },
        },
        originRole: envelope.originRole,
        originWindowId: envelope.originWindowId,
      );

      try {
        await db.executeWriteEnvelopeLocally(request);

        expect(host.lastEnvelope, isNotNull);
        expect(host.lastEnvelope?.requestId, 'request-app-1');
        expect(host.lastEnvelope?.originRole, 'desktop_settings');
        expect(host.lastEnvelope?.originWindowId, 11);

        final row = await db.getComposeDraftRow(
          uid: 'draft-1',
          workspaceKey: 'workspace-app',
        );
        expect(row?['content'], 'hello');
      } finally {
        await db.close();
        await deleteTestDatabase(dbName);
      }
    },
  );

  test(
    'app database composites dispatch as a single remote write command',
    () async {
      final gateway = _CapturingRemoteGateway();
      final db = AppDatabase(
        dbName: 'remote-app.db',
        workspaceKey: 'workspace-app',
        writeGateway: gateway,
      );

      try {
        await db.completeOutboxTask(42);
        expect(gateway.operations, <String>['completeOutboxTask']);
        expect(gateway.payloads.single['id'], 42);

        gateway.clear();

        await db.renameMemoUidAndRewriteOutboxMemoUids(
          oldUid: 'local-1',
          newUid: 'remote-1',
        );
        expect(gateway.operations, <String>[
          'renameMemoUidAndRewriteOutboxMemoUids',
        ]);
        expect(gateway.payloads.single, <String, dynamic>{
          'oldUid': 'local-1',
          'newUid': 'remote-1',
        });

        gateway.clear();

        await db.discardMissingSourceUploadTask(
          outboxId: 7,
          memoUid: 'memo-1',
          attachmentUid: 'att-1',
        );
        expect(gateway.operations, <String>['discardMissingSourceUploadTask']);
        expect(gateway.payloads.single, <String, dynamic>{
          'outboxId': 7,
          'memoUid': 'memo-1',
          'attachmentUid': 'att-1',
        });

        gateway.clear();

        await db.enqueueOutboxBatch(
          items: <Map<String, Object?>>[
            <String, Object?>{
              'type': 'create_memo',
              'payload': <String, Object?>{'uid': 'memo-1'},
            },
            <String, Object?>{
              'type': 'upload_attachment',
              'payload': <String, Object?>{
                'memo_uid': 'memo-1',
                'uid': 'att-1',
              },
            },
          ],
        );
        expect(gateway.operations, <String>['enqueueOutboxBatch']);
        expect((gateway.payloads.single['items'] as List).length, 2);

        gateway.clear();

        await db.deleteOutboxItems(<int>[1, 2, 3]);
        expect(gateway.operations, <String>['deleteOutboxItems']);
        expect(gateway.payloads.single['ids'], <int>[1, 2, 3]);

        gateway.clear();

        await db.deleteMemoAfterRecycleBinMove(
          memoUid: 'memo-1',
          draftAttachmentNames: <String>['resources/att-1'],
        );
        expect(gateway.operations, <String>['deleteMemoAfterRecycleBinMove']);
        expect(gateway.payloads.single, <String, dynamic>{
          'memoUid': 'memo-1',
          'draftAttachmentNames': <String>['resources/att-1'],
        });

        gateway.clear();

        await db.replaceMemoFromLocalLibrary(
          uid: 'memo-1',
          content: 'disk content',
          visibility: 'PRIVATE',
          pinned: false,
          state: 'NORMAL',
          createTimeSec: 1,
          displayTimeSec: 2,
          displayTimeSpecified: true,
          updateTimeSec: 3,
          tags: const <String>['disk'],
          attachments: const <Map<String, dynamic>>[],
          location: null,
          relationCount: 0,
          syncState: 0,
          clearOutbox: true,
          relationsMode: 'clear',
        );
        expect(gateway.operations, <String>['replaceMemoFromLocalLibrary']);
        expect(gateway.payloads.single['uid'], 'memo-1');
        expect(gateway.payloads.single['clearOutbox'], isTrue);
        expect(gateway.payloads.single['relationsMode'], 'clear');

        gateway.clear();

        await db.deleteMemoFromLocalLibrary(memoUid: 'memo-1');
        expect(gateway.operations, <String>['deleteMemoFromLocalLibrary']);
        expect(gateway.payloads.single, <String, dynamic>{'memoUid': 'memo-1'});
      } finally {
        await db.close();
      }
    },
  );

  test('app database batch outbox helpers preserve local order', () async {
    final dbName = uniqueDbName('app_database_outbox_batch');
    final db = AppDatabase(dbName: dbName, workspaceKey: 'workspace-app');

    try {
      final inserted = await db.enqueueOutboxBatch(
        items: <Map<String, Object?>>[
          <String, Object?>{
            'type': 'upload_attachment',
            'payload': <String, Object?>{'memo_uid': 'memo-1', 'uid': 'att-1'},
          },
          <String, Object?>{
            'type': 'create_memo',
            'payload': <String, Object?>{'uid': 'memo-1'},
          },
          <String, Object?>{
            'type': 'delete_attachment',
            'payload': <String, Object?>{
              'memo_uid': 'memo-1',
              'attachment_name': 'old',
            },
          },
        ],
      );

      expect(inserted, 3);

      final pending = await db.listOutboxPending(limit: 10);
      expect(
        pending.map((row) => row['type']).toList(growable: false),
        <Object?>['upload_attachment', 'create_memo', 'delete_attachment'],
      );

      final deleted = await db.deleteOutboxItems(
        pending
            .map((row) => row['id'])
            .whereType<int>()
            .toList(growable: false)
            .sublist(0, 2),
      );
      expect(deleted, 2);

      final remaining = await db.listOutboxPending(limit: 10);
      expect(remaining, hasLength(1));
      expect(remaining.single['type'], 'delete_attachment');
    } finally {
      await db.close();
      await deleteTestDatabase(dbName);
    }
  });
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

class _CapturingRemoteGateway implements DesktopDbWriteGateway {
  final List<String> operations = <String>[];
  final List<Map<String, dynamic>> payloads = <Map<String, dynamic>>[];

  @override
  bool get isRemote => true;

  void clear() {
    operations.clear();
    payloads.clear();
  }

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
    operations.add(operation);
    payloads.add(Map<String, dynamic>.from(payload));
    return decode(0);
  }
}
