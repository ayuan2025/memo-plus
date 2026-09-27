import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/features/settings/export_memos_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/platform/widgets/platform_controls.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';

import 'settings_test_harness.dart';

void main() {
  testWidgets('export memos page uses settings seams', (tester) async {
    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const ExportMemosScreen(),
        overrides: [
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(ref),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsNWidgets(2));
    expect(find.byType(SettingsValueRow), findsNWidgets(2));
    expect(find.byType(SettingsToggleRow), findsOneWidget);
    expect(find.byType(SettingsAction), findsOneWidget);
    expect(find.byType(SettingsInfoRow), findsOneWidget);
    expect(find.text('Export'), findsNWidgets(2));
    expect(find.text('Date Range'), findsOneWidget);
    expect(find.text('All'), findsOneWidget);
    expect(find.text('Include Archived'), findsOneWidget);
    expect(find.text('Export Format'), findsOneWidget);
    expect(find.text('Markdown + ZIP'), findsOneWidget);
    expect(
      find.text(
        'Note: Export includes content already synced to the local database '
        '(offline data included).',
      ),
      findsOneWidget,
    );

    final includeArchivedSwitch = tester.widget<PlatformSwitch>(
      find.byType(PlatformSwitch),
    );
    expect(includeArchivedSwitch.value, isFalse);

    includeArchivedSwitch.onChanged?.call(true);
    await tester.pumpAndSettle();

    final updatedIncludeArchivedSwitch = tester.widget<PlatformSwitch>(
      find.byType(PlatformSwitch),
    );
    expect(updatedIncludeArchivedSwitch.value, isTrue);
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
