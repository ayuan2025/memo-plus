import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/collection_reader.dart';
import 'package:memos_flutter_app/features/collections/collection_reader_page_models.dart';
import 'package:memos_flutter_app/features/collections/reader_tip_builder.dart';

void main() {
  const page = ReaderPage(
    memoUid: 'memo-1',
    memoIndex: 0,
    chapterPageIndex: 0,
    contentCharStart: 0,
    contentCharEnd: 10,
    blocks: <ReaderPageBlock>[],
    isFirstPage: true,
    isLastPage: false,
    reservedInsets: ReaderPageReservedInsets.zero,
    headerTip: ReaderTipRenderData(
      mode: CollectionReaderTipDisplayMode.reserved,
      leftSlot: CollectionReaderTipSlot.collectionTitle,
      centerSlot: CollectionReaderTipSlot.none,
      rightSlot: CollectionReaderTipSlot.pageAndTotal,
    ),
    footerTip: ReaderTipRenderData(
      mode: CollectionReaderTipDisplayMode.reserved,
      leftSlot: CollectionReaderTipSlot.chapterTitle,
      centerSlot: CollectionReaderTipSlot.totalProgress,
      rightSlot: CollectionReaderTipSlot.page,
    ),
    title: null,
  );

  test('tip builder maps configured slots into visible strings', () {
    final header = buildReaderTipStrings(
      page: page,
      tipLayout: CollectionReaderTipLayout.defaults,
      collectionTitle: 'Shelf A',
      chapterTitle: 'Chapter One',
      globalPageIndex: 4,
      totalPages: 20,
      now: DateTime(2026, 4, 12, 9, 30),
    );
    final footer = buildReaderFooterTipStrings(
      page: page,
      tipLayout: CollectionReaderTipLayout.defaults,
      collectionTitle: 'Shelf A',
      chapterTitle: 'Chapter One',
      globalPageIndex: 4,
      totalPages: 20,
      now: DateTime(2026, 4, 12, 9, 30),
    );

    expect(header.left, 'Shelf A');
    expect(header.center, '');
    expect(header.right, '5/20');
    expect(footer.left, 'Chapter One');
    expect(footer.center, '25%');
    expect(footer.right, '5');
  });
}
