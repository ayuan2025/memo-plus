import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum DesktopHomeSecondaryPaneMode { none, preview }

enum DesktopHomeEditorSurfaceMode { hidden, centered, fullscreen }

enum DesktopHomeReaderSurfaceMode { hidden, centered, fullscreen }

@immutable
sealed class DesktopHomeComposeDraftTarget {
  const DesktopHomeComposeDraftTarget();
}

class DesktopHomeComposeNewMemo extends DesktopHomeComposeDraftTarget {
  const DesktopHomeComposeNewMemo();
}

class DesktopHomeComposeEditMemo extends DesktopHomeComposeDraftTarget {
  const DesktopHomeComposeEditMemo(this.memoUid);

  final String memoUid;
}

@immutable
class DesktopHomePaneState {
  const DesktopHomePaneState({
    required this.selectedMemoUid,
    required this.secondaryPaneMode,
    required this.composeDraftTarget,
    required this.editorSurfaceMode,
    required this.readerMemoUid,
    required this.readerSurfaceMode,
  });

  static const initial = DesktopHomePaneState(
    selectedMemoUid: null,
    secondaryPaneMode: DesktopHomeSecondaryPaneMode.none,
    composeDraftTarget: null,
    editorSurfaceMode: DesktopHomeEditorSurfaceMode.hidden,
    readerMemoUid: null,
    readerSurfaceMode: DesktopHomeReaderSurfaceMode.hidden,
  );

  final String? selectedMemoUid;
  final DesktopHomeSecondaryPaneMode secondaryPaneMode;
  final DesktopHomeComposeDraftTarget? composeDraftTarget;
  final DesktopHomeEditorSurfaceMode editorSurfaceMode;
  final String? readerMemoUid;
  final DesktopHomeReaderSurfaceMode readerSurfaceMode;

  bool get hasSelection => (selectedMemoUid ?? '').trim().isNotEmpty;
  bool get previewVisible =>
      secondaryPaneMode == DesktopHomeSecondaryPaneMode.preview;
  bool get editorVisible =>
      editorSurfaceMode != DesktopHomeEditorSurfaceMode.hidden;
  bool get isEditorFullscreen =>
      editorSurfaceMode == DesktopHomeEditorSurfaceMode.fullscreen;
  bool get readerVisible =>
      readerSurfaceMode != DesktopHomeReaderSurfaceMode.hidden;
  bool get isReaderFullscreen =>
      readerSurfaceMode == DesktopHomeReaderSurfaceMode.fullscreen;
}

class DesktopHomePaneStateController
    extends AutoDisposeNotifier<DesktopHomePaneState> {
  @override
  DesktopHomePaneState build() => DesktopHomePaneState.initial;

  void selectMemo(String memoUid) {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    state = DesktopHomePaneState(
      selectedMemoUid: trimmedUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void showPreview(String memoUid) {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    state = DesktopHomePaneState(
      selectedMemoUid: trimmedUid,
      secondaryPaneMode: DesktopHomeSecondaryPaneMode.preview,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void openPreviewPane({String? selectedMemoUid}) {
    final trimmedUid = selectedMemoUid?.trim();
    state = DesktopHomePaneState(
      selectedMemoUid: trimmedUid == null || trimmedUid.isEmpty
          ? state.selectedMemoUid
          : trimmedUid,
      secondaryPaneMode: DesktopHomeSecondaryPaneMode.preview,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void closeSecondaryPane() {
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: DesktopHomeSecondaryPaneMode.none,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void deselectMemo() {
    if (!state.hasSelection &&
        state.secondaryPaneMode == DesktopHomeSecondaryPaneMode.none) {
      return;
    }
    state = DesktopHomePaneState(
      selectedMemoUid: null,
      secondaryPaneMode: DesktopHomeSecondaryPaneMode.none,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void showComposeNew({String? selectedMemoUid}) {
    state = DesktopHomePaneState(
      selectedMemoUid: selectedMemoUid?.trim().isEmpty ?? true
          ? null
          : selectedMemoUid!.trim(),
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: const DesktopHomeComposeNewMemo(),
      editorSurfaceMode: DesktopHomeEditorSurfaceMode.centered,
      readerMemoUid: null,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.hidden,
    );
  }

  void showComposeEdit(String memoUid) {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    state = DesktopHomePaneState(
      selectedMemoUid: trimmedUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: DesktopHomeComposeEditMemo(trimmedUid),
      editorSurfaceMode: DesktopHomeEditorSurfaceMode.centered,
      readerMemoUid: null,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.hidden,
    );
  }

  void expandComposeToFullscreen() {
    if (state.composeDraftTarget == null) return;
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: DesktopHomeEditorSurfaceMode.fullscreen,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void restoreComposeToCentered() {
    if (state.composeDraftTarget == null) return;
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: DesktopHomeEditorSurfaceMode.centered,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void closeCompose() {
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: null,
      editorSurfaceMode: DesktopHomeEditorSurfaceMode.hidden,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: state.readerSurfaceMode,
    );
  }

  void showReader(String memoUid) {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty || state.editorVisible) return;
    state = DesktopHomePaneState(
      selectedMemoUid: trimmedUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: trimmedUid,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.centered,
    );
  }

  void expandReaderToFullscreen() {
    if (!state.readerVisible) return;
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.fullscreen,
    );
  }

  void restoreReaderToCentered() {
    if (!state.readerVisible) return;
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: state.readerMemoUid,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.centered,
    );
  }

  void closeReader() {
    state = DesktopHomePaneState(
      selectedMemoUid: state.selectedMemoUid,
      secondaryPaneMode: state.secondaryPaneMode,
      composeDraftTarget: state.composeDraftTarget,
      editorSurfaceMode: state.editorSurfaceMode,
      readerMemoUid: null,
      readerSurfaceMode: DesktopHomeReaderSurfaceMode.hidden,
    );
  }

  void restore(DesktopHomePaneState value) {
    state = value;
  }

  void clear() {
    state = DesktopHomePaneState.initial;
  }
}

final desktopHomePaneStateProvider =
    AutoDisposeNotifierProvider<
      DesktopHomePaneStateController,
      DesktopHomePaneState
    >(DesktopHomePaneStateController.new);
