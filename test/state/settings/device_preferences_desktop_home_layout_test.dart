import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/data/models/device_preferences.dart';

void main() {
  test('serializes and restores desktop home layout preference', () {
    final prefs = DevicePreferences.defaults.copyWith(
      desktopHomeLayoutPreference: const DesktopHomeLayoutPreference(
        navMode: DesktopHomeNavPreference.rail,
        secondaryPaneVisible: false,
        secondaryPaneWidth: 388,
      ),
    );

    final restored = DevicePreferences.fromJson(prefs.toJson());
    final layout = restored.desktopHomeLayoutPreference;

    expect(layout.navMode, DesktopHomeNavPreference.rail);
    expect(layout.secondaryPaneVisible, isFalse);
    expect(layout.secondaryPaneWidth, 388);
  });

  test('desktop home layout falls back to defaults when missing', () {
    final restored = DevicePreferences.fromJson(DevicePreferences.defaults.toJson());
    final layout = restored.desktopHomeLayoutPreference;

    expect(layout.navMode, DesktopHomeNavPreference.expanded);
    expect(layout.secondaryPaneVisible, isTrue);
    expect(layout.secondaryPaneWidth, 420);
  });

  test('desktop home layout clamps pane width and invalid nav mode', () {
    final restored = DevicePreferences.fromJson({
      ...DevicePreferences.defaults.toJson(),
      'desktopHomeLayoutPreference': {
        'navMode': 'invalid',
        'secondaryPaneVisible': false,
        'secondaryPaneWidth': 999,
      },
    });

    final layout = restored.desktopHomeLayoutPreference;
    expect(layout.navMode, DesktopHomeNavPreference.expanded);
    expect(layout.secondaryPaneVisible, isFalse);
    expect(layout.secondaryPaneWidth, 560);
  });
}
