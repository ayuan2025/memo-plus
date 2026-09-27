import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/version_probe_gate.dart';

void main() {
  test('enables version probe outside release builds', () {
    expect(shouldEnableVersionProbe(isReleaseMode: false), isTrue);
  });

  test('disables version probe in release builds', () {
    expect(shouldEnableVersionProbe(isReleaseMode: true), isFalse);
  });
}
