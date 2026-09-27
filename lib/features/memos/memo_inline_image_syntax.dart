enum MemoInlineImageSyntax { none, markdownOnly, markdownAndHtml }

extension MemoInlineImageSyntaxX on MemoInlineImageSyntax {
  bool get rendersImages => this != MemoInlineImageSyntax.none;

  bool get allowsHtmlImages => this == MemoInlineImageSyntax.markdownAndHtml;

  String get cacheToken => switch (this) {
    MemoInlineImageSyntax.none => 'none',
    MemoInlineImageSyntax.markdownOnly => 'markdownOnly',
    MemoInlineImageSyntax.markdownAndHtml => 'markdownAndHtml',
  };
}

MemoInlineImageSyntax resolveMemoInlineImageSyntax({
  required bool renderImages,
  MemoInlineImageSyntax? imageSyntax,
}) {
  return imageSyntax ??
      (renderImages
          ? MemoInlineImageSyntax.markdownAndHtml
          : MemoInlineImageSyntax.none);
}
