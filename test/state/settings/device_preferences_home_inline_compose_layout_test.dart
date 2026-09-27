import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/models/device_preferences.dart';

void main() {
  test('serializes and restores home inline compose layout', () {
    final prefs = DevicePreferences.defaults.copyWith(
      homeInlineComposePanelLayout: const HomeInlineComposePanelLayoutPreference(
        width: 640,
        editorHeight: 180,
        xRatio: 0.4,
        yRatio: 0.25,
      ),
    );

    final restored = DevicePreferences.fromJson(prefs.toJson());
    final layout = restored.homeInlineComposePanelLayout;

    expect(layout, isNotNull);
    expect(layout!.width, 640);
    expect(layout.editorHeight, 180);
    expect(layout.xRatio, 0.4);
    expect(layout.yRatio, 0.25);
  });

  test('clamps invalid stored ratios during decode', () {
    final restored = DevicePreferences.fromJson({
      ...DevicePreferences.defaults.toJson(),
      'homeInlineComposePanelLayout': {
        'width': 500,
        'editorHeight': 160,
        'xRatio': 2,
        'yRatio': -1,
      },
    });

    final layout = restored.homeInlineComposePanelLayout;
    expect(layout, isNotNull);
    expect(layout!.xRatio, 1);
    expect(layout.yRatio, 0);
  });

  test('drops incomplete stored layout payloads', () {
    final restored = DevicePreferences.fromJson({
      ...DevicePreferences.defaults.toJson(),
      'homeInlineComposePanelLayout': {
        'width': 500,
        'xRatio': 0.5,
      },
    });

    expect(restored.homeInlineComposePanelLayout, isNull);
  });
}
