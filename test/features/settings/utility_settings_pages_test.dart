import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/features/settings/export_logs_screen.dart';
import 'package:memos_flutter_app/features/settings/self_repair_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/platform/widgets/platform_controls.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';

import 'settings_test_harness.dart';

void main() {
  testWidgets('self repair page uses settings seams and opens confirmation', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const SelfRepairScreen(),
        overrides: [
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(ref),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsOneWidget);
    expect(find.text('Self Repair'), findsOneWidget);
    expect(find.text('Repair abnormal tags'), findsOneWidget);
    expect(find.text('Rebuild search index'), findsOneWidget);
    expect(find.text('Rebuild statistics cache'), findsOneWidget);
    expect(
      find.textContaining('These actions repair local derived data only'),
      findsOneWidget,
    );

    await tester.tap(find.text('Repair abnormal tags'));
    await tester.pumpAndSettle();

    expect(find.text('Repair abnormal tags?'), findsOneWidget);
    expect(find.text('Confirm'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('export logs page uses settings seams and preserves local inputs', (
    tester,
  ) async {
    late _TestDevicePreferencesController deviceController;

    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const ExportLogsScreen(),
        overrides: [
          devicePreferencesProvider.overrideWith((ref) {
            deviceController = _TestDevicePreferencesController(ref);
            return deviceController;
          }),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsNWidgets(4));
    expect(find.byType(SettingsToggleRow), findsNWidgets(3));
    expect(find.byType(SettingsInfoRow), findsNWidgets(2));
    expect(find.text('Export Logs'), findsOneWidget);
    expect(find.text('Include error details'), findsOneWidget);
    expect(find.text('Include pending queue'), findsOneWidget);
    expect(find.text('Record request/response logs'), findsOneWidget);
    expect(find.text('Additional notes (optional)'), findsOneWidget);
    expect(find.text('Export log bundle'), findsOneWidget);
    expect(find.text('Clear logs'), findsOneWidget);

    final switches = tester.widgetList<PlatformSwitch>(
      find.byType(PlatformSwitch),
    );
    switches.elementAt(2).onChanged?.call(false);
    await tester.pumpAndSettle();

    expect(deviceController.state.networkLoggingEnabled, isFalse);
    expect(find.byType(SettingsInfoRow), findsNWidgets(3));
    expect(
      find.text(
        'For login/sync/backup issues, enable network logging before exporting.',
      ),
      findsOneWidget,
    );

    await tester.enterText(find.byType(TextField), 'network failed at 10:00');
    await tester.pump();

    expect(find.text('network failed at 10:00'), findsOneWidget);

    await tester.tap(find.text('Clear logs'));
    await tester.pumpAndSettle();

    expect(find.text('Clear logs'), findsWidgets);
    expect(
      find.text(
        'Clear all log data on this device? Exported files will not be deleted.',
      ),
      findsOneWidget,
    );
  });
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository()
    : _prefs = DevicePreferences.defaultsForLanguage(AppLanguage.en),
      super(PreferencesMigrationService(const FlutterSecureStorage()));

  DevicePreferences _prefs;

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(_prefs);
  }

  @override
  Future<DevicePreferences> read() async {
    return _prefs;
  }

  @override
  Future<void> write(DevicePreferences prefs) async {
    _prefs = prefs;
  }
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref)
    : super(ref, _TestDevicePreferencesRepository());
}
