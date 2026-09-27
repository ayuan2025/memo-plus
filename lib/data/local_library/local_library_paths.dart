import 'dart:io';

import 'package:path/path.dart' as p;

import '../../core/debug_ephemeral_storage.dart';

const _managedWorkspacesDirName = 'workspaces';
const _managedWebDavMirrorsDirName = 'webdav_mirrors';
const _managedLibraryDirName = 'library';

Future<String> resolveManagedWorkspacePath(String workspaceKey) async {
  final root = await _managedWorkspacesRoot();
  final dir = Directory(
    p.join(root.path, _sanitizeSegment(workspaceKey), _managedLibraryDirName),
  );
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}

Future<String> resolveManagedWebDavMirrorPath(String accountHash) async {
  final root = await _managedWebDavMirrorsRoot();
  final dir = Directory(p.join(root.path, _sanitizeSegment(accountHash)));
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  return dir.path;
}

Future<void> ensureManagedWorkspaceStructure(String workspaceKey) async {
  await resolveManagedWorkspacePath(workspaceKey);
}

Future<Directory> _managedWorkspacesRoot() async {
  final supportDir = await resolveAppSupportDirectory();
  final root = Directory(p.join(supportDir.path, _managedWorkspacesDirName));
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  return root;
}

Future<Directory> _managedWebDavMirrorsRoot() async {
  final supportDir = await resolveAppSupportDirectory();
  final root = Directory(p.join(supportDir.path, _managedWebDavMirrorsDirName));
  if (!await root.exists()) {
    await root.create(recursive: true);
  }
  return root;
}

String _sanitizeSegment(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return 'default';
  return trimmed.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
}
