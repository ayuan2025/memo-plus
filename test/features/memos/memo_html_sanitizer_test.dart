import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/memos/memo_html_sanitizer.dart';

void main() {
  test(
    'sanitizeMemoHtml removes blocked tags comments and dangerous links',
    () {
      const html =
          '<!-- note -->'
          '<script>alert(1)</script>'
          '<style>body{display:none;}</style>'
          '<p>safe</p>'
          '<a href="javascript:alert(1)">bad</a>';

      final sanitized = sanitizeMemoHtml(html);

      expect(sanitized, contains('<p>safe</p>'));
      expect(sanitized, isNot(contains('<!--')));
      expect(sanitized, isNot(contains('<script')));
      expect(sanitized, isNot(contains('<style')));
      expect(sanitized, isNot(contains('javascript:')));
      expect(sanitized, isNot(contains('<a href="javascript:alert(1)">')));
    },
  );

  test(
    'sanitizeMemoHtml preserves safe urls checkbox inputs and allowed attrs',
    () {
      const html =
          '<a href="/docs" title="Doc">docs</a>'
          '<a href="mailto:test@example.com">mail</a>'
          '<img src="https://example.com/a.png" width="16" onclick="bad">'
          '<input type="checkbox" checked disabled onclick="bad">';

      final sanitized = sanitizeMemoHtml(html);

      expect(sanitized, contains('<a href="/docs" title="Doc">docs</a>'));
      expect(sanitized, contains('<a href="mailto:test@example.com">mail</a>'));
      expect(
        sanitized,
        contains('<img src="https://example.com/a.png" width="16">'),
      );
      expect(
        sanitized,
        contains('<input type="checkbox" checked="" disabled="">'),
      );
      expect(sanitized, isNot(contains('onclick=')));
    },
  );

  test('sanitizeMemoHtml blocks file image urls by default', () {
    const html = '<p>before</p><img src="file:///tmp/private.png"><p>after</p>';

    final sanitized = sanitizeMemoHtml(html);

    expect(sanitized, contains('<p>before</p>'));
    expect(sanitized, contains('<p>after</p>'));
    expect(sanitized, isNot(contains('<img')));
    expect(sanitized, isNot(contains('file:///tmp/private.png')));
  });

  test(
    'sanitizeMemoHtml preserves allowlisted file image urls only for img',
    () {
      const localUrl = 'file:///tmp/private.png';
      const html =
          '<a href="$localUrl">file</a>'
          '<img src="$localUrl" width="100%" onclick="bad">';

      final sanitized = sanitizeMemoHtml(
        html,
        allowedLocalImageUrls: const {localUrl},
      );

      expect(
        sanitized,
        contains('<img src="file:///tmp/private.png" width="100%">'),
      );
      expect(sanitized, isNot(contains('<a href="file:///tmp/private.png">')));
      expect(sanitized, isNot(contains('onclick=')));
    },
  );
}
