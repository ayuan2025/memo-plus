import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/db/db_write_protocol.dart';
import 'package:memos_flutter_app/data/db/serialized_workspace_write_runner.dart';
import 'package:memos_flutter_app/data/db/workspace_write_host.dart';

void main() {
  test('serializing host preserves original envelope metadata in broadcasts', () async {
    final broadcaster = _CapturingDesktopDbChangeBroadcaster();
    final host = SerializingWorkspaceWriteHost(
      runner: SerializedWorkspaceWriteRunner(),
      broadcaster: broadcaster,
    );
    const envelope = DbWriteEnvelope(
      requestId: 'request-1',
      workspaceKey: 'workspace-a',
      dbName: 'workspace.db',
      commandType: tagRepositoryWriteCommandType,
      operation: 'updateTag',
      payload: <String, dynamic>{'id': 7},
      originRole: 'desktop_settings',
      originWindowId: 9,
    );

    final result = await host.execute<String>(
      envelope: envelope,
      localExecute: () async => 'ok',
      decode: (raw) => raw as String,
    );

    expect(result, 'ok');
    expect(broadcaster.lastEvent, isNotNull);
    expect(broadcaster.lastEvent?.changeId, 'request-1');
    expect(broadcaster.lastEvent?.originWindowId, 9);
    expect(broadcaster.lastEvent?.category, 'tag_repository.updateTag');
  });
}

class _CapturingDesktopDbChangeBroadcaster extends DesktopDbChangeBroadcaster {
  DesktopDbChangeEvent? lastEvent;

  @override
  Future<void> broadcast(DesktopDbChangeEvent event) async {
    lastEvent = event;
  }
}
