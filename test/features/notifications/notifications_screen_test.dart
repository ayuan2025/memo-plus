import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/models/home_navigation_preferences.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/notification_item.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/data/models/workspace_preferences.dart';
import 'package:memos_flutter_app/features/home/app_drawer.dart';
import 'package:memos_flutter_app/features/home/home_entry_screen.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/notifications/notifications_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_provider.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:memos_flutter_app/state/settings/workspace_preferences_provider.dart';
import 'package:memos_flutter_app/state/system/notifications_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    HomeEntryScreen.debugClassicScreenBuilderOverride = (_) =>
        const Text('classic-home');
    HomeEntryScreen.debugBottomNavShellBuilderOverride = (_) =>
        const Text('bottom-nav-shell');
  });

  tearDown(() {
    HomeEntryScreen.debugClassicScreenBuilderOverride = null;
    HomeEntryScreen.debugBottomNavShellBuilderOverride = null;
  });

  testWidgets('embedded notifications back delegates to host', (tester) async {
    final host = _RecordingEmbeddedNavigationHost();

    await tester.pumpWidget(
      _buildApp(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: false),
          ),
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(ref),
          ),
          currentWorkspacePreferencesProvider.overrideWith(
            (ref) => _TestWorkspacePreferencesController(
              ref,
              initial: WorkspacePreferences.defaults,
            ),
          ),
          workspacePreferencesLoadedProvider.overrideWith((ref) => true),
          notificationsProvider.overrideWith(
            (ref) async => const <AppNotification>[],
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        home: MediaQuery(
          data: const MediaQueryData(size: Size(430, 900)),
          child: NotificationsScreen(
            presentation: HomeScreenPresentation.embeddedBottomNav,
            embeddedNavigationHost: host,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(host.backToPrimaryCount, 1);
    expect(find.text('classic-home'), findsNothing);
    expect(find.text('bottom-nav-shell'), findsNothing);
  });

  testWidgets('standalone notifications back returns to HomeEntryScreen', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildApp(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: false),
          ),
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(ref),
          ),
          currentWorkspacePreferencesProvider.overrideWith(
            (ref) => _TestWorkspacePreferencesController(
              ref,
              initial: WorkspacePreferences.defaults.copyWith(
                homeNavigationPreferences: HomeNavigationPreferences.defaults
                    .copyWith(mode: HomeNavigationMode.bottomBar),
              ),
            ),
          ),
          workspacePreferencesLoadedProvider.overrideWith((ref) => true),
          notificationsProvider.overrideWith(
            (ref) async => const <AppNotification>[],
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        home: const MediaQuery(
          data: MediaQueryData(size: Size(430, 900)),
          child: NotificationsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('bottom-nav-shell'), findsOneWidget);
    expect(find.text('classic-home'), findsNothing);
  });

  testWidgets('desktop embedded notifications render without page app bar', (
    tester,
  ) async {
    var backCount = 0;

    await tester.pumpWidget(
      _buildApp(
        overrides: [
          appSessionProvider.overrideWith(
            (ref) => _TestSessionController(hasAccount: true),
          ),
          devicePreferencesProvider.overrideWith(
            (ref) => _TestDevicePreferencesController(ref),
          ),
          currentWorkspacePreferencesProvider.overrideWith(
            (ref) => _TestWorkspacePreferencesController(
              ref,
              initial: WorkspacePreferences.defaults,
            ),
          ),
          workspacePreferencesLoadedProvider.overrideWith((ref) => true),
          notificationsProvider.overrideWith(
            (ref) async => const <AppNotification>[],
          ),
          unreadNotificationCountProvider.overrideWith((ref) => 0),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
        ],
        home: MediaQuery(
          data: const MediaQueryData(size: Size(900, 700)),
          child: NotificationsScreen(
            presentation: HomeScreenPresentation.desktopEmbedded,
            onDesktopEmbeddedBack: () => backCount++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(backCount, 1);
  });
}

Widget _buildApp({required List<Override> overrides, required Widget home}) {
  return ProviderScope(
    overrides: overrides,
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: home,
      ),
    ),
  );
}

class _RecordingEmbeddedNavigationHost implements HomeEmbeddedNavigationHost {
  int backToPrimaryCount = 0;

  @override
  void handleBackToPrimaryDestination(BuildContext context) {
    backToPrimaryCount++;
  }

  @override
  void handleDrawerDestination(
    BuildContext context,
    AppDrawerDestination destination,
  ) {}

  @override
  void handleDrawerTag(BuildContext context, String tag) {}

  @override
  void handleOpenNotifications(BuildContext context) {}

  @override
  void updateGlobalSwipeExclusionRects(
    HomeRootDestination destination,
    List<Rect> rects,
  ) {}

  @override
  void clearGlobalSwipeExclusionRects(HomeRootDestination destination) {}
}

class _TestSessionController extends AppSessionController {
  _TestSessionController({required bool hasAccount})
    : super(
        AsyncValue.data(
          AppSessionState(
            accounts: hasAccount ? [_testAccount] : const <Account>[],
            currentKey: hasAccount ? _testAccountKey : null,
          ),
        ),
      );

  @override
  Future<void> addAccountWithPat({
    required Uri baseUrl,
    required String personalAccessToken,
    bool? useLegacyApiOverride,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> addAccountWithPassword({
    required Uri baseUrl,
    required String username,
    required String password,
    required bool useLegacyApi,
    String? serverVersionOverride,
  }) async {}

  @override
  Future<void> removeAccount(String accountKey) async {}

  @override
  Future<void> switchAccount(String accountKey) async {}

  @override
  Future<void> setCurrentKey(String? key) async {}

  @override
  Future<void> switchWorkspace(String workspaceKey) async {}

  @override
  Future<void> refreshCurrentUser({bool ignoreErrors = true}) async {}

  @override
  Future<void> reloadFromStorage() async {}

  @override
  bool resolveUseLegacyApiForAccount({
    required Account account,
    required bool globalDefault,
  }) => globalDefault;

  @override
  InstanceProfile resolveEffectiveInstanceProfileForAccount({
    required Account account,
  }) => account.instanceProfile;

  @override
  String resolveEffectiveServerVersionForAccount({required Account account}) =>
      account.serverVersionOverride ?? account.instanceProfile.version;

  @override
  Future<void> setCurrentAccountUseLegacyApiOverride(bool value) async {}

  @override
  Future<void> setCurrentAccountServerVersionOverride(String? version) async {}

  @override
  Future<InstanceProfile> detectCurrentAccountInstanceProfile() async {
    return const InstanceProfile.empty();
  }
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository()
    : _stored = DevicePreferences.defaultsForLanguage(AppLanguage.en),
      super(PreferencesMigrationService(const FlutterSecureStorage()));

  DevicePreferences _stored;

  @override
  Future<StorageReadResult<DevicePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<DevicePreferences> read() async {
    return _stored;
  }

  @override
  Future<void> write(DevicePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestDevicePreferencesController extends DevicePreferencesController {
  _TestDevicePreferencesController(Ref ref)
    : super(ref, _TestDevicePreferencesRepository()) {
    state = DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }
}

class _TestWorkspacePreferencesRepository
    extends WorkspacePreferencesRepository {
  _TestWorkspacePreferencesRepository(this._stored)
    : super(
        PreferencesMigrationService(const FlutterSecureStorage()),
        workspaceKey: 'test-workspace',
      );

  WorkspacePreferences _stored;

  @override
  Future<StorageReadResult<WorkspacePreferences>> readWithStatus() async {
    return StorageReadResult.success(_stored);
  }

  @override
  Future<WorkspacePreferences> read() async {
    return _stored;
  }

  @override
  Future<void> write(WorkspacePreferences prefs) async {
    _stored = prefs;
  }
}

class _TestWorkspacePreferencesController
    extends WorkspacePreferencesController {
  _TestWorkspacePreferencesController(
    Ref ref, {
    required WorkspacePreferences initial,
  }) : super(ref, _TestWorkspacePreferencesRepository(initial)) {
    state = initial;
  }
}

const _testAccountKey = 'account-1';
final _testAccount = Account(
  key: _testAccountKey,
  baseUrl: Uri.parse('https://example.com'),
  personalAccessToken: 'token',
  user: User.empty(),
  instanceProfile: InstanceProfile.empty(),
);
