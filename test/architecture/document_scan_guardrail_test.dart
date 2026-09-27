import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// The scan geometry and imaging code is vendored third-party code, but it is
/// still *our* seam: it must stay pure Dart so every entry point can run inside
/// `compute()` and in a unit test, and it must stay in the `core` layer so no
/// feature can start depending on a widget to do geometry.
void main() {
  final scanRoot = Directory(p.join('lib', 'core', 'scan'));

  test('the scan module exists', () {
    expect(scanRoot.existsSync(), isTrue);
  });

  test('scan code never imports Flutter UI or a higher layer', () async {
    const forbiddenPrefixes = <String>[
      'package:flutter/material.dart',
      'package:flutter/widgets.dart',
      'package:flutter/cupertino.dart',
      'package:flutter/rendering.dart',
      'package:memos_flutter_app/features/',
      'package:memos_flutter_app/state/',
      'package:memos_flutter_app/application/',
      '../features/',
      '../../features/',
      '../state/',
      '../../state/',
    ];

    final violations = <String>[];
    await for (final entry in scanRoot.list(recursive: true)) {
      if (entry is! File || p.extension(entry.path) != '.dart') continue;
      final relative = p
          .relative(entry.path, from: Directory.current.path)
          .replaceAll('\\', '/');

      for (final import in _importsOf(await entry.readAsString())) {
        if (forbiddenPrefixes.any(import.startsWith)) {
          violations.add('$relative: $import');
        }
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Scan geometry must not depend on Flutter UI or higher layers:\n'
                '${violations.join('\n')}',
    );
  });

  test('scan code stays free of dart:io, so it runs on web too', () async {
    final violations = <String>[];
    await for (final entry in scanRoot.list(recursive: true)) {
      if (entry is! File || p.extension(entry.path) != '.dart') continue;
      final relative = p
          .relative(entry.path, from: Directory.current.path)
          .replaceAll('\\', '/');

      if (_importsOf(await entry.readAsString()).contains('dart:io')) {
        violations.add(relative);
      }
    }

    expect(
      violations,
      isEmpty,
      reason: violations.isEmpty
          ? null
          : 'Scan entry points take bytes, not paths; these files still reach '
                'for dart:io:\n${violations.join('\n')}',
    );
  });
}

List<String> _importsOf(String source) => RegExp(
  r"""^import\s+'([^']+)';""",
  multiLine: true,
).allMatches(source).map((m) => m.group(1)!).toList(growable: false);
