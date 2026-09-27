import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop_runtime_role.dart';
import 'package:memos_flutter_app/data/db/desktop_db_write_gateway.dart';
import 'package:memos_flutter_app/data/db/workspace_write_host.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';

void main() {
  test(
    'workspaceWriteHostProvider returns serializing host',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final host = container.read(workspaceWriteHostProvider);

      expect(host, isA<SerializingWorkspaceWriteHost>());
    },
  );

  test(
    'desktopDbWriteGatewayProvider returns local gateway in main runtime',
    () {
      final container = ProviderContainer(
        overrides: [
          desktopRuntimeRoleProvider.overrideWith(
            (ref) => DesktopRuntimeRole.mainApp,
          ),
          desktopWindowIdProvider.overrideWith((ref) => 7),
        ],
      );
      addTearDown(container.dispose);

      final gateway = container.read(desktopDbWriteGatewayProvider);

      expect(gateway, isA<LocalDesktopDbWriteGateway>());
      expect(gateway, isA<OwnerDesktopDbWriteGateway>());
    },
  );

  test(
    'desktopDbWriteGatewayProvider returns remote gateway in settings runtime',
    () {
      final container = ProviderContainer(
        overrides: [
          desktopRuntimeRoleProvider.overrideWith(
            (ref) => DesktopRuntimeRole.desktopSettings,
          ),
          desktopWindowIdProvider.overrideWith((ref) => 9),
        ],
      );
      addTearDown(container.dispose);

      final gateway = container.read(desktopDbWriteGatewayProvider);

      expect(gateway, isA<RemoteDesktopDbWriteGateway>());
      expect(gateway?.isRemote, isTrue);
    },
  );
}
