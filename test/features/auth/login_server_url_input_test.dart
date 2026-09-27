import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/features/auth/login_server_url_input.dart';

void main() {
  test('normalizes fullwidth colon in address suffixes', () {
    expect(normalizeLoginServerUrlSuffix('localhost：5230'), 'localhost:5230');
    expect(
      normalizeLoginServerUrlSuffix('http：//localhost：5230'),
      'localhost:5230',
    );
  });

  test('restores complete URL drafts into protocol and suffix', () {
    final httpDraft = restoreLoginServerUrlDraft('http：//localhost：5230');
    expect(httpDraft.useHttps, isFalse);
    expect(httpDraft.suffix, 'localhost:5230');

    final httpsDraft = restoreLoginServerUrlDraft(
      'https://memos.example.com/api/v1',
    );
    expect(httpsDraft.useHttps, isTrue);
    expect(httpsDraft.suffix, 'memos.example.com/api/v1');
  });

  test('composes selected protocol with normalized suffix', () {
    expect(
      composeLoginServerBaseUrl(useHttps: true, rawSuffix: 'localhost：5230'),
      'https://localhost:5230',
    );
    expect(
      composeLoginServerBaseUrl(
        useHttps: false,
        rawSuffix: 'https://memos.example.com/api/v1',
      ),
      'http://memos.example.com/api/v1',
    );
  });

  test(
    'text formatter normalizes fullwidth colons without shifting cursor',
    () {
      const formatter = LoginServerUrlTextInputFormatter();
      final result = formatter.formatEditUpdate(
        const TextEditingValue(text: 'localhost'),
        const TextEditingValue(
          text: 'localhost：5230',
          selection: TextSelection.collapsed(offset: 14),
        ),
      );

      expect(result.text, 'localhost:5230');
      expect(result.selection.baseOffset, 14);
    },
  );
}
