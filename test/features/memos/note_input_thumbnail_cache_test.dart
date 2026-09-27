import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/note_input_sheet.dart';

void main() {
  test('pending image preview uses single-axis cache fallback', () {
    final target = resolveNoteInputPendingImageThumbnailCacheTarget(
      tileSize: 62,
      devicePixelRatio: 1,
    );

    expect(target.width, 93);
    expect(target.height, isNull);
  });
}
