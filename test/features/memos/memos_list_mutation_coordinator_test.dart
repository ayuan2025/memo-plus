import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/content_fingerprint.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/features/memos/memos_list_inline_compose_coordinator.dart';
import 'package:memos_flutter_app/features/memos/memos_list_mutation_coordinator.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';

void main() {
  test('quick input returns noop for blank content', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter();
    final sync = _FakeMutationSyncAdapter();
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: sync,
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final result = await coordinator.submitQuickInput(
      rawContent: '   ',
      visibility: 'PRIVATE',
    );

    expect(result.kind, MemosListMutationResultKind.noop);
    expect(repository.createQuickInputCallCount, 0);
    expect(sync.requestCallCount, 0);
    expect(coordinator.desktopQuickInputSubmitting, isFalse);
  });

  test(
    'quick input success generates uid, trims content, extracts tags and syncs',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter()
        ..createQuickInputCompleter = Completer<void>();
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
        now: () => DateTime.utc(2025, 1, 2, 3, 4, 5),
        uidFactory: () => 'memo-quick-1',
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      final future = coordinator.submitQuickInput(
        rawContent: '#work\n\nhello   ',
        visibility: 'PROTECTED',
      );

      expect(coordinator.desktopQuickInputSubmitting, isTrue);
      repository.createQuickInputCompleter!.complete();
      final result = await future;
      await Future<void>.delayed(Duration.zero);

      expect(result.kind, MemosListMutationResultKind.handled);
      expect(repository.createQuickInputCallCount, 1);
      expect(repository.lastQuickInputUid, 'memo-quick-1');
      expect(repository.lastQuickInputContent, '#work\n\nhello');
      expect(repository.lastQuickInputVisibility, 'PROTECTED');
      expect(repository.lastQuickInputNowSec, 1735787045);
      expect(repository.lastQuickInputTags, const <String>['work']);
      expect(sync.requestCallCount, 1);
      expect(coordinator.desktopQuickInputSubmitting, isFalse);
    },
  );

  test('quick input failure returns failed and clears busy flag', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()
      ..quickInputError = StateError('quick input failed');
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: _FakeMutationSyncAdapter(),
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final result = await coordinator.submitQuickInput(
      rawContent: 'hello',
      visibility: 'PRIVATE',
    );

    expect(result.kind, MemosListMutationResultKind.failed);
    expect(result.error, isA<StateError>());
    expect(coordinator.desktopQuickInputSubmitting, isFalse);
  });

  test('inline compose success forwards full draft and syncs', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()
      ..createInlineComposeCompleter = Completer<void>();
    final sync = _FakeMutationSyncAdapter();
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: sync,
      now: () => DateTime.utc(2025, 2, 3, 4, 5, 6),
      uidFactory: () => 'memo-inline-1',
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final draft = _buildDraft();
    final future = coordinator.submitInlineCompose(draft);

    expect(coordinator.inlineComposeSubmitting, isTrue);
    repository.createInlineComposeCompleter!.complete();
    final result = await future;
    await Future<void>.delayed(Duration.zero);

    expect(result.kind, MemosListMutationResultKind.handled);
    expect(repository.createInlineComposeCallCount, 1);
    expect(repository.lastInlineComposeUid, 'memo-inline-1');
    expect(repository.lastInlineComposeContent, draft.content);
    expect(repository.lastInlineComposeVisibility, draft.visibility);
    expect(repository.lastInlineComposeNowSec, 1738555506);
    expect(repository.lastInlineComposeTags, draft.tags);
    expect(repository.lastInlineComposeAttachments, draft.attachmentsPayload);
    expect(repository.lastInlineComposeLocation, draft.location);
    expect(repository.lastInlineComposeRelations, draft.relations);
    expect(
      repository.lastInlineComposePendingAttachments,
      draft.pendingAttachments,
    );
    expect(sync.requestCallCount, 1);
    expect(coordinator.inlineComposeSubmitting, isFalse);
  });

  test('inline compose returns noop when already busy', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()
      ..createInlineComposeCompleter = Completer<void>();
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: _FakeMutationSyncAdapter(),
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final firstFuture = coordinator.submitInlineCompose(_buildDraft());
    final secondResult = await coordinator.submitInlineCompose(_buildDraft());

    expect(coordinator.inlineComposeSubmitting, isTrue);
    expect(secondResult.kind, MemosListMutationResultKind.noop);
    repository.createInlineComposeCompleter!.complete();
    await firstFuture;
  });

  test(
    'update memo routes through repository and requests sync by default',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter();
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      final memo = _buildMemo();
      final result = await coordinator.updateMemo(memo, pinned: true);
      await Future<void>.delayed(Duration.zero);

      expect(result.kind, MemosListMutationResultKind.handled);
      expect(repository.updateMemoCallCount, 1);
      expect(repository.lastUpdatedMemo, memo);
      expect(repository.lastUpdatedPinned, isTrue);
      expect(repository.lastUpdatedState, isNull);
      expect(sync.requestCallCount, 1);
    },
  );

  test(
    'update memo content noop when unchanged and respects triggerSync false',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter();
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      final memo = _buildMemo(content: 'same content');
      final noopResult = await coordinator.updateMemoContent(
        memo,
        'same content',
      );
      expect(noopResult.kind, MemosListMutationResultKind.noop);
      expect(repository.updateMemoContentCallCount, 0);
      expect(sync.requestCallCount, 0);

      final handledResult = await coordinator.updateMemoContent(
        memo,
        'updated content',
        preserveUpdateTime: true,
        triggerSync: false,
      );
      await Future<void>.delayed(Duration.zero);

      expect(handledResult.kind, MemosListMutationResultKind.handled);
      expect(repository.updateMemoContentCallCount, 1);
      expect(repository.lastUpdatedContentMemo, memo);
      expect(repository.lastUpdatedContent, 'updated content');
      expect(repository.lastPreserveUpdateTime, isTrue);
      expect(sync.requestCallCount, 0);
    },
  );

  test(
    'adjust memo time routes through repository and requests sync',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter();
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      final memo = _buildMemo();
      final selectedTime = DateTime.utc(2025, 2, 3, 4, 5);
      final result = await coordinator.adjustMemoTime(
        memo: memo,
        selectedTime: selectedTime,
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.kind, MemosListMutationResultKind.handled);
      expect(repository.adjustMemoTimeCallCount, 1);
      expect(repository.lastAdjustedTimeMemo, memo);
      expect(repository.lastSelectedTime, selectedTime);
      expect(sync.requestCallCount, 1);
    },
  );

  test(
    'delete forwards recycle-bin callback and syncs after success',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter();
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      var recycleBinCallbackCalled = false;
      final result = await coordinator.deleteMemo(
        _buildMemo(uid: 'memo-delete'),
        onMovedToRecycleBin: () => recycleBinCallbackCalled = true,
      );
      await Future<void>.delayed(Duration.zero);

      expect(result.kind, MemosListMutationResultKind.handled);
      expect(repository.deleteMemoCallCount, 1);
      expect(recycleBinCallbackCalled, isTrue);
      expect(sync.requestCallCount, 1);
    },
  );

  test('delete failure returns failed', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()
      ..deleteError = StateError('delete failed');
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: _FakeMutationSyncAdapter(),
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final result = await coordinator.deleteMemo(_buildMemo(uid: 'memo-delete'));

    expect(result.kind, MemosListMutationResultKind.failed);
    expect(result.error, isA<StateError>());
  });

  test(
    'retry failed sync returns openSyncQueue for blank or zero retry count',
    () async {
      final container = ProviderContainer();
      final repository = _FakeMutationRepositoryAdapter()
        ..retryOutboxResult = 0;
      final sync = _FakeMutationSyncAdapter();
      final coordinator = MemosListMutationCoordinator(
        read: container.read,
        repositoryOverride: repository,
        syncOverride: sync,
      );
      addTearDown(() {
        coordinator.dispose();
        container.dispose();
      });

      final blankResult = await coordinator.retryFailedMemoSync('   ');
      final zeroResult = await coordinator.retryFailedMemoSync('memo-1');

      expect(
        blankResult.kind,
        MemosListRetryFailedSyncResultKind.openSyncQueue,
      );
      expect(zeroResult.kind, MemosListRetryFailedSyncResultKind.openSyncQueue);
      expect(sync.requestCallCount, 0);
    },
  );

  test('retry failed sync starts retry and requests sync', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()..retryOutboxResult = 3;
    final sync = _FakeMutationSyncAdapter();
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: sync,
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final result = await coordinator.retryFailedMemoSync(' memo-retry ');
    await Future<void>.delayed(Duration.zero);

    expect(result.kind, MemosListRetryFailedSyncResultKind.retryStarted);
    expect(result.retriedCount, 3);
    expect(repository.lastRetriedMemoUid, 'memo-retry');
    expect(sync.requestCallCount, 1);
  });

  test('retry failed sync failure returns failed', () async {
    final container = ProviderContainer();
    final repository = _FakeMutationRepositoryAdapter()
      ..retryOutboxError = StateError('retry failed');
    final coordinator = MemosListMutationCoordinator(
      read: container.read,
      repositoryOverride: repository,
      syncOverride: _FakeMutationSyncAdapter(),
    );
    addTearDown(() {
      coordinator.dispose();
      container.dispose();
    });

    final result = await coordinator.retryFailedMemoSync('memo-retry');

    expect(result.kind, MemosListRetryFailedSyncResultKind.failed);
    expect(result.error, isA<StateError>());
  });
}

InlineComposeSubmissionDraft _buildDraft() {
  return InlineComposeSubmissionDraft(
    content: 'draft #work',
    visibility: 'PRIVATE',
    tags: const <String>['work'],
    relations: const <Map<String, dynamic>>[
      {
        'relatedMemo': {'name': 'memos/1'},
        'type': 'REFERENCE',
      },
    ],
    attachmentsPayload: const <Map<String, dynamic>>[
      {
        'name': 'attachments/1',
        'filename': 'image.png',
        'type': 'image/png',
        'size': 12,
        'externalLink': '',
      },
    ],
    pendingAttachments: const <MemoComposerPendingAttachment>[
      MemoComposerPendingAttachment(
        uid: 'pending-1',
        filePath: 'C:/tmp/image.png',
        filename: 'image.png',
        mimeType: 'image/png',
        size: 12,
      ),
    ],
    location: const MemoLocation(
      placeholder: 'Home',
      latitude: 1.2,
      longitude: 3.4,
    ),
  );
}

LocalMemo _buildMemo({String uid = 'memo-1', String content = 'hello #tag'}) {
  return LocalMemo(
    uid: uid,
    content: content,
    contentFingerprint: computeContentFingerprint(content),
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: DateTime.utc(2025, 1, 1),
    updateTime: DateTime.utc(2025, 1, 1, 1),
    tags: const <String>['tag'],
    attachments: const <Attachment>[],
    relationCount: 0,
    syncState: SyncState.synced,
    lastError: null,
  );
}

class _FakeMutationRepositoryAdapter
    implements MemosListMutationRepositoryAdapter {
  Completer<void>? createQuickInputCompleter;
  Completer<void>? createInlineComposeCompleter;
  Object? quickInputError;
  Object? inlineComposeError;
  Object? updateMemoError;
  Object? adjustMemoTimeError;
  Object? updateMemoContentError;
  Object? deleteError;
  Object? retryOutboxError;
  int retryOutboxResult = 0;

  int createQuickInputCallCount = 0;
  int createInlineComposeCallCount = 0;
  int updateMemoCallCount = 0;
  int adjustMemoTimeCallCount = 0;
  int updateMemoContentCallCount = 0;
  int deleteMemoCallCount = 0;

  String? lastQuickInputUid;
  String? lastQuickInputContent;
  String? lastQuickInputVisibility;
  int? lastQuickInputNowSec;
  List<String>? lastQuickInputTags;

  String? lastInlineComposeUid;
  String? lastInlineComposeContent;
  String? lastInlineComposeVisibility;
  int? lastInlineComposeNowSec;
  List<String>? lastInlineComposeTags;
  List<Map<String, dynamic>>? lastInlineComposeAttachments;
  MemoLocation? lastInlineComposeLocation;
  List<Map<String, dynamic>>? lastInlineComposeRelations;
  List<MemoComposerPendingAttachment>? lastInlineComposePendingAttachments;

  LocalMemo? lastUpdatedMemo;
  bool? lastUpdatedPinned;
  String? lastUpdatedState;

  LocalMemo? lastAdjustedTimeMemo;
  DateTime? lastSelectedTime;

  LocalMemo? lastUpdatedContentMemo;
  String? lastUpdatedContent;
  bool? lastPreserveUpdateTime;

  LocalMemo? lastDeletedMemo;
  String? lastRetriedMemoUid;

  @override
  Future<void> createQuickInputMemo({
    required String uid,
    required String content,
    required String visibility,
    required int nowSec,
    required List<String> tags,
  }) async {
    createQuickInputCallCount++;
    lastQuickInputUid = uid;
    lastQuickInputContent = content;
    lastQuickInputVisibility = visibility;
    lastQuickInputNowSec = nowSec;
    lastQuickInputTags = tags;
    if (createQuickInputCompleter != null) {
      await createQuickInputCompleter!.future;
    }
    if (quickInputError != null) {
      throw quickInputError!;
    }
  }

  @override
  Future<void> createInlineComposeMemo({
    required String uid,
    required String content,
    required String visibility,
    required int nowSec,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required List<Map<String, dynamic>> relations,
    required List<MemoComposerPendingAttachment> pendingAttachments,
  }) async {
    createInlineComposeCallCount++;
    lastInlineComposeUid = uid;
    lastInlineComposeContent = content;
    lastInlineComposeVisibility = visibility;
    lastInlineComposeNowSec = nowSec;
    lastInlineComposeTags = tags;
    lastInlineComposeAttachments = attachments;
    lastInlineComposeLocation = location;
    lastInlineComposeRelations = relations;
    lastInlineComposePendingAttachments = pendingAttachments;
    if (createInlineComposeCompleter != null) {
      await createInlineComposeCompleter!.future;
    }
    if (inlineComposeError != null) {
      throw inlineComposeError!;
    }
  }

  @override
  Future<void> updateMemo(LocalMemo memo, {bool? pinned, String? state}) async {
    updateMemoCallCount++;
    lastUpdatedMemo = memo;
    lastUpdatedPinned = pinned;
    lastUpdatedState = state;
    if (updateMemoError != null) {
      throw updateMemoError!;
    }
  }

  @override
  Future<void> adjustMemoTime({
    required LocalMemo memo,
    required DateTime selectedTime,
  }) async {
    adjustMemoTimeCallCount++;
    lastAdjustedTimeMemo = memo;
    lastSelectedTime = selectedTime;
    if (adjustMemoTimeError != null) {
      throw adjustMemoTimeError!;
    }
  }

  @override
  Future<void> updateMemoContent(
    LocalMemo memo,
    String content, {
    bool preserveUpdateTime = false,
  }) async {
    updateMemoContentCallCount++;
    lastUpdatedContentMemo = memo;
    lastUpdatedContent = content;
    lastPreserveUpdateTime = preserveUpdateTime;
    if (updateMemoContentError != null) {
      throw updateMemoContentError!;
    }
  }

  @override
  Future<void> deleteMemo(
    LocalMemo memo, {
    VoidCallback? onMovedToRecycleBin,
  }) async {
    deleteMemoCallCount++;
    lastDeletedMemo = memo;
    onMovedToRecycleBin?.call();
    if (deleteError != null) {
      throw deleteError!;
    }
  }

  @override
  Future<int> retryOutboxErrors({required String memoUid}) async {
    lastRetriedMemoUid = memoUid;
    if (retryOutboxError != null) {
      throw retryOutboxError!;
    }
    return retryOutboxResult;
  }
}

class _FakeMutationSyncAdapter implements MemosListMutationSyncAdapter {
  int requestCallCount = 0;

  @override
  Future<void> requestMemosSync() async {
    requestCallCount++;
  }
}
