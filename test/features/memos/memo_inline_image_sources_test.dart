import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/features/memos/memo_inline_image_sources.dart';
import 'package:memos_flutter_app/features/memos/memo_inline_image_syntax.dart';
import 'package:path/path.dart' as p;

void main() {
  test('allows current memo image attachment local file urls', () {
    final localUrl = Uri.file(_tempPath('owned-photo.jpg')).toString();

    final policy = buildMemoInlineImageSourcePolicy(
      content: '<p>intro</p><img src="$localUrl" width="100%">',
      attachments: [_imageAttachment(localUrl)],
    );

    expect(policy.allowedLocalImageUrls, contains(localUrl));
    expect(policy.hasAllowedSources, isTrue);
    expect(
      policy.fingerprint,
      isNot(MemoInlineImageSourcePolicy.empty.fingerprint),
    );
  });

  test('blocks local file urls not owned by current memo attachments', () {
    final contentUrl = Uri.file(_tempPath('unowned-photo.jpg')).toString();
    final attachmentUrl = Uri.file(_tempPath('owned-photo.jpg')).toString();

    final policy = buildMemoInlineImageSourcePolicy(
      content: '<img src="$contentUrl">',
      attachments: [_imageAttachment(attachmentUrl)],
    );

    expect(policy.allowedLocalImageUrls, isEmpty);
    expect(policy.fingerprint, MemoInlineImageSourcePolicy.empty.fingerprint);
  });

  test('does not treat file host urls as canonical local file urls', () {
    final localPath = _tempPath('host-mutated-photo.jpg');
    final canonicalUrl = Uri.file(localPath).toString();
    final hostMutatedUrl = canonicalUrl.replaceFirst(
      'file:///',
      'file://data/',
    );

    final policy = buildMemoInlineImageSourcePolicy(
      content: '<img src="$hostMutatedUrl">',
      attachments: [_imageAttachment(canonicalUrl)],
    );

    expect(policy.allowedLocalImageUrls, isEmpty);
  });

  test('ignores non-image attachments when building the allowlist', () {
    final localUrl = Uri.file(_tempPath('document-photo.jpg')).toString();

    final policy = buildMemoInlineImageSourcePolicy(
      content: '<img src="$localUrl">',
      attachments: [
        Attachment(
          name: 'attachments/doc',
          filename: 'doc.txt',
          type: 'text/plain',
          size: 1,
          externalLink: localUrl,
        ),
      ],
    );

    expect(policy.allowedLocalImageUrls, isEmpty);
  });

  test('markdown-only mode ignores html image local urls', () {
    final localUrl = Uri.file(_tempPath('html-owned-photo.jpg')).toString();

    final policy = buildMemoInlineImageSourcePolicy(
      content: '<img src="$localUrl">\n\n![](https://example.com/remote.png)',
      attachments: [_imageAttachment(localUrl)],
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
    );

    expect(policy.allowedLocalImageUrls, isEmpty);
  });

  test('markdown-only mode allows markdown image local urls', () {
    final localUrl = Uri.file(_tempPath('markdown-owned-photo.jpg')).toString();

    final policy = buildMemoInlineImageSourcePolicy(
      content: '![]($localUrl)',
      attachments: [_imageAttachment(localUrl)],
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
    );

    expect(policy.allowedLocalImageUrls, contains(localUrl));
  });
}

Attachment _imageAttachment(String externalLink) {
  return Attachment(
    name: 'attachments/photo',
    filename: 'photo.jpg',
    type: 'image/jpeg',
    size: 1,
    externalLink: externalLink,
  );
}

String _tempPath(String filename) {
  return p.join(
    Directory.systemTemp.path,
    'memo-inline-image-sources',
    filename,
  );
}
