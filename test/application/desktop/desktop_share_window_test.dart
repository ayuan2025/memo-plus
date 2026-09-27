import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/desktop/desktop_share_window.dart';

void main() {
  test('desktop share task window capability is platform gated', () {
    expect(
      supportsDesktopShareTaskWindow(platform: TargetPlatform.macOS),
      isTrue,
    );
    expect(
      supportsDesktopShareTaskWindow(platform: TargetPlatform.windows),
      isFalse,
    );
    expect(
      supportsDesktopShareTaskWindow(platform: TargetPlatform.linux),
      isFalse,
    );
    expect(
      supportsDesktopShareTaskWindow(platform: TargetPlatform.android),
      isFalse,
    );
    expect(
      supportsDesktopShareTaskWindow(platform: TargetPlatform.iOS),
      isFalse,
    );
  });
}
