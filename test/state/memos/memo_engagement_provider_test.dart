import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/content_fingerprint.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/memo.dart';
import 'package:memos_flutter_app/data/models/reaction.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/api/memos_live_refresh_api.dart';
import 'package:memos_flutter_app/state/memos/memo_engagement_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

void main() {
  test('reaction helpers count unique likes and shape other summaries', () {
    final reactions = <Reaction>[
      _reaction(creator: 'users/alice'),
      _reaction(creator: 'users/alice'),
      _reaction(creator: 'users/bob', reactionType: 'HEART'),
      _reaction(creator: 'users/cara', reactionType: 'THUMBS_UP'),
      _reaction(creator: 'users/cara', reactionType: 'THUMBS_UP'),
      _reaction(creator: 'users/dan', reactionType: 'THUMBS_UP'),
      _reaction(creator: '', reactionType: 'FIRE'),
    ];

    expect(countMemoLikeCreators(reactions), 2);
    expect(hasCurrentUserMemoLike(reactions, 'users/bob'), isTrue);
    expect(hasCurrentUserMemoLike(reactions, 'users/missing'), isFalse);
    expect(uniqueMemoCreatorReactions(reactions).map((r) => r.creator), [
      'users/alice',
      'users/bob',
      'users/cara',
      'users/dan',
    ]);
    expect(memoOtherReactionSummaries(reactions), [
      const MemoReactionSummary(reactionType: 'THUMBS_UP', count: 2),
      const MemoReactionSummary(reactionType: 'FIRE', count: 1),
    ]);
  });

  test(
    'controller loads zero-state summary once for concurrent requests',
    () async {
      final client = _FakeMemoEngagementClient();
      final container = _buildContainer(client: client);
      addTearDown(container.dispose);

      final controller = container.read(
        memoEngagementControllerProvider(_request).notifier,
      );

      await Future.wait(<Future<void>>[controller.load(), controller.load()]);

      final state = container.read(memoEngagementControllerProvider(_request));
      expect(state.loaded, isTrue);
      expect(state.snapshot.hasEngagement, isFalse);
      expect(state.snapshot.likeCount, 0);
      expect(state.snapshot.visibleCommentCount, 0);
      expect(client.reactionLoadCalls, 1);
      expect(client.commentLoadCalls, 1);
    },
  );

  test('controller detects current user like and toggles snapshot', () async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction(creator: 'users/me')],
    );
    final container = _buildContainer(client: client);
    addTearDown(container.dispose);
    final provider = memoEngagementControllerProvider(_request);
    final controller = container.read(provider.notifier);

    await controller.load();
    expect(container.read(provider).snapshot.hasUserLike('users/me'), isTrue);
    expect(container.read(provider).snapshot.likeCount, 1);

    await controller.toggleLike();

    expect(container.read(provider).snapshot.hasUserLike('users/me'), isFalse);
    expect(container.read(provider).snapshot.likeCount, 0);
    expect(client.deletedReactions, hasLength(1));

    await controller.toggleLike();

    expect(container.read(provider).snapshot.hasUserLike('users/me'), isTrue);
    expect(container.read(provider).snapshot.likeCount, 1);
    expect(client.upsertedReactions, hasLength(1));
  });

  test('controller appends created comments to cached snapshot', () async {
    final client = _FakeMemoEngagementClient(comments: [_memo('first')]);
    final container = _buildContainer(client: client);
    addTearDown(container.dispose);
    final provider = memoEngagementControllerProvider(_request);
    final controller = container.read(provider.notifier);

    await controller.load();
    await controller.createComment('second');

    final snapshot = container.read(provider).snapshot;
    expect(snapshot.visibleCommentCount, 2);
    expect(snapshot.comments.map((memo) => memo.content), ['second', 'first']);
    expect(client.createdComments, ['second']);
  });

  test('live reaction event force refreshes active reactions only', () async {
    final client = _FakeMemoEngagementClient();
    final source = _FakeMemosLiveRefreshEventSource();
    final registry = MemoEngagementLiveRefreshRegistry(
      coalesceDelay: Duration.zero,
    );
    final container = _buildContainer(
      client: client,
      liveRefreshEventSource: source,
      liveRefreshRegistry: registry,
    );
    addTearDown(container.dispose);
    addTearDown(source.close);
    final subscription = container.listen<void>(
      memoEngagementLiveRefreshRegistrationProvider(_request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    client.reactions = [_reaction(creator: 'users/alice')];
    source.add(
      const MemosLiveRefreshEvent(
        type: MemosLiveRefreshEventType.reactionUpserted,
        name: 'memos/memo-1',
      ),
    );
    await pumpEventQueue(times: 4);

    final state = container.read(memoEngagementControllerProvider(_request));
    expect(state.snapshot.likeCount, 1);
    expect(client.reactionLoadCalls, 1);
    expect(client.commentLoadCalls, 0);
  });

  test('live comment event force refreshes active comments only', () async {
    final client = _FakeMemoEngagementClient();
    final source = _FakeMemosLiveRefreshEventSource();
    final registry = MemoEngagementLiveRefreshRegistry(
      coalesceDelay: Duration.zero,
    );
    final container = _buildContainer(
      client: client,
      liveRefreshEventSource: source,
      liveRefreshRegistry: registry,
    );
    addTearDown(container.dispose);
    addTearDown(source.close);
    final subscription = container.listen<void>(
      memoEngagementLiveRefreshRegistrationProvider(_request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    client.comments = [_memo('live comment')];
    source.add(
      const MemosLiveRefreshEvent(
        type: MemosLiveRefreshEventType.memoCommentCreated,
        name: 'memos/comment-1',
        parent: 'memos/memo-1',
      ),
    );
    await pumpEventQueue(times: 4);

    final state = container.read(memoEngagementControllerProvider(_request));
    expect(state.snapshot.visibleCommentCount, 1);
    expect(state.snapshot.comments.single.content, 'live comment');
    expect(client.reactionLoadCalls, 0);
    expect(client.commentLoadCalls, 1);
  });

  test('live refresh coalesces duplicate memo reaction events', () async {
    final client = _FakeMemoEngagementClient(
      reactions: [_reaction(creator: 'users/alice')],
    );
    final source = _FakeMemosLiveRefreshEventSource();
    final registry = MemoEngagementLiveRefreshRegistry(
      coalesceDelay: Duration.zero,
    );
    final container = _buildContainer(
      client: client,
      liveRefreshEventSource: source,
      liveRefreshRegistry: registry,
    );
    addTearDown(container.dispose);
    addTearDown(source.close);
    final subscription = container.listen<void>(
      memoEngagementLiveRefreshRegistrationProvider(_request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    source
      ..add(
        const MemosLiveRefreshEvent(
          type: MemosLiveRefreshEventType.reactionUpserted,
          name: 'memos/memo-1',
        ),
      )
      ..add(
        const MemosLiveRefreshEvent(
          type: MemosLiveRefreshEventType.reactionDeleted,
          name: 'memos/memo-1/reactions/r1',
        ),
      );
    await pumpEventQueue(times: 4);

    expect(client.reactionLoadCalls, 1);
    expect(client.commentLoadCalls, 0);
  });

  test(
    'live refresh connected callback compensates active engagement',
    () async {
      final client = _FakeMemoEngagementClient(
        reactions: [_reaction(creator: 'users/alice')],
        comments: [_memo('live comment')],
      );
      final source = _FakeMemosLiveRefreshEventSource(callConnected: true);
      final registry = MemoEngagementLiveRefreshRegistry(
        coalesceDelay: Duration.zero,
      );
      final container = _buildContainer(
        client: client,
        liveRefreshEventSource: source,
        liveRefreshRegistry: registry,
      );
      addTearDown(container.dispose);
      addTearDown(source.close);
      final subscription = container.listen<void>(
        memoEngagementLiveRefreshRegistrationProvider(_request),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await pumpEventQueue(times: 4);

      final state = container.read(memoEngagementControllerProvider(_request));
      expect(state.snapshot.likeCount, 1);
      expect(state.snapshot.visibleCommentCount, 1);
      expect(client.reactionLoadCalls, 1);
      expect(client.commentLoadCalls, 1);
    },
  );
}

const _request = MemoEngagementRequest(
  memoUid: 'memo-1',
  memoVisibility: 'PRIVATE',
);

ProviderContainer _buildContainer({
  required _FakeMemoEngagementClient client,
  _FakeMemosLiveRefreshEventSource? liveRefreshEventSource,
  MemoEngagementLiveRefreshRegistry? liveRefreshRegistry,
}) {
  final overrides = <Override>[
    memoEngagementClientProvider.overrideWithValue(client),
    appSessionProvider.overrideWith((ref) => _TestSessionController()),
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
  return ProviderContainer(overrides: overrides);
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

Memo _memo(String content, {String name = 'memos/comment-1'}) {
  final now = DateTime.utc(2024, 1, 2, 3, 4, 5);
  return Memo(
    name: name,
    creator: 'users/me',
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
  final deletedReactions = <Reaction>[];
  final upsertedReactions = <Reaction>[];
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
    final memo = _memo(content, name: 'memos/comment-${_nextComment++}');
    comments.insert(0, memo);
    return memo;
  }
}

class _FakeMemosLiveRefreshEventSource implements MemosLiveRefreshEventSource {
  _FakeMemosLiveRefreshEventSource({this.callConnected = false});

  final bool callConnected;
  final StreamController<MemosLiveRefreshEvent> _controller =
      StreamController<MemosLiveRefreshEvent>.broadcast();

  int listenCount = 0;

  @override
  bool get isSupported => true;

  @override
  Stream<MemosLiveRefreshEvent> watchEvents({void Function()? onConnected}) {
    listenCount += 1;
    if (callConnected) {
      onConnected?.call();
    }
    return _controller.stream;
  }

  void add(MemosLiveRefreshEvent event) {
    _controller.add(event);
  }

  Future<void> close() async {
    await _controller.close();
  }
}

class _TestSessionController extends AppSessionController {
  _TestSessionController()
    : super(
        AsyncValue.data(
          AppSessionState(accounts: [_testAccount], currentKey: 'test'),
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
  user: User(
    name: 'users/me',
    username: 'me',
    displayName: 'Me',
    avatarUrl: '',
    description: '',
  ),
  instanceProfile: InstanceProfile(
    version: '0.24.0',
    mode: '',
    instanceUrl: '',
    owner: '',
  ),
);
