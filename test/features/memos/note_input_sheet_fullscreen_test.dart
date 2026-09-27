import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/sync_coordinator.dart';
import 'package:memos_flutter_app/application/sync/sync_error.dart';
import 'package:memos_flutter_app/application/sync/sync_request.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/application/sync/webdav_backup_service.dart';
import 'package:memos_flutter_app/application/sync/webdav_sync_service.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/core/desktop/shortcuts.dart';
import 'package:memos_flutter_app/core/share_inline_image_content.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/compose_draft.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/data/models/memo_template_settings.dart';
import 'package:memos_flutter_app/data/models/user_setting.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/data/repositories/memo_template_settings_repository.dart';
import 'package:memos_flutter_app/features/memos/note_input_sheet.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';
import 'package:memos_flutter_app/state/memos/compose_draft_provider.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/memos/note_input_controller.dart';
import 'package:memos_flutter_app/state/memos/note_input_providers.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/memo_template_settings_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';
import 'package:memos_flutter_app/state/settings/user_settings_provider.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.en));
  tearDown(() {
    debugPlatformTargetOverride = null;
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('expands from embedded compact control and preserves text', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: const NoteInputSheet(
          initialText: 'Long draft body',
          ignoreDraft: true,
          autoFocus: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(_expandButton, findsOneWidget);
    expect(_fullscreenTopToolbar, findsNothing);
    expect(find.text('Long draft body'), findsOneWidget);

    await tester.tap(_expandButton);
    await tester.pumpAndSettle();

    expect(_expandButton, findsNothing);
    expect(_fullscreenTopToolbar, findsOneWidget);
    expect(_fullscreenBottomToolbar, findsOneWidget);
    expect(_collapseButton, findsOneWidget);
    expect(_closeButton, findsOneWidget);
    expect(find.text('Create Memo'), findsNothing);
    expect(find.text('Long draft body'), findsOneWidget);
    expect(
      tester.getCenter(_closeButton).dx,
      lessThan(tester.getCenter(_collapseButton).dx),
    );
    expect(
      tester.getTopLeft(_fullscreenTopToolbar).dy,
      greaterThan(tester.getBottomLeft(_fullscreenTextField).dy),
    );
    expect(
      tester.getTopLeft(_fullscreenBottomToolbar).dy,
      greaterThan(tester.getBottomLeft(_fullscreenTextField).dy),
    );
    expect(
      tester.getCenter(_fullscreenVisibilityButton).dy,
      lessThan(tester.getCenter(_fullscreenSendButton).dy),
    );

    await tester.tap(_collapseButton);
    await tester.pumpAndSettle();

    expect(_expandButton, findsOneWidget);
    expect(_fullscreenTopToolbar, findsNothing);
    expect(find.text('Long draft body'), findsOneWidget);

    await _disposeHarness(tester);
  });

  testWidgets('keeps visibility selection when toggling fullscreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: const NoteInputSheet(ignoreDraft: true, autoFocus: false),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_expandButton);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.lock).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Public').last);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.public), findsOneWidget);

    await tester.tap(_collapseButton);
    await tester.pumpAndSettle();
    await tester.tap(_expandButton);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.public), findsOneWidget);

    await _disposeHarness(tester);
  });

  testWidgets('fullscreen top chrome avoids modal status bar inset', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 780);
    tester.view.padding = const FakeViewPadding(top: 36);
    tester.view.viewPadding = const FakeViewPadding(top: 36);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewPadding);

    await tester.pumpWidget(
      _buildHarness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => unawaited(
                NoteInputSheet.show(
                  context,
                  initialText: 'Route opened draft',
                  ignoreDraft: true,
                  autoFocus: false,
                ),
              ),
              child: const Text('Open compose'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open compose'));
    await tester.pumpAndSettle();
    await tester.tap(_expandButton);
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(_closeButton).dy, greaterThanOrEqualTo(36));
    expect(tester.getTopLeft(_collapseButton).dy, greaterThanOrEqualTo(36));

    await _disposeHarness(tester);
  });

  testWidgets('show opens note input sheet on apple mobile target', (
    tester,
  ) async {
    debugPlatformTargetOverride = TargetPlatform.iOS;

    await tester.pumpWidget(
      _buildHarness(
        child: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => unawaited(
                NoteInputSheet.show(
                  context,
                  initialText: 'Apple compose',
                  ignoreDraft: true,
                  autoFocus: false,
                ),
              ),
              child: const Text('Open compose'),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open compose'));
    await tester.pumpAndSettle();

    expect(find.byType(NoteInputSheet), findsOneWidget);
    expect(find.text('Apple compose'), findsOneWidget);

    await _disposeHarness(tester);
  });

  testWidgets('expanding to fullscreen focuses editor and opens keyboard', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        child: const NoteInputSheet(
          initialText: 'Focus target',
          ignoreDraft: true,
          autoFocus: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.testTextInput.isVisible, isFalse);

    await tester.tap(_expandButton);
    await tester.pumpAndSettle();

    final textField = tester.widget<TextField>(_fullscreenTextField);
    expect(textField.focusNode?.hasFocus, isTrue);
    expect(tester.testTextInput.isVisible, isTrue);

    await _disposeHarness(tester);
  });

  testWidgets(
    'expanding to fullscreen reopens keyboard when editor has focus',
    (tester) async {
      await tester.pumpWidget(
        _buildHarness(
          child: const NoteInputSheet(
            initialText: 'Already focused',
            ignoreDraft: true,
            autoFocus: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      expect(tester.testTextInput.isVisible, isTrue);

      tester.testTextInput.hide();
      tester.testTextInput.log.clear();
      expect(tester.testTextInput.isVisible, isFalse);

      await tester.tap(_expandButton);
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(_fullscreenTextField);
      expect(textField.focusNode?.hasFocus, isTrue);
      expect(tester.testTextInput.hasAnyClients, isTrue);
      expect(tester.testTextInput.isVisible, isTrue);
      expect(
        tester.testTextInput.log.any(
          (call) => call.method == 'TextInput.clearClient',
        ),
        isTrue,
      );
      expect(
        tester.testTextInput.log.any(
          (call) => call.method == 'TextInput.setClient',
        ),
        isTrue,
      );
      expect(
        tester.testTextInput.log.any((call) => call.method == 'TextInput.show'),
        isTrue,
      );

      tester.testTextInput.enterText('Typed after fullscreen');
      await tester.pump();
      final focusedTextField = tester.widget<TextField>(_fullscreenTextField);
      expect(focusedTextField.controller?.text, 'Typed after fullscreen');

      await _disposeHarness(tester);
    },
  );

  testWidgets('fullscreen send uses note input submit path', (tester) async {
    final controller = _RecordingNoteInputController();
    await tester.pumpWidget(
      _buildHarness(
        noteInputController: controller,
        child: const NoteInputSheet(
          initialText: 'Send this memo',
          ignoreDraft: true,
          autoFocus: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_expandButton);
    await tester.pumpAndSettle();
    await tester.tap(_fullscreenSendButton);
    await tester.pumpAndSettle();

    expect(controller.createdContents, ['Send this memo']);

    await _disposeHarness(tester);
  });

  testWidgets('configured desktop submit shortcut sends note input content', (
    tester,
  ) async {
    await _withDefaultTargetPlatform(TargetPlatform.windows, () async {
      final controller = _RecordingNoteInputController();
      await tester.pumpWidget(
        _buildHarness(
          noteInputController: controller,
          devicePreferences: _devicePreferencesWithPublishBinding(
            DesktopShortcutBinding(
              keyId: LogicalKeyboardKey.keyS.keyId,
              primary: true,
              shift: true,
              alt: false,
            ),
          ),
          child: const NoteInputSheet(
            initialText: 'Shortcut note input',
            ignoreDraft: true,
            autoFocus: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await tester.pumpAndSettle();

      expect(controller.createdContents, ['Shortcut note input']);

      await _disposeHarness(tester);
    });
  });

  testWidgets('plain desktop Enter does not submit note input content', (
    tester,
  ) async {
    await _withDefaultTargetPlatform(TargetPlatform.windows, () async {
      final controller = _RecordingNoteInputController();
      await tester.pumpWidget(
        _buildHarness(
          noteInputController: controller,
          child: const NoteInputSheet(
            initialText: 'Plain enter note input',
            ignoreDraft: true,
            autoFocus: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(TextField).first);
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();

      expect(controller.createdContents, isEmpty);
      expect(find.byType(NoteInputSheet), findsOneWidget);

      await _disposeHarness(tester);
    });
  });

  testWidgets('fullscreen close uses draft-aware close path', (tester) async {
    final draftRepository = _FakeComposeDraftRepository();
    await tester.pumpWidget(
      _buildHarness(
        draftRepository: draftRepository,
        child: const NoteInputSheet(
          initialText: 'Unsaved fullscreen draft',
          autoFocus: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(_expandButton);
    await tester.pumpAndSettle();
    await tester.tap(_closeButton);
    await tester.pumpAndSettle();

    expect(
      draftRepository.savedSnapshots.map((snapshot) => snapshot.content),
      contains('Unsaved fullscreen draft'),
    );

    await _disposeHarness(tester);
  });

  testWidgets(
    'initialDraftUid restores draft content and metadata for submit',
    (tester) async {
      final controller = _RecordingNoteInputController();
      final attachmentPath = '/tmp/restored-inline.png';
      final localUrl = shareInlineLocalUrlFromPath(attachmentPath);
      final draftRepository = _FakeComposeDraftRepository(
        records: [
          ComposeDraftRecord(
            uid: 'draft-restore',
            workspaceKey: 'test-workspace',
            snapshot: ComposeDraftSnapshot(
              content: 'Restored body ![]($localUrl)',
              visibility: 'PUBLIC',
              relations: const [
                {
                  'relatedMemo': {'name': 'memos/linked-1'},
                  'type': 'REFERENCE',
                },
              ],
              attachments: [
                ComposeDraftAttachment(
                  uid: 'att-1',
                  filePath: attachmentPath,
                  filename: 'restored-inline.png',
                  mimeType: 'image/png',
                  size: 12,
                  shareInlineImage: true,
                  fromThirdPartyShare: true,
                  sourceUrl: 'https://example.com/restored.png',
                ),
              ],
              location: const MemoLocation(
                placeholder: 'Desk',
                latitude: 12.3,
                longitude: 45.6,
              ),
            ),
            createdTime: DateTime.utc(2025, 1, 1),
            updatedTime: DateTime.utc(2025, 1, 2),
          ),
        ],
      );
      await tester.pumpWidget(
        _buildHarness(
          noteInputController: controller,
          draftRepository: draftRepository,
          child: const NoteInputSheet(
            initialDraftUid: 'draft-restore',
            autoFocus: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Restored body'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pumpAndSettle();

      expect(controller.createdContents, ['Restored body ![]($localUrl)']);
      expect(controller.createdVisibilities, ['PUBLIC']);
      expect(controller.createdLocations.single?.placeholder, 'Desk');
      expect(controller.createdRelations.single, hasLength(1));
      expect(controller.createdPendingAttachments.single, hasLength(1));
      expect(
        controller.createdPendingAttachments.single.single.sourceUrl,
        'https://example.com/restored.png',
      );
      expect(draftRepository.deletedDraftIds, ['draft-restore']);

      await _disposeHarness(tester);
    },
  );

  testWidgets('missing initialDraftUid keeps note input usable', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildHarness(
        draftRepository: _FakeComposeDraftRepository(),
        child: const NoteInputSheet(
          initialDraftUid: 'missing-draft',
          autoFocus: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NoteInputSheet), findsOneWidget);
    expect(find.text('missing-draft'), findsNothing);

    await _disposeHarness(tester);
  });
}

Finder get _expandButton =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-expand-button'));
Finder get _collapseButton =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-collapse-button'));
Finder get _closeButton =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-close-button'));
Finder get _fullscreenTopToolbar =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-top-toolbar-row'));
Finder get _fullscreenBottomToolbar => find.byKey(
  const ValueKey<String>('note-input-fullscreen-bottom-toolbar-row'),
);
Finder get _fullscreenSendButton =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-send-button'));
Finder get _fullscreenTextField =>
    find.byKey(const ValueKey<String>('note-input-fullscreen-text-field'));
Finder get _fullscreenVisibilityButton => find.byIcon(Icons.lock).first;

Future<void> _disposeHarness(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

Future<void> _withDefaultTargetPlatform(
  TargetPlatform platform,
  Future<void> Function() body,
) async {
  debugDefaultTargetPlatformOverride = platform;
  try {
    await body();
  } finally {
    debugDefaultTargetPlatformOverride = null;
  }
}

Widget _buildHarness({
  required Widget child,
  _RecordingNoteInputController? noteInputController,
  _FakeComposeDraftRepository? draftRepository,
  DevicePreferences? devicePreferences,
  MediaQueryData mediaQueryData = const MediaQueryData(size: Size(390, 780)),
}) {
  final drafts = draftRepository ?? _FakeComposeDraftRepository();
  return ProviderScope(
    overrides: [
      composeDraftRepositoryProvider.overrideWith((ref) => drafts),
      currentWorkspacePreferencesProvider.overrideWith(
        (ref) => _TestWorkspacePreferencesController(ref),
      ),
      workspacePreferencesLoadedProvider.overrideWith((ref) => true),
      memoTemplateSettingsProvider.overrideWith(
        (ref) => _TestMemoTemplateSettingsController(ref),
      ),
      devicePreferencesProvider.overrideWith(
        (ref) => _TestDevicePreferencesController(
          ref,
          devicePreferences ??
              DevicePreferences.defaultsForLanguage(AppLanguage.en),
        ),
      ),
      tagStatsProvider.overrideWith((ref) => Stream.value(const <TagStat>[])),
      tagColorLookupProvider.overrideWith(
        (ref) => TagColorLookup(const <TagStat>[]),
      ),
      userGeneralSettingProvider.overrideWith(
        (ref) async => const UserGeneralSetting(),
      ),
      syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
      noteInputControllerProvider.overrideWith(
        (ref) => noteInputController ?? _RecordingNoteInputController(),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Scaffold(
          body: MediaQuery(
            data: mediaQueryData,
            child: SizedBox(width: 390, height: 780, child: child),
          ),
        ),
      ),
    ),
  );
}

class _RecordingNoteInputController implements NoteInputController {
  final createdContents = <String>[];
  final createdVisibilities = <String>[];
  final createdLocations = <MemoLocation?>[];
  final createdRelations = <List<Map<String, dynamic>>>[];
  final createdPendingAttachments = <List<NoteInputPendingAttachment>>[];

  @override
  Future<void> createMemo({
    required String uid,
    required String content,
    String? syncContent,
    required String visibility,
    required DateTime now,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required bool hasAttachments,
    required List<Map<String, dynamic>> relations,
    required List<NoteInputPendingAttachment> pendingAttachments,
    ShareClipMetadataDraft? clipMetadataDraft,
  }) async {
    createdContents.add(content);
    createdVisibilities.add(visibility);
    createdLocations.add(location);
    createdRelations.add(relations);
    createdPendingAttachments.add(pendingAttachments);
  }

  @override
  Future<void> appendDeferredThirdPartyShareInlineImage({
    required String memoUid,
    required String sourceUrl,
    required NoteInputPendingAttachment attachment,
  }) async {}
}

DevicePreferences _devicePreferencesWithPublishBinding(
  DesktopShortcutBinding binding,
) {
  final bindings = Map<DesktopShortcutAction, DesktopShortcutBinding>.from(
    desktopShortcutDefaultBindings,
  );
  bindings[DesktopShortcutAction.publishMemo] = binding;
  return DevicePreferences.defaultsForLanguage(
    AppLanguage.en,
  ).copyWith(desktopShortcutBindings: bindings);
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository(this._stored)
    : super(PreferencesMigrationService(const FlutterSecureStorage()));

  DevicePreferences _stored;

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<DevicePreferences> read() async => _stored;

  @override
  Future<void> write(DevicePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref, DevicePreferences initial)
    : super(ref, _TestDevicePreferencesRepository(initial)) {
    state = initial;
  }
}

class _FakeComposeDraftRepository implements ComposeDraftRepository {
  _FakeComposeDraftRepository({List<ComposeDraftRecord> records = const []})
    : _records = {for (final record in records) record.uid: record};

  final _changes = StreamController<void>.broadcast();
  final savedSnapshots = <ComposeDraftSnapshot>[];
  final deletedDraftIds = <String>[];
  final Map<String, ComposeDraftRecord> _records;

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String get workspaceKey => 'test-workspace';

  @override
  Future<void> clearDrafts() async {}

  @override
  Future<void> deleteDraft(
    String uid, {
    Set<String> keepPaths = const <String>{},
  }) async {
    deletedDraftIds.add(uid);
    _records.remove(uid);
  }

  @override
  Future<ComposeDraftRecord?> getByUid(String uid) async =>
      getByUidWithoutLegacyImport(uid);

  @override
  Future<ComposeDraftRecord?> getByUidWithoutLegacyImport(String uid) async =>
      _records[uid.trim()];

  @override
  Future<ComposeDraftRecord?> getEditDraftForMemo(String targetMemoUid) async {
    final normalized = targetMemoUid.trim();
    for (final draft in _records.values) {
      if (draft.isEditMemoDraft && draft.targetMemoUid == normalized) {
        return draft;
      }
    }
    return null;
  }

  @override
  Future<ComposeDraftRecord?> latestDraft() async =>
      _records.isEmpty ? null : _records.values.first;

  @override
  Future<ComposeDraftRecord?> latestCreateDraft() async {
    for (final draft in _records.values) {
      if (draft.isCreateMemoDraft) return draft;
    }
    return null;
  }

  @override
  Future<List<ComposeDraftRecord>> listDrafts({int? limit}) async =>
      limit == null
      ? _records.values.toList(growable: false)
      : _records.values.take(limit).toList(growable: false);

  @override
  Future<void> replaceAllDrafts(Iterable<ComposeDraftRecord> drafts) async {}

  @override
  Future<void> deleteEditDraftForMemo(String targetMemoUid) async {
    final normalized = targetMemoUid.trim();
    _records.removeWhere(
      (_, draft) => draft.isEditMemoDraft && draft.targetMemoUid == normalized,
    );
  }

  @override
  Future<String?> saveSnapshot({
    String? draftUid,
    required ComposeDraftSnapshot snapshot,
  }) async {
    if (snapshot.hasSavableContent) {
      savedSnapshots.add(snapshot);
    }
    final normalizedUid = draftUid?.trim();
    if (!snapshot.hasSavableContent) {
      if (normalizedUid != null && normalizedUid.isNotEmpty) {
        _records.remove(normalizedUid);
      }
      return null;
    }
    final uid = normalizedUid?.isNotEmpty == true ? normalizedUid! : 'draft-1';
    _records[uid] = ComposeDraftRecord(
      uid: uid,
      workspaceKey: workspaceKey,
      snapshot: snapshot,
      createdTime: _records[uid]?.createdTime ?? DateTime.utc(2025, 1, 1),
      updatedTime: DateTime.utc(2025, 1, 2),
    );
    return uid;
  }

  @override
  Future<String?> saveEditDraft({
    required String targetMemoUid,
    required ComposeDraftSnapshot snapshot,
    String? targetMemoContentFingerprint,
    DateTime? targetMemoUpdateTime,
  }) async {
    final normalizedTarget = targetMemoUid.trim();
    if (normalizedTarget.isEmpty || !snapshot.hasSavableContent) {
      return null;
    }
    final existing = await getEditDraftForMemo(normalizedTarget);
    final uid = existing?.uid ?? 'edit-draft-1';
    _records[uid] = ComposeDraftRecord(
      uid: uid,
      workspaceKey: workspaceKey,
      kind: ComposeDraftKind.editMemo,
      targetMemoUid: normalizedTarget,
      targetMemoContentFingerprint: targetMemoContentFingerprint,
      targetMemoUpdateTime: targetMemoUpdateTime,
      snapshot: snapshot,
      createdTime: existing?.createdTime ?? DateTime.utc(2025, 1, 1),
      updatedTime: DateTime.utc(2025, 1, 2),
    );
    return uid;
  }
}

class _TestWorkspacePreferencesRepository
    extends WorkspacePreferencesRepository {
  _TestWorkspacePreferencesRepository()
    : super(
        PreferencesMigrationService(const FlutterSecureStorage()),
        workspaceKey: 'test-workspace',
      );

  WorkspacePreferences _stored = WorkspacePreferences.defaults;

  @override
  Future<StorageReadResult<WorkspacePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<WorkspacePreferences> read() async => _stored;

  @override
  Future<void> write(WorkspacePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestWorkspacePreferencesController
    extends WorkspacePreferencesController {
  _TestWorkspacePreferencesController(Ref ref)
    : super(ref, _TestWorkspacePreferencesRepository()) {
    state = WorkspacePreferences.defaults;
  }
}

class _TestMemoTemplateSettingsController
    extends MemoTemplateSettingsController {
  _TestMemoTemplateSettingsController(Ref ref)
    : super(ref, _TestMemoTemplateSettingsRepository());
}

class _TestMemoTemplateSettingsRepository
    extends MemoTemplateSettingsRepository {
  _TestMemoTemplateSettingsRepository()
    : super(const FlutterSecureStorage(), accountKey: 'test-workspace');

  @override
  Future<MemoTemplateSettings> read() async => MemoTemplateSettings.defaults;

  @override
  Future<void> write(MemoTemplateSettings settings) async {}

  @override
  Future<void> clear() async {}
}

class _NoopSyncFacade extends DesktopSyncFacade {
  _NoopSyncFacade() : super(SyncCoordinatorState.initial);

  @override
  void applyRemoteStateSnapshot(SyncCoordinatorState next) {
    state = next;
  }

  @override
  Future<WebDavExportCleanupStatus> cleanWebDavPlainExport() async {
    return WebDavExportCleanupStatus.notFound;
  }

  @override
  Future<WebDavSyncMeta?> cleanWebDavDeprecatedPlainFiles() async {
    return null;
  }

  @override
  Future<WebDavExportStatus> fetchWebDavExportStatus() async {
    return const WebDavExportStatus(
      webDavConfigured: false,
      encSignature: null,
      plainSignature: null,
      plainDetected: false,
      plainDeprecated: false,
      plainDetectedAt: null,
      plainRemindAfter: null,
      lastExportSuccessAt: null,
      lastUploadSuccessAt: null,
    );
  }

  @override
  Future<WebDavSyncMeta?> fetchWebDavSyncMeta() async {
    return null;
  }

  @override
  Future<List<WebDavBackupSnapshotInfo>> listWebDavBackupSnapshots({
    required WebDavSettings settings,
    required String? accountKey,
    required String password,
  }) async {
    return const <WebDavBackupSnapshotInfo>[];
  }

  @override
  Future<String> recoverWebDavBackupPassword({
    required WebDavSettings settings,
    required String? accountKey,
    required String recoveryCode,
    required String newPassword,
  }) async {
    return '';
  }

  @override
  Future<SyncRunResult> requestSync(SyncRequest request) async {
    return const SyncRunStarted();
  }

  @override
  Future<SyncRunResult> requestWebDavBackup({
    required SyncRequestReason reason,
    String? password,
    WebDavBackupExportIssueHandler? onExportIssue,
  }) async {
    return const SyncRunStarted();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackup({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavPlainBackupToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshot({
    required WebDavSettings settings,
    required String? accountKey,
    required LocalLibrary? activeLocalLibrary,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    Map<String, bool>? conflictDecisions,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<WebDavRestoreResult> restoreWebDavSnapshotToDirectory({
    required WebDavSettings settings,
    required String? accountKey,
    required WebDavBackupSnapshotInfo snapshot,
    required String password,
    required LocalLibrary exportLibrary,
    required String exportPrefix,
    WebDavBackupConfigRestorePromptHandler? onConfigRestorePrompt,
  }) async {
    return const WebDavRestoreSuccess();
  }

  @override
  Future<void> resolveLocalScanConflicts(Map<String, bool> resolutions) async {}

  @override
  Future<void> resolveWebDavConflicts(Map<String, bool> resolutions) async {}

  @override
  Future<void> retryPending() async {}

  @override
  Future<WebDavConnectionTestResult> testWebDavConnection({
    required WebDavSettings settings,
  }) async {
    return const WebDavConnectionTestResult.success();
  }

  @override
  Future<SyncError?> verifyWebDavBackup({
    required String password,
    required bool deep,
  }) async {
    return null;
  }
}
