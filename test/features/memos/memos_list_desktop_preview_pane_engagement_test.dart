import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/content_fingerprint.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo.dart';
import 'package:memos_flutter_app/data/models/memo_relation.dart';
import 'package:memos_flutter_app/data/models/reaction.dart';
import 'package:memos_flutter_app/data/models/resolved_app_settings.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/memos/widgets/memo_engagement_surface.dart';
import 'package:memos_flutter_app/features/memos/widgets/memos_list_desktop_preview_pane.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/desktop_memo_preview_session.dart';
import 'package:memos_flutter_app/state/memos/memo_detail_controller.dart';
import 'package:memos_flutter_app/state/memos/memo_detail_providers.dart';
import 'package:memos_flutter_app/state/memos/memo_engagement_provider.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/resolved_preferences_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'desktop preview hides engagement when unified gate is disabled',
    (tester) async {
      final memo = _localMemo();
      final client = _FakeMemoEngagementClient(
        reactions: [_reaction()],
        comments: [_remoteMemo('comment')],
      );

      await tester.pumpWidget(
        _buildPreviewHarness(
          memo: memo,
          showMemoEngagement: false,
          client: client,
        ),
      );
      await _requestAndSettlePreview(tester, memo);

      expect(find.byKey(memoEngagementSurfaceKey), findsNothing);
      expect(client.reactionLoadCalls, 0);
      expect(client.commentLoadCalls, 0);
    },
  );

  testWidgets('desktop preview shows engagement when unified gate is enabled', (
    tester,
  ) async {
    final memo = _localMemo();
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );

    await tester.pumpWidget(
      _buildPreviewHarness(
        memo: memo,
        showMemoEngagement: true,
        client: client,
      ),
    );
    await _requestAndSettlePreview(tester, memo);

    expect(find.byKey(memoEngagementSurfaceKey), findsOneWidget);
    expect(find.text('Like 1'), findsOneWidget);
    expect(find.text('Comment 1'), findsOneWidget);
  });

  testWidgets('local library desktop preview never mounts engagement', (
    tester,
  ) async {
    final memo = _localMemo();
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );

    await tester.pumpWidget(
      _buildPreviewHarness(
        memo: memo,
        showMemoEngagement: true,
        localLibraryMode: true,
        client: client,
      ),
    );
    await _requestAndSettlePreview(tester, memo);

    expect(find.byKey(memoEngagementSurfaceKey), findsNothing);
    expect(client.reactionLoadCalls, 0);
    expect(client.commentLoadCalls, 0);
  });
}

Widget _buildPreviewHarness({
  required LocalMemo memo,
  required bool showMemoEngagement,
  bool localLibraryMode = false,
  required _FakeMemoEngagementClient client,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  final workspace = WorkspacePreferences.defaults.copyWith(
    showMemoEngagement: showMemoEngagement,
  );
  return ProviderScope(
    overrides: [
      appSessionProvider.overrideWith(
        (ref) => _TestSessionController(hasAccount: !localLibraryMode),
      ),
      devicePreferencesProvider.overrideWith(
        (ref) => _TestDevicePreferencesController(ref),
      ),
      resolvedAppSettingsProvider.overrideWithValue(
        ResolvedAppSettings(
          device: DevicePreferences.defaultsForLanguage(AppLanguage.en),
          workspace: workspace,
          workspaceKey: localLibraryMode ? 'local-library' : 'test',
          hasWorkspace: true,
          hasRemoteAccount: !localLibraryMode,
          isLocalLibraryMode: localLibraryMode,
        ),
      ),
      memoEngagementClientProvider.overrideWithValue(client),
      memoDetailControllerProvider.overrideWith(
        (ref) => _FakeMemoDetailController(ref),
      ),
      memoRelationsProvider.overrideWith(
        (ref, uid) => Stream<List<MemoRelation>>.value(const <MemoRelation>[]),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SizedBox(
            width: 520,
            height: 700,
            child: MemosListDesktopPreviewPane(
              selectedMemo: memo,
              isVisible: true,
              suspendAudio: false,
              onClose: () {},
              onEditMemo: () {},
              onOpenMemo: () {},
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _requestAndSettlePreview(
  WidgetTester tester,
  LocalMemo memo,
) async {
  await tester.pump();
  final container = ProviderScope.containerOf(
    tester.element(find.byType(MemosListDesktopPreviewPane)),
  );
  await container
      .read(desktopMemoPreviewSessionProvider.notifier)
      .requestMemo(memo);
  for (var i = 0; i < 20; i++) {
    await tester.pump(const Duration(milliseconds: 120));
    final phase = container.read(desktopMemoPreviewSessionProvider).phase;
    if (phase == DesktopMemoPreviewPhase.ready &&
        find
            .textContaining('preview body', findRichText: true)
            .evaluate()
            .isNotEmpty) {
      break;
    }
  }
  await tester.pumpAndSettle();
}

LocalMemo _localMemo() {
  final now = DateTime.utc(2024, 1, 2, 3, 4, 5);
  const content = 'preview body';
  return LocalMemo(
    uid: 'memo-1',
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const <String>[],
    attachments: const <Attachment>[],
    relationCount: 0,
    syncState: SyncState.synced,
    lastError: null,
  );
}

Reaction _reaction() {
  return const Reaction(
    name: 'reactions/r1',
    creator: 'users/me',
    contentId: 'memos/memo-1',
    reactionType: kMemoLikeReactionType,
  );
}

Memo _remoteMemo(String content) {
  final now = DateTime.utc(2024, 1, 2, 3, 4, 5);
  return Memo(
    name: 'memos/comment-1',
    creator: 'users/me',
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const <String>[],
    attachments: const <Attachment>[],
  );
}

class _FakeMemoEngagementClient implements MemoEngagementClient {
  _FakeMemoEngagementClient({
    List<Reaction> reactions = const <Reaction>[],
    List<Memo> comments = const <Memo>[],
  }) : reactions = List<Reaction>.from(reactions),
       comments = List<Memo>.from(comments);

  final List<Reaction> reactions;
  final List<Memo> comments;
  int reactionLoadCalls = 0;
  int commentLoadCalls = 0;

  @override
  Future<({List<Reaction> reactions, String nextPageToken, int totalSize})>
  listMemoReactions({required String memoUid, int pageSize = 50}) async {
    reactionLoadCalls += 1;
    return (
      reactions: List<Reaction>.from(reactions),
      nextPageToken: '',
      totalSize: reactions.length,
    );
  }

  @override
  Future<({List<Memo> memos, String nextPageToken, int totalSize})>
  listMemoComments({required String memoUid, int pageSize = 50}) async {
    commentLoadCalls += 1;
    return (
      memos: List<Memo>.from(comments),
      nextPageToken: '',
      totalSize: comments.length,
    );
  }

  @override
  Future<Reaction> upsertMemoReaction({
    required String memoUid,
    required String reactionType,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteMemoReaction({required Reaction reaction}) async {
    throw UnimplementedError();
  }

  @override
  Future<Memo> createMemoComment({
    required String memoUid,
    required String content,
    required String visibility,
  }) async {
    throw UnimplementedError();
  }
}

class _FakeMemoDetailController extends MemoDetailController {
  _FakeMemoDetailController(super.ref);

  @override
  Future<User?> fetchUser({required String name}) async {
    return User(
      name: name,
      username: name.split('/').last,
      displayName: name.split('/').last,
      avatarUrl: '',
      description: '',
    );
  }
}

class _TestSessionController extends AppSessionController {
  _TestSessionController({required bool hasAccount})
    : super(
        AsyncValue.data(
          hasAccount
              ? AppSessionState(accounts: [_testAccount], currentKey: 'test')
              : const AppSessionState(
                  accounts: <Account>[],
                  currentKey: 'local-library',
                ),
        ),
      );

  @override
  Future<void> addAccountWithPat({
    required Uri baseUrl,
    required String personalAccessToken,
    bool? useLegacyApiOverride,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> addAccountWithPassword({
    required Uri baseUrl,
    required String username,
    required String password,
    required bool useLegacyApi,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<InstanceProfile> detectCurrentAccountInstanceProfile() async {
    return const InstanceProfile.empty();
  }

  @override
  Future<void> refreshCurrentUser({bool ignoreErrors = true}) async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  Future<void> removeAccount(String accountKey) async {}

  @override
  String resolveEffectiveServerVersionForAccount({required Account account}) {
    return account.serverVersionOverride ?? account.instanceProfile.version;
  }

  @override
  InstanceProfile resolveEffectiveInstanceProfileForAccount({
    required Account account,
  }) {
    return account.instanceProfile;
  }

  @override
  bool resolveUseLegacyApiForAccount({
    required Account account,
    required bool globalDefault,
  }) {
    return globalDefault;
  }

  @override
  Future<void> setCurrentAccountServerVersionOverride(String? version) async {}

  @override
  Future<void> setCurrentAccountUseLegacyApiOverride(bool value) async {}

  @override
  Future<void> setCurrentKey(String? key) async {}

  @override
  Future<void> switchAccount(String accountKey) async {}

  @override
  Future<void> switchWorkspace(String workspaceKey) async {}
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref)
    : super(
        ref,
        _TestDevicePreferencesRepository(),
        onLoaded: () {
          ref.read(devicePreferencesLoadedProvider.notifier).state = true;
        },
      ) {
    state = DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository()
    : super(PreferencesMigrationService(const FlutterSecureStorage()));

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(
      DevicePreferences.defaultsForLanguage(AppLanguage.en),
    );
  }

  @override
  Future<DevicePreferences> read() async {
    return DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }

  @override
  Future<void> write(DevicePreferences prefs) async {}
}

final _testAccount = Account(
  key: 'test',
  baseUrl: Uri.parse('https://example.com'),
  personalAccessToken: 'token',
  user: const User(
    name: 'users/me',
    username: 'me',
    displayName: 'Me',
    avatarUrl: '',
    description: '',
  ),
  instanceProfile: const InstanceProfile(
    version: '0.24.0',
    mode: '',
    instanceUrl: '',
    owner: '',
  ),
);
