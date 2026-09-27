import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/attachment_mime_type.dart';

void main() {
  group('guessAttachmentMimeType', () {
    test('resolves image extensions', () {
      expect(guessAttachmentMimeType('photo.png'), 'image/png');
      expect(guessAttachmentMimeType('photo.JPG'), 'image/jpeg');
      expect(guessAttachmentMimeType('scan.heic'), 'image/heic');
      expect(guessAttachmentMimeType('vector.svg'), 'image/svg+xml');
    });

    test('resolves audio and video extensions', () {
      expect(guessAttachmentMimeType('voice.m4a'), 'audio/mp4');
      expect(guessAttachmentMimeType('voice.opus'), 'audio/opus');
      expect(guessAttachmentMimeType('clip.mp4'), 'video/mp4');
      expect(guessAttachmentMimeType('clip.webm'), 'video/webm');
      expect(guessAttachmentMimeType('clip.m4v'), 'video/x-m4v');
    });

    test('resolves document and text extensions', () {
      expect(guessAttachmentMimeType('report.pdf'), 'application/pdf');
      expect(
        guessAttachmentMimeType('archive.7z'),
        'application/x-7z-compressed',
      );
      expect(guessAttachmentMimeType('notes.md'), 'text/markdown');
      expect(guessAttachmentMimeType('data.csv'), 'text/csv');
    });

    test('uses configurable fallback for unknown extensions', () {
      expect(
        guessAttachmentMimeType('unknown.bin'),
        'application/octet-stream',
      );
      expect(
        guessAttachmentMimeType('unknown.bin', fallback: 'video/mp4'),
        'video/mp4',
      );
    });
  });
}
