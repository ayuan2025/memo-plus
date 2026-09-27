import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/location_settings.dart';
import 'package:memos_flutter_app/data/repositories/location_settings_repository.dart';
import 'package:memos_flutter_app/features/settings/location_settings_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/platform/widgets/platform_controls.dart';
import 'package:memos_flutter_app/state/settings/location_settings_provider.dart';

import 'settings_test_harness.dart';

void main() {
  testWidgets('location settings uses seams and preserves writes', (
    tester,
  ) async {
    late _FakeLocationSettingsController controller;

    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const LocationSettingsScreen(),
        overrides: [
          locationSettingsProvider.overrideWith((ref) {
            controller = _FakeLocationSettingsController(
              ref,
              LocationSettings.defaults,
            );
            return controller;
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsNWidgets(2));
    expect(find.byType(SettingsToggleRow), findsOneWidget);
    expect(
      find.byType(SettingsMenuRow<LocationServiceProvider>),
      findsOneWidget,
    );
    expect(find.byType(SettingsInputRow), findsNWidgets(2));
    expect(find.text('Location'), findsOneWidget);
    expect(find.text('Enable memo location'), findsOneWidget);

    final enableSwitch = tester.widget<PlatformSwitch>(
      find.byType(PlatformSwitch).first,
    );
    enableSwitch.onChanged?.call(true);
    await tester.pump();

    expect(controller.state.enabled, isTrue);

    final providerMenu = tester
        .widget<SettingsMenuRow<LocationServiceProvider>>(
          find.byType(SettingsMenuRow<LocationServiceProvider>),
        );
    providerMenu.onChanged(LocationServiceProvider.baidu);
    await tester.pump();

    expect(controller.state.provider, LocationServiceProvider.baidu);
    expect(find.text('Baidu AK'), findsOneWidget);

    await tester.enterText(find.byType(TextField).first, '  baidu-key  ');
    await tester.pump();

    expect(controller.state.baiduWebKey, 'baidu-key');

    await tester.tap(find.text('Street'));
    await tester.pump();

    expect(controller.state.precision, LocationPrecision.street);
  });
}

class _FakeLocationSettingsController extends LocationSettingsController {
  _FakeLocationSettingsController(Ref ref, LocationSettings initial)
    : super(ref, _FakeLocationSettingsRepository(initial)) {
    state = initial;
  }

  @override
  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
  }

  @override
  void setProvider(LocationServiceProvider value) {
    state = state.copyWith(provider: value);
  }

  @override
  void setAmapWebKey(String value) {
    state = state.copyWith(amapWebKey: value.trim());
  }

  @override
  void setAmapSecurityKey(String value) {
    state = state.copyWith(amapSecurityKey: value.trim());
  }

  @override
  void setBaiduWebKey(String value) {
    state = state.copyWith(baiduWebKey: value.trim());
  }

  @override
  void setGoogleApiKey(String value) {
    state = state.copyWith(googleApiKey: value.trim());
  }

  @override
  void setPrecision(LocationPrecision value) {
    state = state.copyWith(precision: value);
  }
}

class _FakeLocationSettingsRepository extends LocationSettingsRepository {
  _FakeLocationSettingsRepository(this._settings)
    : super(const FlutterSecureStorage(), accountKey: 'test-location');

  LocationSettings _settings;

  @override
  Future<LocationSettings> read() async => _settings;

  @override
  Future<void> write(LocationSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> clear() async {
    _settings = LocationSettings.defaults;
  }
}
