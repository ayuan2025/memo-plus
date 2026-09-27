import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'package:memos_flutter_app/core/debug_ephemeral_storage.dart';
import 'package:memos_flutter_app/data/local_library/local_library_paths.dart';

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
    'managed workspace and WebDAV mirror paths live under app support',
    () async {
      final supportDir = await resolveAppSupportDirectory();
      final workspacePath = await resolveManagedWorkspacePath('workspace-key');
      final mirrorPath = await resolveManagedWebDavMirrorPath('account-hash');

      expect(
        workspacePath,
        p.join(supportDir.path, 'workspaces', 'workspace-key', 'library'),
      );
      expect(
        mirrorPath,
        p.join(supportDir.path, 'webdav_mirrors', 'account-hash'),
      );
      expect(await Directory(workspacePath).exists(), isTrue);
      expect(await Directory(mirrorPath).exists(), isTrue);
    },
  );
}
