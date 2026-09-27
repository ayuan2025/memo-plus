import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('desktop share launcher keeps share UI out of lower desktop seam', () {
    final launcher = File(
      'lib/application/desktop/desktop_share_window.dart',
    ).readAsStringSync();
    final channel = File(
      'lib/core/desktop_quick_input_channel.dart',
    ).readAsStringSync();

    expect(launcher.contains('features/share'), isFalse);
    expect(channel.contains('features/share'), isFalse);
  });

  test('desktop share window does not reuse settings warm-hide lifecycle', () {
    final launcher = File(
      'lib/application/desktop/desktop_share_window.dart',
    ).readAsStringSync();

    expect(launcher.contains('desktop_settings_window.dart'), isFalse);
    expect(launcher.contains('_desktopSettingsWindow'), isFalse);
    expect(launcher.contains('warm'), isFalse);
    expect(launcher.contains('hide'), isFalse);
  });
}
