import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/core/theme_colors.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/home_navigation_preferences.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';

class _MemorySecureStorage extends FlutterSecureStorage {
  final Map<String, String> _data = <String, String>{};

  void seed(String key, String value) {
    _data[key] = value;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _data.remove(key);
      return;
    }
    _data[key] = value;
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _data[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _data.remove(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PreferencesMigrationService', () {
    test(
      'migrates device-scoped legacy preferences into the new key',
      () async {
        final storage = _MemorySecureStorage();
        final legacy = AppPreferences.defaults.copyWith(
          language: AppLanguage.ja,
          hasSelectedLanguage: true,
          onboardingMode: AppOnboardingMode.server,
          themeMode: AppThemeMode.dark,
          themeColor: AppThemeColor.cypressGreen,
          launchAction: LaunchAction.quickInput,
        );
        storage.seed(
          legacyAppPreferencesDeviceKey,
          jsonEncode(legacy.toJson()),
        );

        final service = PreferencesMigrationService(storage);
        final migrated = await service.readDevice();

        expect(migrated, DevicePreferences.fromLegacy(legacy));

        final rawNew = await storage.read(key: devicePreferencesStorageKey);
        expect(rawNew, isNotNull);
        expect(jsonDecode(rawNew!)['language'], 'ja');
        expect(
          await storage.read(key: legacyAppPreferencesDeviceKey),
          isNotNull,
        );
      },
    );

    test(
      'migrates workspace-scoped legacy preferences and theme overrides',
      () async {
        const workspaceKey = 'workspace-1';
        final storage = _MemorySecureStorage();
        final workspaceTheme = CustomThemeSettings.defaults.copyWith(
          mode: CustomThemeMode.manual,
          autoLight: const Color(0xFF223344),
          manualLight: const Color(0xFF334455),
          manualDark: const Color(0xFF445566),
        );
        final legacy = AppPreferences.defaults.copyWith(
          language: AppLanguage.de,
          hasSelectedLanguage: true,
          useLegacyApi: false,
          homeQuickActionPrimary: HomeQuickAction.explore,
          homeQuickActionSecondary: HomeQuickAction.resources,
          homeQuickActionTertiary: HomeQuickAction.archived,
          accountThemeColors: const <String, AppThemeColor>{
            workspaceKey: AppThemeColor.duskPurple,
          },
          accountCustomThemes: <String, CustomThemeSettings>{
            workspaceKey: workspaceTheme,
          },
        );
        final service = PreferencesMigrationService(storage);
        storage.seed(
          service.legacyWorkspaceStorageKey(workspaceKey),
          jsonEncode(legacy.toJson()),
        );

        final migrated = await service.readWorkspace(workspaceKey);

        expect(
          migrated,
          WorkspacePreferences.fromLegacy(legacy, workspaceKey: workspaceKey),
        );
        expect(migrated.defaultUseLegacyApi, isFalse);
        expect(migrated.themeColorOverride, AppThemeColor.duskPurple);
        expect(migrated.customThemeOverride?.toJson(), workspaceTheme.toJson());
        expect(migrated.toJson().containsKey('language'), isFalse);

        final rawNew = await storage.read(
          key: service.workspaceStorageKey(workspaceKey),
        );
        expect(rawNew, isNotNull);
        expect(jsonDecode(rawNew!)['homeQuickActionPrimary'], 'explore');
        expect(
          await storage.read(
            key: service.legacyWorkspaceStorageKey(workspaceKey),
          ),
          isNotNull,
        );
      },
    );

    test(
      'falls back to global legacy preferences when workspace data is absent',
      () async {
        final storage = _MemorySecureStorage();
        final legacy = AppPreferences.defaults.copyWith(
          useLegacyApi: false,
          homeQuickActionPrimary: HomeQuickAction.resources,
        );
        storage.seed(
          legacyAppPreferencesGlobalKey,
          jsonEncode(legacy.toJson()),
        );

        final service = PreferencesMigrationService(storage);
        final migrated = await service.readWorkspace('workspace-from-global');

        expect(migrated.defaultUseLegacyApi, isFalse);
        expect(migrated.homeQuickActionPrimary, HomeQuickAction.resources);
        expect(
          await storage.read(key: legacyAppPreferencesGlobalKey),
          isNotNull,
        );
      },
    );

    test(
      'returns defaults and skips writes when workspace key is absent',
      () async {
        final storage = _MemorySecureStorage();
        final service = PreferencesMigrationService(storage);

        expect(
          await service.readWorkspace(null),
          WorkspacePreferences.defaults,
        );

        await service.writeWorkspace(
          null,
          WorkspacePreferences.defaults.copyWith(
            homeQuickActionPrimary: HomeQuickAction.archived,
          ),
        );

        expect(await storage.read(key: devicePreferencesStorageKey), isNull);
        expect(
          await storage.read(
            key: service.workspaceStorageKey('unused-workspace'),
          ),
          isNull,
        );
      },
    );

    test('workspace navigation preferences default when field is absent', () {
      final json = WorkspacePreferences.defaults.toJson()
        ..remove('homeNavigationPreferences');

      final prefs = WorkspacePreferences.fromJson(json);

      expect(
        prefs.homeNavigationPreferences,
        HomeNavigationPreferences.defaults,
      );
    });

    test('workspace navigation preferences survive json round-trip', () {
      const navigationPreferences = HomeNavigationPreferences(
        mode: HomeNavigationMode.bottomBar,
        leftPrimary: HomeRootDestination.memos,
        leftSecondary: HomeRootDestination.dailyReview,
        rightPrimary: HomeRootDestination.settings,
        rightSecondary: HomeRootDestination.archived,
      );
      final prefs = WorkspacePreferences.defaults.copyWith(
        homeNavigationPreferences: navigationPreferences,
      );

      final decoded = WorkspacePreferences.fromJson(prefs.toJson());

      expect(decoded.homeNavigationPreferences.mode, HomeNavigationMode.bottomBar);
      expect(
        decoded.homeNavigationPreferences.leftSecondary,
        HomeRootDestination.dailyReview,
      );
      expect(
        decoded.homeNavigationPreferences.rightSecondary,
        HomeRootDestination.archived,
      );
    });
  });
}
