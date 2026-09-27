import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/api/memos_live_refresh_api.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/content_fingerprint.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/location_settings.dart';
import 'package:memos_flutter_app/data/models/memo.dart';
import 'package:memos_flutter_app/data/models/memo_relation.dart';
import 'package:memos_flutter_app/data/models/reaction.dart';
import 'package:memos_flutter_app/data/models/resolved_app_settings.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/memos/memo_inline_image_syntax.dart';
import 'package:memos_flutter_app/features/memos/widgets/memo_engagement_surface.dart';
import 'package:memos_flutter_app/features/memos/widgets/memos_list_memo_card_container.dart';
import 'package:memos_flutter_app/features/memos/widgets/memos_list_memo_card.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/memo_detail_controller.dart';
import 'package:memos_flutter_app/state/memos/memo_detail_providers.dart';
import 'package:memos_flutter_app/state/memos/memo_engagement_provider.dart';
import 'package:memos_flutter_app/state/memos/memos_list_providers.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/settings/resolved_preferences_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('card hides compact engagement when preference is disabled', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );
    final source = _FakeMemosLiveRefreshEventSource();

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: false,
        client: client,
        liveRefreshEventSource: source,
      ),
    );
    await tester.pumpAndSettle();
    source.add(
      const MemosLiveRefreshEvent(
        type: MemosLiveRefreshEventType.reactionUpserted,
        name: 'memos/memo-1',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsNothing);
    expect(client.reactionLoadCalls, 0);
    expect(client.commentLoadCalls, 0);
  });

  testWidgets('card container hides engagement when unified gate is disabled', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );

    await tester.pumpWidget(
      _buildCardContainerHarness(
        memo: _localMemo(),
        showMemoEngagement: false,
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsNothing);
    expect(client.reactionLoadCalls, 0);
    expect(client.commentLoadCalls, 0);
  });

  testWidgets('card container shows engagement when unified gate is enabled', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );

    await tester.pumpWidget(
      _buildCardContainerHarness(
        memo: _localMemo(),
        showMemoEngagement: true,
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsOneWidget);
    expect(find.text('Like 1'), findsOneWidget);
    expect(find.text('Comment 1'), findsOneWidget);
  });

  testWidgets('local library card container never mounts engagement', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction()],
      comments: [_remoteMemo('comment')],
    );

    await tester.pumpWidget(
      _buildCardContainerHarness(
        memo: _localMemo(),
        showMemoEngagement: true,
        localLibraryMode: true,
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsNothing);
    expect(client.reactionLoadCalls, 0);
    expect(client.commentLoadCalls, 0);
  });

  testWidgets('card shows liker avatars and recent comment previews', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      reactions: [
        _reaction(creator: 'users/me'),
        _reaction(name: 'reactions/r2', creator: 'users/alice'),
        _reaction(name: 'reactions/r3', creator: 'users/bob'),
        _reaction(name: 'reactions/r4', creator: 'users/cara'),
        _reaction(name: 'reactions/r5', creator: 'users/dan'),
        _reaction(name: 'reactions/r6', creator: 'users/erin'),
      ],
      comments: [
        _remoteMemo('latest visible comment', creator: 'users/alice'),
        _remoteMemo(
          'second visible comment',
          name: 'memos/comment-2',
          creator: 'users/bob',
        ),
        _remoteMemo(
          'hidden overflow comment',
          name: 'memos/comment-3',
          creator: 'users/cara',
        ),
      ],
    );

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: client,
        users: _testUsers,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsOneWidget);
    expect(find.text('Like 6'), findsOneWidget);
    expect(find.text('Comment 3'), findsOneWidget);
    expect(find.byKey(memoEngagementCompactPreviewKey), findsOneWidget);
    expect(find.byKey(memoEngagementCompactLikeAvatarsKey), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(memoEngagementCompactLikeAvatarsKey),
        matching: find.byType(Image),
      ),
      findsWidgets,
    );
    expect(find.text('and 1 more liked'), findsOneWidget);
    expect(find.textContaining('latest visible comment'), findsOneWidget);
    expect(find.textContaining('second visible comment'), findsOneWidget);
    expect(find.textContaining('hidden overflow comment'), findsNothing);
    expect(find.text('View all comments'), findsOneWidget);
  });

  testWidgets('card view-all comments opens the existing engagement surface', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient(
      comments: [
        _remoteMemo('latest visible comment', creator: 'users/alice'),
        _remoteMemo(
          'second visible comment',
          name: 'memos/comment-2',
          creator: 'users/bob',
        ),
        _remoteMemo(
          'hidden overflow comment',
          name: 'memos/comment-3',
          creator: 'users/cara',
        ),
      ],
    );

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: client,
        users: _testUsers,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(memoEngagementViewAllCommentsButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementSurfaceKey), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('card shows zero-state compact engagement when enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: _FakeMemoEngagementClient(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementCompactBarKey), findsOneWidget);
    expect(find.text('Like 0'), findsOneWidget);
    expect(find.text('Comment 0'), findsOneWidget);
  });

  testWidgets('card updates engagement after live refresh event', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient();
    final source = _FakeMemosLiveRefreshEventSource();

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: client,
        users: _testUsers,
        liveRefreshEventSource: source,
        liveRefreshRegistry: MemoEngagementLiveRefreshRegistry(
          coalesceDelay: Duration.zero,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Like 0'), findsOneWidget);
    expect(find.text('Comment 0'), findsOneWidget);

    client.reactions = [_reaction(creator: 'users/alice')];
    client.comments = [_remoteMemo('live comment', creator: 'users/alice')];
    source
      ..add(
        const MemosLiveRefreshEvent(
          type: MemosLiveRefreshEventType.reactionUpserted,
          name: 'memos/memo-1',
        ),
      )
      ..add(
        const MemosLiveRefreshEvent(
          type: MemosLiveRefreshEventType.memoCommentCreated,
          name: 'memos/comment-1',
          parent: 'memos/memo-1',
        ),
      );
    await tester.pumpAndSettle();

    expect(find.text('Like 1'), findsOneWidget);
    expect(find.text('Comment 1'), findsOneWidget);
    expect(find.textContaining('live comment'), findsOneWidget);
  });

  testWidgets('card like action toggles the current user like', (tester) async {
    final client = _FakeMemoEngagementClient();

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(memoEngagementLikeButtonKey));
    await tester.pumpAndSettle();

    expect(client.upsertedReactions, hasLength(1));
    expect(find.text('Like 1'), findsOneWidget);
  });

  testWidgets('card comment action opens composer and submits comment', (
    tester,
  ) async {
    final client = _FakeMemoEngagementClient();

    await tester.pumpWidget(
      _buildCardHarness(
        memo: _localMemo(),
        showEngagement: true,
        client: client,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(memoEngagementCommentButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(memoEngagementSurfaceKey), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'from card');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(client.createdComments, ['from card']);
  });
}

Widget _buildCardContainerHarness({
  required LocalMemo memo,
  required bool showMemoEngagement,
  bool localLibraryMode = false,
  required _FakeMemoEngagementClient client,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  final position = ValueNotifier<Duration>(Duration.zero);
  final duration = ValueNotifier<Duration?>(null);
  final workspace = WorkspacePreferences.defaults.copyWith(
    showMemoEngagement: showMemoEngagement,
  );
  return ProviderScope(
    overrides: [
      memoEngagementClientProvider.overrideWithValue(client),
      memoDetailControllerProvider.overrideWith(
        (ref) => _FakeMemoDetailController(ref, const <String, User>{}),
      ),
      appSessionProvider.overrideWith(
        (ref) => _TestSessionController(hasAccount: !localLibraryMode),
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
          body: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: MemosListMemoCardContainer(
                memoCardKey: GlobalKey<MemoListCardState>(),
                memo: memo,
                heroTag: null,
                prefs: AppPreferences.defaultsForLanguage(AppLanguage.en),
                outboxStatus: const OutboxMemoStatus.empty(),
                tagColors: TagColorLookup(const []),
                removing: false,
                searching: false,
                windowsHeaderSearchExpanded: false,
                selectedQuickSearchKind: null,
                searchQuery: '',
                playingMemoUid: null,
                audioPlaying: false,
                audioLoading: false,
                audioPositionListenable: position,
                audioDurationListenable: duration,
                onAudioSeek: null,
                onAudioTap: null,
                onSyncStatusTap: null,
                onToggleTask: (_) {},
                onTap: () {},
                onAction: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Widget _buildCardHarness({
  required LocalMemo memo,
  required bool showEngagement,
  required _FakeMemoEngagementClient client,
  Map<String, User> users = const <String, User>{},
  _FakeMemosLiveRefreshEventSource? liveRefreshEventSource,
  MemoEngagementLiveRefreshRegistry? liveRefreshRegistry,
}) {
  LocaleSettings.setLocale(AppLocale.en);
  final overrides = <Override>[
    memoEngagementClientProvider.overrideWithValue(client),
    memoDetailControllerProvider.overrideWith(
      (ref) => _FakeMemoDetailController(ref, users),
    ),
    appSessionProvider.overrideWith((ref) => _TestSessionController()),
    memoRelationsProvider.overrideWith(
      (ref, uid) => Stream<List<MemoRelation>>.value(const <MemoRelation>[]),
    ),
  ];
  if (liveRefreshEventSource != null) {
    overrides.add(
      memosLiveRefreshEventSourceProvider.overrideWithValue(
        liveRefreshEventSource,
      ),
    );
  }
  if (liveRefreshRegistry != null) {
    overrides.add(
      memoEngagementLiveRefreshRegistryProvider.overrideWithValue(
        liveRefreshRegistry,
      ),
    );
  }
  return ProviderScope(
    overrides: overrides,
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: MemoListCard(
                memo: memo,
                dateText: '2024-01-02',
                reminderText: null,
                tagColors: TagColorLookup(const []),
                initiallyExpanded: false,
                highlightQuery: null,
                collapseLongContent: true,
                collapseReferences: true,
                showEngagement: showEngagement,
                isAudioPlaying: false,
                isAudioLoading: false,
                audioPositionListenable: null,
                audioDurationListenable: null,
                imageEntries: const [],
                mediaEntries: const [],
                useExpandedArticleBody: true,
                expandedInlineImageSyntax: MemoInlineImageSyntax.none,
                locationProvider: LocationServiceProvider.google,
                onAudioSeek: null,
                onAudioTap: null,
                syncStatus: MemoSyncStatus.none,
                onToggleTask: (_) {},
                onTap: () {},
                onAction: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

LocalMemo _localMemo() {
  final now = DateTime.utc(2024, 1, 2, 3, 4, 5);
  const content = 'memo body';
  return LocalMemo(
    uid: 'memo-1',
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const [],
    attachments: const [],
    relationCount: 0,
    syncState: SyncState.synced,
    lastError: null,
  );
}

Reaction _reaction({
  String name = 'reactions/r1',
  String creator = 'users/me',
  String reactionType = kMemoLikeReactionType,
}) {
  return Reaction(
    name: name,
    creator: creator,
    contentId: 'memos/memo-1',
    reactionType: reactionType,
  );
}

Memo _remoteMemo(
  String content, {
  String name = 'memos/comment-1',
  String creator = 'users/commenter',
}) {
  final now = DateTime.utc(2024, 1, 2, 3, 4, 5);
  return Memo(
    name: name,
    creator: creator,
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const [],
    attachments: const [],
  );
}

class _FakeMemoEngagementClient implements MemoEngagementClient {
  _FakeMemoEngagementClient({
    List<Reaction> reactions = const <Reaction>[],
    List<Memo> comments = const <Memo>[],
  }) : reactions = List<Reaction>.from(reactions),
       comments = List<Memo>.from(comments);

  List<Reaction> reactions;
  List<Memo> comments;
  final upsertedReactions = <Reaction>[];
  final deletedReactions = <Reaction>[];
  final createdComments = <String>[];
  int reactionLoadCalls = 0;
  int commentLoadCalls = 0;
  int _nextReaction = 1;
  int _nextComment = 1;

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
    final reaction = _reaction(
      name: 'reactions/${_nextReaction++}',
      reactionType: reactionType,
    );
    upsertedReactions.add(reaction);
    reactions.add(reaction);
    return reaction;
  }

  @override
  Future<void> deleteMemoReaction({required Reaction reaction}) async {
    deletedReactions.add(reaction);
    reactions = reactions.where((item) => item.name != reaction.name).toList();
  }

  @override
  Future<Memo> createMemoComment({
    required String memoUid,
    required String content,
    required String visibility,
  }) async {
    createdComments.add(content);
    final memo = _remoteMemo(content, name: 'memos/comment-${_nextComment++}');
    comments.insert(0, memo);
    return memo;
  }
}

class _FakeMemosLiveRefreshEventSource implements MemosLiveRefreshEventSource {
  final StreamController<MemosLiveRefreshEvent> _controller =
      StreamController<MemosLiveRefreshEvent>.broadcast();

  @override
  bool get isSupported => true;

  @override
  Stream<MemosLiveRefreshEvent> watchEvents({void Function()? onConnected}) {
    return _controller.stream;
  }

  void add(MemosLiveRefreshEvent event) {
    _controller.add(event);
  }
}

class _FakeMemoDetailController extends MemoDetailController {
  _FakeMemoDetailController(super.ref, this.users);

  final Map<String, User> users;

  @override
  Future<User?> fetchUser({required String name}) async {
    return users[name.trim()];
  }
}

const _avatarDataUri =
    'data:image/png;base64,'
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/'
    'x8AAwMCAO+/p9sAAAAASUVORK5CYII=';

final _testUsers = <String, User>{
  'users/me': const User(
    name: 'users/me',
    username: 'me',
    displayName: 'Me',
    avatarUrl: _avatarDataUri,
    description: '',
  ),
  'users/alice': const User(
    name: 'users/alice',
    username: 'alice',
    displayName: 'Alice',
    avatarUrl: _avatarDataUri,
    description: '',
  ),
  'users/bob': const User(
    name: 'users/bob',
    username: 'bob',
    displayName: 'Bob',
    avatarUrl: _avatarDataUri,
    description: '',
  ),
  'users/cara': const User(
    name: 'users/cara',
    username: 'cara',
    displayName: 'Cara',
    avatarUrl: _avatarDataUri,
    description: '',
  ),
  'users/dan': const User(
    name: 'users/dan',
    username: 'dan',
    displayName: 'Dan',
    avatarUrl: _avatarDataUri,
    description: '',
  ),
};

class _TestSessionController extends AppSessionController {
  _TestSessionController({bool hasAccount = true})
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
