import '../../data/models/attachment.dart';
import 'memo_image_src_normalizer.dart';
import 'memo_inline_image_sources.dart';
import 'memo_inline_image_syntax.dart';

class MemoInlineImageRenderPolicy {
  const MemoInlineImageRenderPolicy({
    required this.syntax,
    required this.localSourcePolicy,
  });

  static final none = MemoInlineImageRenderPolicy(
    syntax: MemoInlineImageSyntax.none,
    localSourcePolicy: MemoInlineImageSourcePolicy.empty,
  );

  final MemoInlineImageSyntax syntax;
  final MemoInlineImageSourcePolicy localSourcePolicy;

  bool get rendersImages => syntax.rendersImages;

  String get cacheFingerprint =>
      '${syntax.cacheToken}|local=${localSourcePolicy.fingerprint}';
}

MemoInlineImageRenderPolicy buildMemoInlineImageRenderPolicy({
  required String content,
  required List<Attachment> attachments,
  required bool enabled,
  required MemoInlineImageSyntax syntax,
}) {
  if (!enabled || !syntax.rendersImages) {
    return MemoInlineImageRenderPolicy.none;
  }
  final hasSupportedImages = switch (syntax) {
    MemoInlineImageSyntax.none => false,
    MemoInlineImageSyntax.markdownOnly => contentHasMarkdownImageSyntax(
      content,
    ),
    MemoInlineImageSyntax.markdownAndHtml => extractMemoImageUrlsForSyntax(
      content,
      syntax,
    ).isNotEmpty,
  };
  if (!hasSupportedImages) {
    return MemoInlineImageRenderPolicy.none;
  }
  return MemoInlineImageRenderPolicy(
    syntax: syntax,
    localSourcePolicy: buildMemoInlineImageSourcePolicy(
      content: content,
      attachments: attachments,
      imageSyntax: syntax,
    ),
  );
}
