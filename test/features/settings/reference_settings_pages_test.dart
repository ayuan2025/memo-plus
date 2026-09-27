import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/features/settings/laboratory_screen.dart';
import 'package:memos_flutter_app/features/settings/navigation_mode_screen.dart';
import 'package:memos_flutter_app/features/settings/placeholder_settings_screen.dart';
import 'package:memos_flutter_app/features/settings/settings_ui.dart';
import 'package:memos_flutter_app/features/settings/user_guide_screen.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'settings_test_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    PackageInfo.setMockInitialValues(
      appName: 'MemoFlow',
      packageName: 'dev.memoflow.test',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
      installerStore: null,
    );
  });

  testWidgets('laboratory screen uses settings seams and keeps navigation', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSettingsTestApp(home: const LaboratoryScreen()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsOneWidget);
    expect(find.byType(SettingsNavigationRow), findsNWidgets(5));
    expect(find.text('Laboratory'), findsOneWidget);
    expect(find.text('Navigation Mode'), findsOneWidget);
    expect(find.text('MemoFlow'), findsOneWidget);
    expect(find.text('VERSION 1.0.0'), findsOneWidget);

    await tester.tap(find.text('Navigation Mode'));
    await tester.pumpAndSettle();

    expect(find.byType(NavigationModeScreen), findsOneWidget);
  });

  testWidgets('user guide screen uses settings seams and opens info surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const UserGuideScreen(),
        overrides: [
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(
              ref,
              _TestDevicePreferencesRepository(),
            ),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsOneWidget);
    expect(find.byType(SettingsNavigationRow), findsNWidgets(5));
    expect(find.text('User Guide'), findsOneWidget);
    expect(find.text('Memos Backend Docs'), findsOneWidget);
    expect(find.text('Pull to Refresh'), findsOneWidget);

    await tester.tap(find.text('Pull to Refresh'));
    await tester.pumpAndSettle();

    expect(find.text('Pull to Refresh'), findsWidgets);
    expect(
      find.text(
        'Pull down in the memo list to refresh and sync. Sync fetches the '
        'most recent items first; run a full sync periodically to keep '
        'stats/heatmap complete.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('placeholder screen renders dynamic strings on settings seams', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildSettingsTestApp(
        home: const SettingsPlaceholderScreen(
          titleKey: 'msg_laboratory',
          messageKey: 'msg_feature_in_progress',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(SettingsSection), findsOneWidget);
    expect(find.byType(SettingsProfileSummary), findsOneWidget);
    expect(find.text('Laboratory'), findsOneWidget);
    expect(find.text('Feature in progress. Coming soon.'), findsOneWidget);
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
  _TestDevicePreferencesController(super.ref, super.repo);
}
