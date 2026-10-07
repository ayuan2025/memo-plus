import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/note_display_theme_settings.dart';
import '../../data/repositories/note_display_theme_settings_repository.dart';
import '../../features/memos/theme/memo_card_theme.dart';
import '../sync/sync_coordinator_provider.dart';
import '../../application/sync/sync_request.dart';
import '../system/session_provider.dart';

final noteDisplayThemeSettingsRepositoryProvider =
    Provider<NoteDisplayThemeSettingsRepository>((ref) {
      final session = ref.watch(appSessionProvider).valueOrNull;
      final key = session?.currentKey?.trim();
      final storageKey = (key == null || key.isEmpty) ? 'device' : key;
      return NoteDisplayThemeSettingsRepository(
        ref.watch(secureStorageProvider),
        accountKey: storageKey,
      );
    });

final noteDisplayThemeSettingsProvider = StateNotifierProvider<
    NoteDisplayThemeSettingsController, NoteDisplayThemeSettings>((ref) {
  return NoteDisplayThemeSettingsController(
    ref,
    ref.watch(noteDisplayThemeSettingsRepositoryProvider),
  );
});

/// 当前选中的卡片主题（全局统一）。`themeId` 无法匹配时回落到默认暖白主题。
final selectedMemoCardThemeProvider = Provider<MemoCardTheme>((ref) {
  final id = ref.watch(noteDisplayThemeSettingsProvider).themeId;
  return kMemoCardThemes.firstWhere(
    (theme) => theme.id == id,
    orElse: () => kMemoCardThemeWarmWhite,
  );
});

class NoteDisplayThemeSettingsController
    extends StateNotifier<NoteDisplayThemeSettings> {
  NoteDisplayThemeSettingsController(this._ref, this._repo)
    : super(NoteDisplayThemeSettings.defaults) {
    unawaited(_load());
  }

  final Ref _ref;
  final NoteDisplayThemeSettingsRepository _repo;

  Future<void> _load() async {
    final stored = await _repo.read();
    if (!mounted) return;
    state = stored;
  }

  void _setAndPersist(
    NoteDisplayThemeSettings next, {
    bool triggerSync = true,
  }) {
    state = next;
    unawaited(_repo.write(next));
    if (triggerSync) {
      unawaited(
        _ref.read(syncCoordinatorProvider.notifier).requestSync(
              const SyncRequest(
                kind: SyncRequestKind.webDavSync,
                reason: SyncRequestReason.settings,
              ),
            ),
      );
    }
  }

  Future<void> setThemeId(String id) async {
    final normalized = id.trim();
    if (normalized.isEmpty) return;
    if (state.themeId == normalized) return;
    _setAndPersist(state.copyWith(themeId: normalized));
  }
}
