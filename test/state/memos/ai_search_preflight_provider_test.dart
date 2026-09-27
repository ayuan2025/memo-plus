import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/ai/ai_semantic_memo_search_service.dart';
import 'package:memos_flutter_app/data/db/app_database.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/repositories/ai_settings_repository.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/settings/ai_settings_provider.dart';
import 'package:memos_flutter_app/state/system/database_provider.dart';

import '../../test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AI search preflight provider exposes required index work', () async {
    final support = await initializeTestSupport();
    final dbName = uniqueDbName('ai_search_preflight_provider');
    final db = AppDatabase(dbName: dbName);
    await db.db;
    addTearDown(() async {
      await db.close();
      await deleteTestDatabase(dbName);
      await support.dispose();
    });

    await db.upsertMemo(
      uid: 'memo-food',
      content: 'Dinner idea: dapanji big plate chicken with potatoes.',
      visibility: 'PRIVATE',
      pinned: false,
      state: 'NORMAL',
      createTimeSec: _utcSec(2026, 3, 2),
      updateTimeSec: _utcSec(2026, 3, 2),
      tags: const <String>['food'],
      attachments: const <Map<String, dynamic>>[],
      location: null,
      relationCount: 0,
      syncState: 0,
    );

    final container = _buildContainer(db, _semanticSearchSettings);
    addTearDown(container.dispose);

    final preflight = await container.read(
      aiSearchIndexPreflightProvider(_query(searchQuery: 'what to eat')).future,
    );

    expect(preflight.needsIndexing, isTrue);
    expect(preflight.memoCount, 1);
    expect(preflight.chunkCount, greaterThan(0));
    expect(preflight.estimatedTokenCount, greaterThan(0));
    expect(preflight.profileKey, 'test-embedding');
  });

  test(
    'AI search preflight provider passes configuration errors through',
    () async {
      final support = await initializeTestSupport();
      final dbName = uniqueDbName(
        'ai_search_preflight_provider_missing_config',
      );
      final db = AppDatabase(dbName: dbName);
      await db.db;
      addTearDown(() async {
        await db.close();
        await deleteTestDatabase(dbName);
        await support.dispose();
      });

      final container = _buildContainer(
        db,
        AiSettings.defaultsFor(AppLanguage.en),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(
          aiSearchIndexPreflightProvider(
            _query(searchQuery: 'what to eat'),
          ).future,
        ),
        throwsA(isA<AiSemanticMemoSearchConfigurationException>()),
      );
    },
  );
}

const _semanticEmbeddingProfile = AiEmbeddingProfile(
  profileKey: 'test-embedding',
  displayName: 'Test Embedding',
  backendKind: AiBackendKind.remoteApi,
  providerKind: AiProviderKind.openAiCompatible,
  baseUrl: 'https://example.com/v1',
  apiKey: 'test-key',
  model: 'test-embedding-model',
  enabled: true,
);

final _semanticSearchSettings = AiSettings.defaultsFor(AppLanguage.en).copyWith(
  embeddingProfiles: const <AiEmbeddingProfile>[_semanticEmbeddingProfile],
  selectedEmbeddingProfileKey: 'test-embedding',
);

ProviderContainer _buildContainer(AppDatabase db, AiSettings settings) {
  return ProviderContainer(
    overrides: [
      databaseProvider.overrideWithValue(db),
      aiSettingsProvider.overrideWith(
        (ref) => _TestAiSettingsController(ref, settings),
      ),
    ],
  );
}

class _TestAiSettingsController extends AiSettingsController {
  _TestAiSettingsController(Ref ref, AiSettings settings)
    : super(ref, _MemoryAiSettingsRepository(settings)) {
    state = settings;
  }
}

class _MemoryAiSettingsRepository extends AiSettingsRepository {
  _MemoryAiSettingsRepository(this._value)
    : super(const FlutterSecureStorage(), accountKey: 'test-account');

  AiSettings _value;

  @override
  Future<AiSettings> read({AppLanguage language = AppLanguage.en}) async =>
      _value;

  @override
  Future<void> write(AiSettings settings) async {
    _value = settings;
  }
}

AiSearchMemosQuery _query({required String searchQuery}) {
  return (
    searchQuery: searchQuery,
    state: 'NORMAL',
    tag: null,
    startTimeSec: null,
    endTimeSecExclusive: null,
    advancedFilters: AdvancedSearchFilters.empty,
    pageSize: 20,
  );
}

int _utcSec(int year, int month, int day) {
  return DateTime.utc(year, month, day).millisecondsSinceEpoch ~/ 1000;
}
