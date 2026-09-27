import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/features/collections/collection_reader_menu_logic.dart';

void main() {
  test('toggle overlay shows and hides overlay without timer semantics', () {
    final shown = reduceCollectionReaderMenuState(
      CollectionReaderMenuState.hidden,
      CollectionReaderMenuEvent.toggleOverlay,
    );
    expect(shown.nextState, CollectionReaderMenuState.overlayVisible);
    expect(shown.cancelOverlayTimer, isTrue);
    expect(shown.restartOverlayTimer, isFalse);

    final hidden = reduceCollectionReaderMenuState(
      CollectionReaderMenuState.overlayVisible,
      CollectionReaderMenuEvent.toggleOverlay,
    );
    expect(hidden.nextState, CollectionReaderMenuState.hidden);
    expect(hidden.restartOverlayTimer, isFalse);
    expect(hidden.cancelOverlayTimer, isTrue);
  });

  test('overlay interaction keeps overlay visible without restart', () {
    final transition = reduceCollectionReaderMenuState(
      CollectionReaderMenuState.overlayVisible,
      CollectionReaderMenuEvent.overlayInteraction,
    );

    expect(transition.nextState, CollectionReaderMenuState.overlayVisible);
    expect(transition.restartOverlayTimer, isFalse);
    expect(transition.cancelOverlayTimer, isTrue);
  });

  test('opening sheets hides overlay and does not auto-restore on close', () {
    final opened = reduceCollectionReaderMenuState(
      CollectionReaderMenuState.overlayVisible,
      CollectionReaderMenuEvent.openSearchSheet,
    );
    expect(opened.nextState, CollectionReaderMenuState.searchSheetVisible);
    expect(opened.cancelOverlayTimer, isTrue);

    final closed = reduceCollectionReaderMenuState(
      opened.nextState,
      CollectionReaderMenuEvent.closeSheet,
    );
    expect(closed.nextState, CollectionReaderMenuState.hidden);
    expect(closed.restartOverlayTimer, isFalse);
  });

  test('reading actions and lifecycle events force menus hidden', () {
    for (final event in <CollectionReaderMenuEvent>[
      CollectionReaderMenuEvent.pageTurned,
      CollectionReaderMenuEvent.chapterJumped,
      CollectionReaderMenuEvent.searchResultJumped,
      CollectionReaderMenuEvent.autoPageStarted,
      CollectionReaderMenuEvent.appBackgrounded,
      CollectionReaderMenuEvent.readerExited,
      CollectionReaderMenuEvent.overlayTimeout,
    ]) {
      final transition = reduceCollectionReaderMenuState(
        CollectionReaderMenuState.overlayVisible,
        event,
      );
      expect(transition.nextState, CollectionReaderMenuState.hidden);
      expect(transition.cancelOverlayTimer, isTrue);
    }
  });
}
