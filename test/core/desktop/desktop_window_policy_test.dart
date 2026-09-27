import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/desktop_layout_policy.dart';
import 'package:memos_flutter_app/core/desktop/desktop_window_policy.dart';

void main() {
  test('resolves shared main-window size policy for Windows and macOS', () {
    for (final platform in <TargetPlatform>[
      TargetPlatform.windows,
      TargetPlatform.macOS,
    ]) {
      final policy = resolveDesktopMainWindowPolicy(platform: platform);

      expect(policy.initialSize, const Size(1360, 860));
      expect(policy.minimumSize, const Size(960, 640));
    }
  });

  test(
    'keeps main-window minimum width aligned to the narrow layout floor',
    () {
      final policy = resolveDesktopMainWindowPolicy(
        platform: TargetPlatform.windows,
      );

      expect(policy.minimumSize.width, kWindowsDesktopNarrowBreakpoint);
      expect(policy.minimumSize.height, 640);
    },
  );
}
