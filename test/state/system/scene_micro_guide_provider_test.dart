import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/repositories/scene_micro_guide_repository.dart';
import 'package:memos_flutter_app/state/system/scene_micro_guide_provider.dart';

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = <String, String>{};

  Iterable<String> get keys => _data.keys;

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
      return;
    }
    _data[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  test('loads empty state by default', () async {
    final storage = _MemorySecureStorage();
    final controller = SceneMicroGuideController(
      SceneMicroGuideRepository(storage),
    );

    await controller.load();

    expect(controller.state.loaded, isTrue);
    expect(controller.state.seen, isEmpty);
  });

  test('markSeen is idempotent', () async {
    final storage = _MemorySecureStorage();
    final controller = SceneMicroGuideController(
      SceneMicroGuideRepository(storage),
    );
    await controller.load();

    await controller.markSeen(SceneMicroGuideId.memoListGestures);
    await controller.markSeen(SceneMicroGuideId.memoListGestures);

    expect(controller.state.seen, {SceneMicroGuideId.memoListGestures});
    final raw = await storage.read(key: SceneMicroGuideRepository.storageKey);
    expect(jsonDecode(raw!), [SceneMicroGuideId.memoListGestures.name]);
  });

  test('uses a device scoped storage key', () async {
    final storage = _MemorySecureStorage();
    final repository = SceneMicroGuideRepository(storage);

    await repository.write({SceneMicroGuideId.desktopGlobalShortcuts});

    expect(storage.keys, [SceneMicroGuideRepository.storageKey]);
  });
}
