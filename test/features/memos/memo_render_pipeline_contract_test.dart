import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/memo_image_src_normalizer.dart';
import 'package:memos_flutter_app/features/memos/memo_inline_image_syntax.dart';
import 'package:memos_flutter_app/features/memos/memo_markdown_preprocessor.dart';
import 'package:memos_flutter_app/features/memos/memo_render_pipeline.dart';

void main() {
  final pipeline = MemoRenderPipeline();

  test('full html document renders through code block mode', () {
    const content =
        '<!DOCTYPE html>\n'
        '<html>\n'
        '<head><title>Hello</title></head>\n'
        '<body><p>Hello</p></body>\n'
        '</html>';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(artifact.mode, MemoRenderMode.codeBlock);
    expect(artifact.content, content);
  });

  test('embedded full html document is wrapped as escaped fenced html', () {
    const content =
        'intro\n\n'
        '<!DOCTYPE html>\n'
        '<html>\n'
        '<body>\n'
        '<p>Hello</p>\n'
        '</body>\n'
        '</html>';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(artifact.mode, MemoRenderMode.html);
    expect(artifact.content, contains('<pre><code class="language-html">'));
    expect(artifact.content, contains('&lt;!DOCTYPE html&gt;'));
    expect(artifact.content, contains('&lt;p&gt;Hello&lt;/p&gt;'));
    expect(artifact.content, isNot(contains('<p>Hello</p>')));
  });

  test('empty markdown links collapse to text and images stay intact', () {
    const content = 'Open [](/docs)\n\n![](https://example.com/image.png)';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(artifact.content, contains('/docs'));
    expect(
      artifact.content,
      contains('<img src="https://example.com/image.png"'),
    );
  });

  test('markdown-only image mode preserves markdown image syntax', () {
    const content = 'before\n\n![alt](https://example.com/image.png)\n\nafter';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
    );

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(
      artifact.content,
      contains('<img src="https://example.com/image.png" alt="alt"'),
    );
  });

  test('markdown-only image mode strips raw html image tags', () {
    const content =
        'before\n\n'
        '<img src="https://example.com/html.png" alt="html">\n\n'
        '![md](https://example.com/markdown.png)\n\n'
        'after';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
    );

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, contains('https://example.com/markdown.png'));
    expect(artifact.content, isNot(contains('https://example.com/html.png')));
  });

  test(
    'markdown-only image mode leaves fenced html image examples as code',
    () {
      const content =
          'before\n\n'
          '```html\n'
          '<img src="https://example.com/in-code.png">\n'
          '```\n\n'
          'after';

      final artifact = pipeline.build(
        data: content,
        renderImages: true,
        imageSyntax: MemoInlineImageSyntax.markdownOnly,
      );

      expect(artifact.content, contains('<pre><code class="language-html">'));
      expect(artifact.content, contains('&lt;img'));
      expect(artifact.content, isNot(contains('<img src=')));
    },
  );

  test('renderImages false strips html img tags from rendered output', () {
    const content =
        'before\n\n'
        '<img src="https://example.com/a.png" alt="a">\n\n'
        'after';

    final artifact = pipeline.build(data: content, renderImages: false);

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, isNot(contains('<img')));
    expect(artifact.content, isNot(contains('https://example.com/a.png')));
  });

  test('allowlisted local file images stay in rendered html', () {
    const localUrl = 'file:///tmp/memo-inline-local.png';
    const content = 'before\n\n<img src="$localUrl" width="100%">\n\nafter';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      allowedLocalImageUrls: const {localUrl},
    );

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, contains('<img src="$localUrl" width="100%">'));
  });

  test('allowlisted local markdown file images stay in rendered html', () {
    const localUrl = 'file:///tmp/memo-inline-local.png';
    const content = 'before\n\n![]($localUrl)\n\nafter';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
      allowedLocalImageUrls: const {localUrl},
    );

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, contains('<img src="$localUrl"'));
  });

  test('unallowlisted local markdown file images are stripped', () {
    const localUrl = 'file:///tmp/memo-inline-local.png';
    const content = 'before\n\n![]($localUrl)\n\nafter';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
    );

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, isNot(contains('<img')));
    expect(artifact.content, isNot(contains(localUrl)));
  });

  test('image syntax mode participates in render cache freshness', () {
    final cachePipeline = MemoRenderPipeline();
    const content = 'before\n\n![](https://example.com/cache.png)\n\nafter';
    const cacheKey = 'memo-cache-key';

    final stripped = cachePipeline.build(
      data: content,
      renderImages: false,
      cacheKey: cacheKey,
    );
    final inline = cachePipeline.build(
      data: content,
      renderImages: true,
      imageSyntax: MemoInlineImageSyntax.markdownOnly,
      cacheKey: cacheKey,
    );

    expect(stripped.content, isNot(contains('<img')));
    expect(inline.content, contains('<img'));
    expect(inline.content, contains('https://example.com/cache.png'));
  });

  test('unallowlisted local file images are stripped from rendered html', () {
    const localUrl = 'file:///tmp/memo-inline-local.png';
    const content = 'before\n\n<img src="$localUrl">\n\nafter';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(artifact.content, contains('before'));
    expect(artifact.content, contains('after'));
    expect(artifact.content, isNot(contains('<img')));
    expect(artifact.content, isNot(contains(localUrl)));
  });

  test(
    'preprocessor preserves explicit blank lines with html placeholders',
    () {
      expect(
        sanitizeMemoMarkdown('Alpha\n\nBeta'),
        'Alpha\n\n<p class="memo-blank-line">\u200B</p>\n\nBeta',
      );
      expect(
        sanitizeMemoMarkdown('- item\n\nParagraph'),
        '- item\n\n<p class="memo-blank-line">\u200B</p>\n\nParagraph',
      );
    },
  );

  test('search highlight skips code and memo tag subtrees', () {
    const content = '#tag\n\n`keyword` plain keyword';

    final artifact = pipeline.build(
      data: content,
      renderImages: true,
      highlightQuery: 'tag keyword',
    );

    expect(_countMatches(artifact.content, 'class="memohighlight"'), 1);
    expect(artifact.content, contains('class="memotag"'));
    expect(artifact.content, contains('<code>keyword</code>'));
  });

  test('tag decoration skips hashes inside links', () {
    const content =
        '#Work\n\n'
        'See [section](https://example.com/article#intro) '
        'and [jump](#details)';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(_countMatches(artifact.content, 'class="memotag"'), 1);
    expect(artifact.content, contains('data-tag="Work"'));
    expect(
      artifact.content,
      contains('href="https://example.com/article#intro"'),
    );
    expect(artifact.content, contains('href="#details"'));
    expect(artifact.content, isNot(contains('data-tag="intro"')));
    expect(artifact.content, isNot(contains('data-tag="details"')));
  });

  test('tag decoration skips prose hashes outside strict tag zones', () {
    const content =
        '\u6D4B\u8BD5\u6587\u672C #\u8FD9\u662F\u6D4B\u8BD5\u6587\u672C';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(artifact.content, isNot(contains('class="memotag"')));
    expect(artifact.content, isNot(contains('data-tag=')));
  });

  test('tag decoration wraps strict tag-zone lines', () {
    const content = '#openwrt #build body #ignored\n\nbody';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(_countMatches(artifact.content, 'class="memotag"'), 2);
    expect(artifact.content, contains('data-tag="openwrt"'));
    expect(artifact.content, contains('data-tag="build"'));
    expect(artifact.content, isNot(contains('data-tag="ignored"')));
  });

  test('tag decoration treats MemoFlow internal markers as non-content', () {
    const content = '''# Example article

Captured body

#clip #reading

<!-- memoflow-third-party-share -->''';

    final artifact = pipeline.build(data: content, renderImages: true);

    expect(_countMatches(artifact.content, 'class="memotag"'), 2);
    expect(artifact.content, contains('data-tag="clip"'));
    expect(artifact.content, contains('data-tag="reading"'));
  });

  test('image src normalizer keeps blob to raw conversions stable', () {
    expect(
      normalizeMarkdownImageSrc('https://github.com/o/r/blob/main/a.png'),
      'https://raw.githubusercontent.com/o/r/main/a.png',
    );
    expect(
      normalizeMarkdownImageSrc('https://gitlab.com/o/r/-/blob/main/a.png'),
      'https://gitlab.com/o/r/-/raw/main/a.png',
    );
    expect(
      normalizeMarkdownImageSrc('https://gitee.com/o/r/blob/main/a.png'),
      'https://gitee.com/o/r/raw/main/a.png',
    );
  });
}

int _countMatches(String text, String pattern) {
  return RegExp(RegExp.escape(pattern)).allMatches(text).length;
}
