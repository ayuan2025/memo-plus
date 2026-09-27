import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/features/memos/memo_image_grid.dart';
import 'package:memos_flutter_app/features/memos/memo_image_preview_adapters.dart';
import 'package:memos_flutter_app/state/memos/memo_composer_state.dart';

void main() {
  test('pending attachment adapter falls back to file path', () {
    const attachment = MemoComposerPendingAttachment(
      uid: 'pending-1',
      filePath: r'C:\demo\pending.png',
      filename: 'pending.png',
      mimeType: 'image/png',
      size: 12,
    );

    final item = pendingAttachmentToImagePreviewItem(
      attachment,
      sourceId: attachment.uid,
    );

    expect(item.id, 'pending-1');
    expect(item.title, 'pending.png');
    expect(item.mimeType, 'image/png');
    expect(item.localFile?.path, File(r'C:\demo\pending.png').path);
  });

  test('attachment adapter maps remote image fields', () {
    const attachment = Attachment(
      name: 'attachments/abc',
      filename: 'photo.png',
      type: 'image/png',
      size: 2048,
      externalLink: '/file/photo.png',
      width: 1200,
      height: 800,
    );

    final item = attachmentToImagePreviewItem(
      attachment,
      Uri.parse('https://example.com'),
      'Bearer token',
    );

    expect(item, isNotNull);
    expect(item!.id, 'attachments/abc');
    expect(item.title, 'photo.png');
    expect(item.mimeType, 'image/png');
    expect(item.fullUrl, 'https://example.com/file/photo.png');
    expect(item.headers?['Authorization'], 'Bearer token');
    expect(item.width, 1200);
    expect(item.height, 800);
  });

  test('memo image entry adapter preserves preview metadata', () {
    const entry = MemoImageEntry(
      id: 'entry-1',
      title: 'Entry',
      mimeType: 'image/jpeg',
      previewUrl: 'https://example.com/thumb.jpg',
      fullUrl: 'https://example.com/full.jpg',
      headers: <String, String>{'Authorization': 'Bearer token'},
      width: 640,
      height: 480,
    );

    final item = memoImageEntryToImagePreviewItem(entry);

    expect(item.id, 'entry-1');
    expect(item.title, 'Entry');
    expect(item.mimeType, 'image/jpeg');
    expect(item.thumbnailUrl, 'https://example.com/thumb.jpg');
    expect(item.fullUrl, 'https://example.com/full.jpg');
    expect(item.headers?['Authorization'], 'Bearer token');
    expect(item.width, 640);
    expect(item.height, 480);
  });
}
