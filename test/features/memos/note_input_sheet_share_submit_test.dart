import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/note_input_sheet.dart';
import 'package:memos_flutter_app/features/share/share_clip_models.dart';

void main() {
  test('ShareComposeRequest defaults local-save toast to false', () {
    const request = ShareComposeRequest(
      text: 'Shared memo body',
      selectionOffset: 16,
    );

    expect(request.showLocalSaveSuccessToast, isFalse);
  });

  test('ShareComposeRequest copyWith can enable local-save toast', () {
    const request = ShareComposeRequest(
      text: 'Shared memo body',
      selectionOffset: 16,
    );

    final updated = request.copyWith(showLocalSaveSuccessToast: true);

    expect(updated.showLocalSaveSuccessToast, isTrue);
    expect(updated.text, request.text);
    expect(updated.selectionOffset, request.selectionOffset);
  });

  test('NoteInputSheet defaults local-save toast to false', () {
    const sheet = NoteInputSheet();

    expect(sheet.showLocalSaveSuccessToast, isFalse);
  });

  test('NoteInputSheet stores explicit local-save toast flag', () {
    const sheet = NoteInputSheet(showLocalSaveSuccessToast: true);

    expect(sheet.showLocalSaveSuccessToast, isTrue);
  });
}
