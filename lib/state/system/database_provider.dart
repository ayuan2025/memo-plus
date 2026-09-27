import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/desktop_runtime_role.dart';
import '../../core/hash.dart';
import '../../data/db/app_database.dart';
import '../../data/db/desktop_db_write_gateway.dart';
import '../../data/db/serialized_workspace_write_runner.dart';
import '../../data/db/database_registry.dart';
import '../../data/db/workspace_write_host.dart';
import 'session_provider.dart';

String databaseNameForAccountKey(String accountKey) {
  return 'memos_app_${fnv1a64Hex(accountKey)}.db';
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final accountKey = ref.watch(
    appSessionProvider.select((state) => state.valueOrNull?.currentKey),
  );
  if (accountKey == null) {
    throw StateError('Not authenticated');
  }

  final dbName = databaseNameForAccountKey(accountKey);
  final writeGateway = ref.watch(desktopDbWriteGatewayProvider);
  final db = DatabaseRegistry.acquire(
    dbName,
    create: () => AppDatabase(
      dbName: dbName,
      workspaceKey: accountKey,
      writeGateway: writeGateway,
    ),
  );
  ref.onDispose(() {
    DatabaseRegistry.release(dbName);
  });
  return db;
});

final _workspaceWriteRunnerProvider = Provider<SerializedWorkspaceWriteRunner>((
  ref,
) {
  return SerializedWorkspaceWriteRunner();
});

final _desktopDbChangeBroadcasterProvider = Provider<DesktopDbChangeBroadcaster>((
  ref,
) {
  return const DesktopDbChangeBroadcaster();
});

final workspaceWriteHostProvider = Provider<WorkspaceWriteHost>((ref) {
  return SerializingWorkspaceWriteHost(
    runner: ref.watch(_workspaceWriteRunnerProvider),
    broadcaster: ref.watch(_desktopDbChangeBroadcasterProvider),
  );
});

final desktopDbWriteGatewayProvider = Provider<DesktopDbWriteGateway?>((ref) {
  final runtimeRole = ref.watch(desktopRuntimeRoleProvider);
  final windowId = ref.watch(desktopWindowIdProvider);
  final originRole = runtimeRole.logName;
  if (runtimeRole == DesktopRuntimeRole.mainApp) {
    return LocalDesktopDbWriteGateway(
      host: ref.watch(workspaceWriteHostProvider),
      originRole: originRole,
      originWindowId: windowId,
    );
  }
  return RemoteDesktopDbWriteGateway(
    originRole: originRole,
    originWindowId: windowId,
  );
});
