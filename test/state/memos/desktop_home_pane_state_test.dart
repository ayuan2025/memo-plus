import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:memos_flutter_app/state/memos/desktop_home_pane_state.dart';

void main() {
  test(
    'showComposeNew opens centered editor without changing preview mode',
    () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final controller = container.read(desktopHomePaneStateProvider.notifier);

      controller.showComposeNew(selectedMemoUid: 'memo-1');

      final state = container.read(desktopHomePaneStateProvider);
      expect(state.selectedMemoUid, 'memo-1');
      expect(state.composeDraftTarget, isA<DesktopHomeComposeNewMemo>());
      expect(state.editorSurfaceMode, DesktopHomeEditorSurfaceMode.centered);
      expect(state.secondaryPaneMode, DesktopHomeSecondaryPaneMode.none);
    },
  );

  test('showComposeEdit keeps preview visible and selects target memo', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(desktopHomePaneStateProvider.notifier);

    controller.showPreview('memo-1');
    controller.showComposeEdit('memo-2');

    final state = container.read(desktopHomePaneStateProvider);
    expect(state.selectedMemoUid, 'memo-2');
    expect(state.composeDraftTarget, isA<DesktopHomeComposeEditMemo>());
    expect(state.previewVisible, isTrue);
    expect(state.editorVisible, isTrue);
  });

  test('editor surface toggles between centered and fullscreen', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(desktopHomePaneStateProvider.notifier);

    controller.showComposeEdit('memo-1');
    controller.expandComposeToFullscreen();
    expect(
      container.read(desktopHomePaneStateProvider).editorSurfaceMode,
      DesktopHomeEditorSurfaceMode.fullscreen,
    );

    controller.restoreComposeToCentered();
    expect(
      container.read(desktopHomePaneStateProvider).editorSurfaceMode,
      DesktopHomeEditorSurfaceMode.centered,
    );
  });

  test('closeCompose hides editor and preserves preview state', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(desktopHomePaneStateProvider.notifier);

    controller.showPreview('memo-1');
    controller.showComposeEdit('memo-1');
    controller.closeCompose();

    final state = container.read(desktopHomePaneStateProvider);
    expect(state.composeDraftTarget, isNull);
    expect(state.editorSurfaceMode, DesktopHomeEditorSurfaceMode.hidden);
    expect(state.secondaryPaneMode, DesktopHomeSecondaryPaneMode.preview);
    expect(state.previewVisible, isTrue);
  });

  test('deselectMemo clears selection and preview while preserving editor', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(desktopHomePaneStateProvider.notifier);

    controller.showPreview('memo-1');
    controller.showComposeNew(selectedMemoUid: 'memo-1');
    controller.deselectMemo();

    final state = container.read(desktopHomePaneStateProvider);
    expect(state.selectedMemoUid, isNull);
    expect(state.secondaryPaneMode, DesktopHomeSecondaryPaneMode.none);
    expect(state.composeDraftTarget, isA<DesktopHomeComposeNewMemo>());
    expect(state.editorSurfaceMode, DesktopHomeEditorSurfaceMode.centered);
  });
}
