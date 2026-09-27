import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/features/collections/collection_rss_html_content.dart';

void main() {
  testWidgets('renders linked RSS images in narrow selectable content', (
    tester,
  ) async {
    const imageData =
        'data:image/png;base64,'
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=';
    const html =
        '<p>Before <a href="https://example.com"><img src="$imageData" alt="pixel"></a> after.</p>';

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 32,
            child: SelectionArea(
              child: CollectionRssHtmlContent(
                html: html,
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}
