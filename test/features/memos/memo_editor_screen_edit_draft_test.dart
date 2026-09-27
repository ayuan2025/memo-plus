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
import 'package:memos_flutter_app/core/desktop/shortcuts.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/compose_draft.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/local_library.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/location_settings.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/data/models/memo_relation.dart';
import 'package:memos_flutter_app/data/models/memo_template_settings.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/webdav_backup.dart';
import 'package:memos_flutter_app/data/models/webdav_export_status.dart';
import 'package:memos_flutter_app/data/models/webdav_settings.dart';
import 'package:memos_flutter_app/data/models/webdav_sync_meta.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/data/repositories/location_settings_repository.dart';
import 'package:memos_flutter_app/data/repositories/memo_template_settings_repository.dart';
import 'package:memos_flutter_app/data/repositories/scene_micro_guide_repository.dart';
import 'package:memos_flutter_app/features/memos/memo_editor_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/compose_draft_provider.dart';
import 'package:memos_flutter_app/state/memos/memo_editor_controller.dart';
import 'package:memos_flutter_app/state/memos/memo_editor_draft_provider.dart';
import 'package:memos_flutter_app/state/memos/memo_editor_providers.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';
import 'package:memos_flutter_app/state/memos/note_draft_provider.dart';
import 'package:memos_flutter_app/state/settings/location_settings_provider.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/memo_template_settings_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/system/scene_micro_guide_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';
import 'package:memos_flutter_app/state/tags/tag_color_lookup.dart';

void main() {
  setUp(() => LocaleSettings.setLocale(AppLocale.en));

  testWidgets('closing unchanged existing memo does not prompt or save draft', (
    tester,
  ) async {
    final context = await _pumpEditor(tester);

    await _requestEditorPop(tester);

    expect(find.byType(MemoEditorScreen), findsNothing);
    expect(context.composeDrafts.savedEditDrafts, isEmpty);
    expect(context.editorController.savedContents, isEmpty);
  });

  testWidgets('continue editing keeps unsaved existing memo open', (
    tester,
  ) async {
    final context = await _pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Changed memo');
    await _requestEditorPop(tester);

    expect(find.text('Save edit draft?'), findsOneWidget);
    await tester.tap(find.text('Continue editing'));
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsOneWidget);
    expect(context.composeDrafts.savedEditDrafts, isEmpty);
    expect(context.editorController.savedContents, isEmpty);
  });

  testWidgets('discard closes restored edit draft and removes visible draft', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      initialEditDraft: _buildEditDraft(content: 'Restored draft'),
    );

    await tester.enterText(find.byType(TextField).first, 'Discard this edit');
    await _requestEditorPop(tester);

    await tester.tap(find.text('Discard changes'));
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsNothing);
    expect(context.composeDrafts.deletedDraftUids, contains('edit-draft'));
    expect(context.editorController.savedContents, isEmpty);
  });

  testWidgets('add to Draft Box saves visible edit draft without saving memo', (
    tester,
  ) async {
    final context = await _pumpEditor(tester);

    await tester.enterText(find.byType(TextField).first, 'Save for later');
    await _requestEditorPop(tester);

    await tester.tap(find.text('Add to Draft Box'));
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsNothing);
    expect(context.composeDrafts.savedEditDrafts, hasLength(1));
    expect(
      context.composeDrafts.savedEditDrafts.single.snapshot.content,
      'Save for later',
    );
    expect(context.hiddenDrafts.clearedMemoUids, contains('memo-1'));
    expect(context.editorController.savedContents, isEmpty);
  });

  testWidgets('saving restored edit draft updates memo and deletes draft', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      initialEditDraft: _buildEditDraft(content: 'Restored draft body'),
    );

    await tester.tap(find.byTooltip('Save'));
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsNothing);
    expect(context.editorController.savedContents, ['Restored draft body']);
    expect(context.editorController.savedExistingUids, ['memo-1']);
    expect(context.composeDrafts.deletedDraftUids, contains('edit-draft'));
    expect(context.composeDrafts.savedEditDrafts, isEmpty);
  });

  testWidgets('page editor shows fullscreen action instead of top save', (
    tester,
  ) async {
    await _pumpEditor(tester, presentation: MemoEditorPresentation.page);

    expect(_pageFullscreenButton, findsOneWidget);
    expect(find.byTooltip('Maximize'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('memo-editor-bottom-save-button')),
      findsOneWidget,
    );
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('page editor fullscreen preserves text and collapses cleanly', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.page,
    );

    await tester.enterText(find.byType(TextField).first, 'Fullscreen edit');
    await tester.tap(_pageFullscreenButton);
    await _pumpRouteFrames(tester);

    expect(_fullscreenTextField, findsOneWidget);
    expect(find.text('Fullscreen edit'), findsOneWidget);

    await tester.tap(_fullscreenCollapseButton);
    await _pumpRouteFrames(tester);

    expect(_fullscreenTextField, findsNothing);
    expect(_pageFullscreenButton, findsOneWidget);
    expect(find.text('Save edit draft?'), findsNothing);
    expect(context.editorController.savedContents, isEmpty);
  });

  testWidgets('fullscreen editor close uses unsaved edit confirmation', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.page,
    );

    await tester.enterText(find.byType(TextField).first, 'Needs decision');
    await tester.tap(_pageFullscreenButton);
    await _pumpRouteFrames(tester);
    await tester.tap(_fullscreenCloseButton);
    await _pumpRouteFrames(tester);

    expect(find.text('Save edit draft?'), findsOneWidget);
    await tester.tap(find.text('Continue editing'));
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsOneWidget);
    expect(context.editorController.savedContents, isEmpty);
    expect(context.composeDrafts.savedEditDrafts, isEmpty);
  });

  testWidgets('fullscreen editor save uses existing save path once', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.page,
    );

    await tester.enterText(
      find.byType(TextField).first,
      'Save from fullscreen',
    );
    await tester.tap(_pageFullscreenButton);
    await _pumpRouteFrames(tester);
    await tester.tap(_fullscreenSaveButton);
    await _pumpRouteFrames(tester);

    expect(context.editorController.savedContents, ['Save from fullscreen']);
    expect(context.editorController.savedExistingUids, ['memo-1']);
  });

  testWidgets('new memo page also supports fullscreen save', (tester) async {
    final context = await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.page,
      useExisting: false,
      initialText: 'New memo body',
    );

    expect(_pageFullscreenButton, findsOneWidget);
    await tester.tap(_pageFullscreenButton);
    await _pumpRouteFrames(tester);
    await tester.tap(_fullscreenSaveButton);
    await _pumpRouteFrames(tester);

    expect(context.editorController.savedContents, ['New memo body']);
    expect(context.editorController.savedExistingUids, [null]);
  });

  testWidgets('desktop editor restores create draft and deletes it on save', (
    tester,
  ) async {
    final context = await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.desktopModal,
      useExisting: false,
      initialCreateDraft: _buildCreateDraft(content: 'Restored create draft'),
    );

    expect(find.text('Restored create draft'), findsOneWidget);

    await tester.tap(find.byTooltip('Save'));
    await _pumpRouteFrames(tester);

    expect(context.editorController.savedContents, ['Restored create draft']);
    expect(context.editorController.savedExistingUids, [null]);
    expect(context.composeDrafts.deletedDraftUids, contains('create-draft'));
  });

  testWidgets('desktop and embedded chrome do not duplicate save action', (
    tester,
  ) async {
    await _pumpEditor(tester);

    expect(
      find.byKey(const ValueKey<String>('memo-editor-bottom-save-button')),
      findsOneWidget,
    );
    expect(find.byTooltip('Save'), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);

    await _disposeHarness(tester);
    await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.desktopModal,
    );

    expect(
      find.byKey(const ValueKey<String>('memo-editor-desktop-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memo-editor-fullscreen-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memo-editor-close-button')),
      findsOneWidget,
    );
    expect(find.byTooltip('Save'), findsOneWidget);

    await _disposeHarness(tester);
    await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.desktopFullscreen,
    );

    expect(
      find.byKey(const ValueKey<String>('memo-editor-desktop-header')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('memo-editor-fullscreen-toggle')),
      findsOneWidget,
    );
    expect(find.byTooltip('Restore'), findsOneWidget);
    expect(find.byTooltip('Save'), findsOneWidget);
  });

  testWidgets('desktop modal escape closes through desktop chrome path', (
    tester,
  ) async {
    await _pumpEditor(
      tester,
      presentation: MemoEditorPresentation.desktopModal,
      useExisting: false,
      initialText: '',
    );

    expect(
      find.byKey(const ValueKey<String>('memo-editor-desktop-header')),
      findsOneWidget,
    );
    expect(_pageFullscreenButton, findsNothing);

    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _pumpRouteFrames(tester);

    expect(find.byType(MemoEditorScreen), findsNothing);
  });

  testWidgets(
    'desktop editor Enter does not save but default submit saves once',
    (tester) async {
      await _withDefaultTargetPlatform(TargetPlatform.windows, () async {
        final context = await _pumpEditor(
          tester,
          presentation: MemoEditorPresentation.desktopModal,
        );

        final editor = find.byType(EditableText);
        await tester.tap(editor);
        await tester.enterText(editor, 'Editing body');
        await tester.pump();

        final editableText = tester.widget<EditableText>(editor);
        expect(editableText.focusNode.hasFocus, isTrue);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await _pumpRouteFrames(tester);
        expect(context.editorController.savedContents, isEmpty);
        expect(
          tester.widget<EditableText>(editor).controller.text,
          'Editing body\r\n',
        );
        expect(find.byType(MemoEditorScreen), findsOneWidget);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
        await _pumpRouteFrames(tester);

        expect(context.editorController.savedContents, ['Editing body']);
        expect(context.editorController.savedExistingUids, ['memo-1']);
        expect(find.byType(MemoEditorScreen), findsNothing);
      });
    },
  );

  testWidgets('desktop editor uses custom publish memo binding', (
    tester,
  ) async {
    await _withDefaultTargetPlatform(TargetPlatform.windows, () async {
      final context = await _pumpEditor(
        tester,
        presentation: MemoEditorPresentation.desktopModal,
        devicePreferences: _devicePreferencesWithPublishBinding(
          DesktopShortcutBinding(
            keyId: LogicalKeyboardKey.keyS.keyId,
            primary: true,
            shift: true,
            alt: false,
          ),
        ),
      );

      final editor = find.byType(EditableText);
      await tester.tap(editor);
      await tester.enterText(editor, 'Custom submit binding');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _pumpRouteFrames(tester);
      expect(context.editorController.savedContents, isEmpty);
      expect(find.byType(MemoEditorScreen), findsOneWidget);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
      await _pumpRouteFrames(tester);

      expect(context.editorController.savedContents, ['Custom submit binding']);
      expect(context.editorController.savedExistingUids, ['memo-1']);
      expect(find.byType(MemoEditorScreen), findsNothing);
    });
  });

  testWidgets('desktop editor macOS default submit uses Cmd Return', (
    tester,
  ) async {
    await _withDefaultTargetPlatform(TargetPlatform.macOS, () async {
      final context = await _pumpEditor(
        tester,
        presentation: MemoEditorPresentation.desktopModal,
      );

      final editor = find.byType(EditableText);
      await tester.tap(editor);
      await tester.enterText(editor, 'macOS submit binding');
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      await _pumpRouteFrames(tester);

      expect(context.editorController.savedContents, ['macOS submit binding']);
      expect(context.editorController.savedExistingUids, ['memo-1']);
      expect(find.byType(MemoEditorScreen), findsNothing);
    });
  });
}

Finder get _pageFullscreenButton =>
    find.byKey(const ValueKey<String>('memo-editor-page-fullscreen-button'));
Finder get _fullscreenCollapseButton => find.byKey(
  const ValueKey<String>('memo-editor-fullscreen-collapse-button'),
);
Finder get _fullscreenCloseButton =>
    find.byKey(const ValueKey<String>('memo-editor-fullscreen-close-button'));
Finder get _fullscreenSaveButton =>
    find.byKey(const ValueKey<String>('memo-editor-fullscreen-save-button'));
Finder get _fullscreenTextField =>
    find.byKey(const ValueKey<String>('memo-editor-fullscreen-text-field'));

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

Future<_EditorTestContext> _pumpEditor(
  WidgetTester tester, {
  ComposeDraftRecord? initialEditDraft,
  ComposeDraftRecord? initialCreateDraft,
  MemoEditorPresentation presentation = MemoEditorPresentation.embeddedPane,
  LocalMemo? existing,
  bool useExisting = true,
  String? initialText,
  DevicePreferences? devicePreferences,
}) async {
  final testContext = _EditorTestContext();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        composeDraftRepositoryProvider.overrideWith(
          (ref) => testContext.composeDrafts,
        ),
        memoEditorDraftRepositoryProvider.overrideWith(
          (ref) => testContext.hiddenDrafts,
        ),
        memoEditorControllerProvider.overrideWith(
          (ref) => testContext.editorController,
        ),
        noteDraftRepositoryProvider.overrideWith(
          (ref) => _FakeNoteDraftRepository(),
        ),
        currentWorkspacePreferencesProvider.overrideWith(
          (ref) => _TestWorkspacePreferencesController(ref),
        ),
        workspacePreferencesLoadedProvider.overrideWith((ref) => true),
        tagStatsProvider.overrideWith((ref) => Stream.value(const <TagStat>[])),
        tagColorLookupProvider.overrideWith(
          (ref) => TagColorLookup(const <TagStat>[]),
        ),
        appSessionProvider.overrideWith((ref) => _TestSessionController()),
        devicePreferencesProvider.overrideWith(
          (ref) => _TestDevicePreferencesController(
            ref,
            devicePreferences ??
                DevicePreferences.defaultsForLanguage(AppLanguage.en),
          ),
        ),
        syncCoordinatorProvider.overrideWith((ref) => _NoopSyncFacade()),
        memoTemplateSettingsProvider.overrideWith(
          (ref) => MemoTemplateSettingsController(
            ref,
            _TestMemoTemplateSettingsRepository(),
          ),
        ),
        locationSettingsProvider.overrideWith(
          (ref) => LocationSettingsController(
            ref,
            _TestLocationSettingsRepository(),
          ),
        ),
        sceneMicroGuideProvider.overrideWith(
          (ref) => SceneMicroGuideController(_TestSceneMicroGuideRepository()),
        ),
      ],
      child: TranslationProvider(
        child: MaterialApp(
          locale: AppLocale.en.flutterLocale,
          supportedLocales: AppLocaleUtils.supportedLocales,
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: MediaQuery(
            data: const MediaQueryData(size: Size(430, 900)),
            child: _EditorHost(
              initialEditDraft: initialEditDraft,
              initialCreateDraft: initialCreateDraft,
              presentation: presentation,
              existing: useExisting ? (existing ?? _buildLocalMemo()) : null,
              initialText: initialText,
            ),
          ),
        ),
      ),
    ),
  );
  await _pumpRouteFrames(tester);
  expect(find.byType(MemoEditorScreen), findsOneWidget);
  return testContext;
}

Future<void> _requestEditorPop(WidgetTester tester) async {
  await tester.tap(find.byIcon(Icons.close_rounded).first);
  await _pumpRouteFrames(tester);
}

Future<void> _pumpRouteFrames(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  await tester.pump();
}

Future<void> _disposeHarness(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 1));
}

class _EditorHost extends StatefulWidget {
  const _EditorHost({
    this.initialEditDraft,
    this.initialCreateDraft,
    required this.presentation,
    required this.existing,
    this.initialText,
  });

  final ComposeDraftRecord? initialEditDraft;
  final ComposeDraftRecord? initialCreateDraft;
  final MemoEditorPresentation presentation;
  final LocalMemo? existing;
  final String? initialText;

  @override
  State<_EditorHost> createState() => _EditorHostState();
}

class _EditorHostState extends State<_EditorHost> {
  var _open = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _open
          ? MemoEditorScreen(
              existing: widget.existing,
              initialText: widget.initialText,
              initialEditDraft: widget.initialEditDraft,
              initialCreateDraft: widget.initialCreateDraft,
              autoFocus: false,
              presentation: widget.presentation,
              onCloseRequested: () => setState(() => _open = false),
            )
          : const SizedBox.shrink(),
    );
  }
}

class _EditorTestContext {
  final composeDrafts = _FakeComposeDraftRepository();
  final hiddenDrafts = _FakeMemoEditorDraftRepository();
  final editorController = _FakeMemoEditorController();
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
  final _changes = StreamController<void>.broadcast();
  final savedEditDrafts = <ComposeDraftRecord>[];
  final deletedDraftUids = <String>[];
  final deletedTargetMemoUids = <String>[];

  @override
  Stream<void> get changes => _changes.stream;

  @override
  String get workspaceKey => 'workspace-1';

  @override
  Future<void> clearDrafts() async {}

  @override
  Future<void> deleteDraft(
    String uid, {
    Set<String> keepPaths = const <String>{},
  }) async {
    deletedDraftUids.add(uid);
    savedEditDrafts.removeWhere((draft) => draft.uid == uid);
    _notifyChanged();
  }

  @override
  Future<void> deleteEditDraftForMemo(String targetMemoUid) async {
    deletedTargetMemoUids.add(targetMemoUid);
    savedEditDrafts.removeWhere(
      (draft) => draft.targetMemoUid == targetMemoUid,
    );
    _notifyChanged();
  }

  @override
  Future<ComposeDraftRecord?> getByUid(String uid) async {
    return getByUidWithoutLegacyImport(uid);
  }

  @override
  Future<ComposeDraftRecord?> getByUidWithoutLegacyImport(String uid) async {
    for (final draft in savedEditDrafts) {
      if (draft.uid == uid) return draft;
    }
    return null;
  }

  @override
  Future<ComposeDraftRecord?> getEditDraftForMemo(String targetMemoUid) async {
    for (final draft in savedEditDrafts) {
      if (draft.targetMemoUid == targetMemoUid) return draft;
    }
    return null;
  }

  @override
  Future<ComposeDraftRecord?> latestCreateDraft() async {
    return null;
  }

  @override
  Future<ComposeDraftRecord?> latestDraft() async {
    return savedEditDrafts.isEmpty ? null : savedEditDrafts.first;
  }

  @override
  Future<List<ComposeDraftRecord>> listDrafts({int? limit}) async {
    return limit == null
        ? List<ComposeDraftRecord>.of(savedEditDrafts)
        : savedEditDrafts.take(limit).toList(growable: false);
  }

  @override
  Future<void> replaceAllDrafts(Iterable<ComposeDraftRecord> drafts) async {
    savedEditDrafts
      ..clear()
      ..addAll(drafts);
    _notifyChanged();
  }

  @override
  Future<String?> saveEditDraft({
    required String targetMemoUid,
    required ComposeDraftSnapshot snapshot,
    String? targetMemoContentFingerprint,
    DateTime? targetMemoUpdateTime,
  }) async {
    final record = ComposeDraftRecord(
      uid: 'saved-edit-draft',
      workspaceKey: workspaceKey,
      kind: ComposeDraftKind.editMemo,
      targetMemoUid: targetMemoUid,
      targetMemoContentFingerprint: targetMemoContentFingerprint,
      targetMemoUpdateTime: targetMemoUpdateTime,
      snapshot: snapshot,
      createdTime: DateTime.utc(2025, 1, 2, 3),
      updatedTime: DateTime.utc(2025, 1, 2, 4),
    );
    savedEditDrafts
      ..removeWhere((draft) => draft.targetMemoUid == targetMemoUid)
      ..add(record);
    _notifyChanged();
    return record.uid;
  }

  @override
  Future<String?> saveSnapshot({
    String? draftUid,
    required ComposeDraftSnapshot snapshot,
  }) async {
    return null;
  }

  void _notifyChanged() {
    if (!_changes.isClosed) {
      _changes.add(null);
    }
  }
}

class _FakeMemoEditorDraftRepository extends MemoEditorDraftRepository {
  _FakeMemoEditorDraftRepository()
    : super(const FlutterSecureStorage(), accountKey: 'workspace-1');

  final clearedMemoUids = <String>[];
  final _stored = <String, String>{};

  @override
  Future<void> clear({required String memoUid}) async {
    clearedMemoUids.add(memoUid);
    _stored.remove(memoUid);
  }

  @override
  Future<String> read({required String memoUid}) async {
    return _stored[memoUid] ?? '';
  }

  @override
  Future<void> write({required String memoUid, required String text}) async {
    _stored[memoUid] = text;
  }
}

class _FakeMemoEditorController implements MemoEditorController {
  final savedContents = <String>[];
  final savedExistingUids = <String?>[];

  @override
  Future<List<MemoRelation>> listMemoRelationsAll({
    required String memoUid,
  }) async {
    return const <MemoRelation>[];
  }

  @override
  Future<void> saveMemo({
    required LocalMemo? existing,
    required String uid,
    required String content,
    required String visibility,
    required bool pinned,
    required String state,
    required DateTime createTime,
    required DateTime now,
    required List<String> tags,
    required List<Map<String, dynamic>> attachments,
    required MemoLocation? location,
    required bool locationChanged,
    required int relationCount,
    required bool hasPrimaryChanges,
    required List<Attachment> attachmentsToDelete,
    required bool includeRelations,
    required List<Map<String, dynamic>> relations,
    required bool shouldSyncAttachments,
    required bool hasPendingAttachments,
    required List<MemoEditorPendingAttachment> pendingAttachments,
  }) async {
    savedContents.add(content);
    savedExistingUids.add(existing?.uid);
  }
}

class _FakeNoteDraftRepository extends NoteDraftRepository {
  _FakeNoteDraftRepository()
    : super(const FlutterSecureStorage(), accountKey: 'workspace-1');

  @override
  Future<void> clear() async {}

  @override
  Future<String> read() async => '';

  @override
  Future<void> write(String text) async {}
}

class _TestMemoTemplateSettingsRepository
    extends MemoTemplateSettingsRepository {
  _TestMemoTemplateSettingsRepository()
    : super(const FlutterSecureStorage(), accountKey: 'workspace-1');

  @override
  Future<MemoTemplateSettings> read() async => MemoTemplateSettings.defaults;

  @override
  Future<void> write(MemoTemplateSettings settings) async {}
}

class _TestLocationSettingsRepository extends LocationSettingsRepository {
  _TestLocationSettingsRepository()
    : super(const FlutterSecureStorage(), accountKey: 'workspace-1');

  @override
  Future<LocationSettings> read() async => LocationSettings.defaults;

  @override
  Future<void> write(LocationSettings settings) async {}
}

class _TestSceneMicroGuideRepository extends SceneMicroGuideRepository {
  _TestSceneMicroGuideRepository() : super(const FlutterSecureStorage());

  final _seen = <SceneMicroGuideId>{};

  @override
  Future<Set<SceneMicroGuideId>> read() async => Set.of(_seen);

  @override
  Future<void> write(Set<SceneMicroGuideId> ids) async {
    _seen
      ..clear()
      ..addAll(ids);
  }
}

class _TestWorkspacePreferencesRepository
    extends WorkspacePreferencesRepository {
  _TestWorkspacePreferencesRepository()
    : super(
        PreferencesMigrationService(const FlutterSecureStorage()),
        workspaceKey: 'workspace-1',
      );

  @override
  Future<WorkspacePreferences> read() async => WorkspacePreferences.defaults;

  @override
  Future<StorageReadResult<WorkspacePreferences>> readWithStatus() async {
    return StorageReadResult.success(WorkspacePreferences.defaults);
  }

  @override
  Future<void> write(WorkspacePreferences prefs) async {}
}

class _TestWorkspacePreferencesController
    extends WorkspacePreferencesController {
  _TestWorkspacePreferencesController(Ref ref)
    : super(ref, _TestWorkspacePreferencesRepository()) {
    state = WorkspacePreferences.defaults;
  }
}

class _TestSessionController extends AppSessionController {
  _TestSessionController()
    : super(
        AsyncValue.data(
          AppSessionState(
            accounts: [_testAccount],
            currentKey: _testAccountKey,
          ),
        ),
      );

  @override
  Future<void> addAccountWithPassword({
    required Uri baseUrl,
    required String username,
    required String password,
    required bool useLegacyApi,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> addAccountWithPat({
    required Uri baseUrl,
    required String personalAccessToken,
    bool? useLegacyApiOverride,
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
  bool resolveUseLegacyApiForAccount({
    required Account account,
    required bool globalDefault,
  }) {
    return globalDefault;
  }

  @override
  InstanceProfile resolveEffectiveInstanceProfileForAccount({
    required Account account,
  }) {
    return account.instanceProfile;
  }

  @override
  String resolveEffectiveServerVersionForAccount({required Account account}) {
    return account.serverVersionOverride ?? account.instanceProfile.version;
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

ComposeDraftRecord _buildEditDraft({required String content}) {
  final now = DateTime.utc(2025, 1, 2, 3, 4, 5);
  return ComposeDraftRecord(
    uid: 'edit-draft',
    workspaceKey: 'workspace-1',
    kind: ComposeDraftKind.editMemo,
    targetMemoUid: 'memo-1',
    snapshot: ComposeDraftSnapshot(content: content, visibility: 'PRIVATE'),
    createdTime: now.subtract(const Duration(minutes: 1)),
    updatedTime: now,
  );
}

ComposeDraftRecord _buildCreateDraft({required String content}) {
  final now = DateTime.utc(2025, 1, 2, 3, 4, 5);
  return ComposeDraftRecord(
    uid: 'create-draft',
    workspaceKey: 'workspace-1',
    kind: ComposeDraftKind.createMemo,
    snapshot: ComposeDraftSnapshot(content: content, visibility: 'PRIVATE'),
    createdTime: now.subtract(const Duration(minutes: 1)),
    updatedTime: now,
  );
}

LocalMemo _buildLocalMemo() {
  final now = DateTime.utc(2025, 1, 2, 3, 4, 5);
  return LocalMemo(
    uid: 'memo-1',
    content: 'Original memo',
    contentFingerprint: 'fingerprint-memo-1',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: now,
    updateTime: now,
    tags: const <String>[],
    attachments: const <Attachment>[],
    relationCount: 0,
    location: null,
    syncState: SyncState.synced,
    lastError: null,
  );
}

const _testAccountKey = 'workspace-1';
final _testAccount = Account(
  key: _testAccountKey,
  baseUrl: Uri.parse('https://example.com'),
  personalAccessToken: 'token',
  user: User.empty(),
  instanceProfile: InstanceProfile.empty(),
);
