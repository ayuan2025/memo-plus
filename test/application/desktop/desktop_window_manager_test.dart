import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/desktop/desktop_quick_input_controller.dart';
import 'package:memos_flutter_app/application/desktop/desktop_window_manager.dart';
import 'package:memos_flutter_app/application/quick_input/quick_input_service.dart';
import 'package:memos_flutter_app/core/desktop_quick_input_channel.dart';
import 'package:memos_flutter_app/data/logs/log_manager.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/data/models/instance_profile.dart';
import 'package:memos_flutter_app/data/models/user.dart';
import 'package:memos_flutter_app/state/memos/app_bootstrap_adapter_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

class _FakeBootstrapAdapter extends AppBootstrapAdapter {
  _FakeBootstrapAdapter({
    required AppSessionState initialSession,
    this.reloadedSession,
  }) : _session = initialSession;

  AppSessionState _session;
  AppSessionState? reloadedSession;
  int reloadSessionCalls = 0;
  int reloadLocalLibrariesCalls = 0;
  final List<String?> setCurrentSessionKeyCalls = <String?>[];

  AppSessionState get session => _session;

  @override
  AppSessionState? readSession(WidgetRef ref) => _session;

  @override
  Future<void> reloadSessionFromStorage(WidgetRef ref) async {
    reloadSessionCalls += 1;
    final next = reloadedSession;
    if (next != null) {
      _session = next;
    }
  }

  @override
  Future<void> reloadLocalLibrariesFromStorage(WidgetRef ref) async {
    reloadLocalLibrariesCalls += 1;
  }

  @override
  Future<void> setCurrentSessionKey(WidgetRef ref, String? key) async {
    setCurrentSessionKeyCalls.add(key);
    _session = AppSessionState(accounts: _session.accounts, currentKey: key);
  }

  @override
  LogManager readLogManager(WidgetRef ref) => LogManager.instance;
}

class _FakeSubWindowClient implements DesktopSubWindowClient {
  Set<int> existingIds = <int>{};
  final Map<int, bool?> visibleByWindowId = <int, bool?>{};
  final Set<int> responsiveSettingsIds = <int>{};
  final Set<int> responsiveQuickInputIds = <int>{};
  final List<int> showCalls = <int>[];
  final List<String> methodCalls = <String>[];

  @override
  Future<Set<int>> getAllSubWindowIds() async {
    return existingIds.toSet();
  }

  @override
  Future<dynamic> invokeMethod(
    int windowId,
    String method, [
    dynamic arguments,
  ]) async {
    methodCalls.add('$windowId:$method');
    return switch (method) {
      desktopSubWindowIsVisibleMethod => visibleByWindowId[windowId],
      desktopSettingsPingMethod => responsiveSettingsIds.contains(windowId),
      desktopQuickInputPingMethod => responsiveQuickInputIds.contains(windowId),
      desktopSettingsFocusMethod => true,
      desktopQuickInputFocusMethod => true,
      _ => true,
    };
  }

  @override
  Future<void> show(int windowId) async {
    showCalls.add(windowId);
  }
}

class _ManagerHarness extends ConsumerStatefulWidget {
  const _ManagerHarness({
    required this.adapter,
    required this.onReady,
    this.onVisibilityChanged,
    this.subWindowClient,
    this.visibilityWatchdogInterval,
  });

  final _FakeBootstrapAdapter adapter;
  final void Function(DesktopWindowManager manager) onReady;
  final VoidCallback? onVisibilityChanged;
  final DesktopSubWindowClient? subWindowClient;
  final Duration? visibilityWatchdogInterval;

  @override
  ConsumerState<_ManagerHarness> createState() => _ManagerHarnessState();
}

class _ManagerHarnessState extends ConsumerState<_ManagerHarness> {
  late final GlobalKey<NavigatorState> _navigatorKey;
  late final DesktopWindowManager _manager;

  @override
  void initState() {
    super.initState();
    _navigatorKey = GlobalKey<NavigatorState>();
    final quickInputController = DesktopQuickInputController(
      bootstrapAdapter: widget.adapter,
      quickInputService: QuickInputService(bootstrapAdapter: widget.adapter),
      ref: ref,
      navigatorKey: _navigatorKey,
      ensureMethodHandlerBound: () {},
      onSubWindowVisibilityChanged:
          ({required int windowId, required bool visible}) {},
      onWindowIdChanged: (_) {},
      onQuickInputRequested: (_) {},
      isMounted: () => mounted,
    );
    _manager = DesktopWindowManager(
      bootstrapAdapter: widget.adapter,
      ref: ref,
      navigatorKey: _navigatorKey,
      quickInputController: quickInputController,
      openQuickInput: ({required bool autoFocus}) async {},
      isMounted: () => mounted,
      onVisibilityChanged: widget.onVisibilityChanged ?? () {},
      subWindowClient: widget.subWindowClient,
      visibilityWatchdogInterval: widget.visibilityWatchdogInterval,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onReady(_manager);
    });
  }

  @override
  void dispose() {
    _manager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      home: const SizedBox.shrink(),
    );
  }
}

Account _buildAccount({required String key}) {
  return Account(
    key: key,
    baseUrl: Uri.parse('http://127.0.0.1:5230'),
    personalAccessToken: 'token',
    user: const User(
      name: 'users/1',
      username: 'tester',
      displayName: 'Tester',
      avatarUrl: '',
      description: '',
    ),
    instanceProfile: const InstanceProfile.empty(),
    useLegacyApiOverride: false,
    serverVersionOverride: '0.24.0',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('workspace reload restores session before applying currentKey', (
    tester,
  ) async {
    final account = _buildAccount(key: 'http://127.0.0.1:5230|users/1');
    final adapter = _FakeBootstrapAdapter(
      initialSession: const AppSessionState(accounts: [], currentKey: null),
      reloadedSession: AppSessionState(
        accounts: <Account>[account],
        currentKey: account.key,
      ),
    );
    final completer = Completer<DesktopWindowManager>();

    await tester.pumpWidget(
      ProviderScope(
        child: _ManagerHarness(adapter: adapter, onReady: completer.complete),
      ),
    );
    await tester.pump();

    final manager = await completer.future;
    final result = await manager.handleMethodCallForTest(
      MethodCall(desktopMainReloadWorkspaceMethod, <String, dynamic>{
        'currentKey': account.key,
      }),
    );

    expect(result, isTrue);
    expect(adapter.reloadSessionCalls, 1);
    expect(adapter.reloadLocalLibrariesCalls, 1);
    expect(adapter.setCurrentSessionKeyCalls, isEmpty);
    expect(adapter.session.currentAccount?.key, account.key);
  });

  testWidgets(
    'workspace reload falls back to key update when reload does not match',
    (tester) async {
      final adapter = _FakeBootstrapAdapter(
        initialSession: const AppSessionState(accounts: [], currentKey: null),
        reloadedSession: const AppSessionState(accounts: [], currentKey: null),
      );
      final completer = Completer<DesktopWindowManager>();

      await tester.pumpWidget(
        ProviderScope(
          child: _ManagerHarness(adapter: adapter, onReady: completer.complete),
        ),
      );
      await tester.pump();

      final manager = await completer.future;
      final result = await manager.handleMethodCallForTest(
        MethodCall(desktopMainReloadWorkspaceMethod, <String, dynamic>{
          'currentKey': 'local-workspace',
        }),
      );

      expect(result, isTrue);
      expect(adapter.reloadSessionCalls, 1);
      expect(adapter.reloadLocalLibrariesCalls, 1);
      expect(adapter.setCurrentSessionKeyCalls, <String?>['local-workspace']);
    },
  );

  testWidgets('quick input idle prewarm arms once and completes after idle', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final adapter = _FakeBootstrapAdapter(
      initialSession: const AppSessionState(accounts: [], currentKey: null),
    );
    final completer = Completer<DesktopWindowManager>();

    await tester.pumpWidget(
      ProviderScope(
        child: _ManagerHarness(adapter: adapter, onReady: completer.complete),
      ),
    );
    await tester.pump();

    final manager = await completer.future;
    manager.scheduleQuickInputIdlePrewarmOnce();

    expect(manager.quickInputIdlePrewarmArmedForTest, isTrue);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isFalse);

    manager.notifyUserInteraction(source: 'pointer_down');
    await tester.pump(const Duration(seconds: 1));
    expect(manager.quickInputIdlePrewarmArmedForTest, isTrue);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isFalse);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump();

    expect(manager.quickInputIdlePrewarmArmedForTest, isFalse);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('explicit quick input open skips future idle prewarm', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    final adapter = _FakeBootstrapAdapter(
      initialSession: const AppSessionState(accounts: [], currentKey: null),
    );
    final completer = Completer<DesktopWindowManager>();

    await tester.pumpWidget(
      ProviderScope(
        child: _ManagerHarness(adapter: adapter, onReady: completer.complete),
      ),
    );
    await tester.pump();

    final manager = await completer.future;
    manager.scheduleQuickInputIdlePrewarmOnce();
    manager.markQuickInputWarmPathUsed(source: 'explicit_open');

    expect(manager.quickInputIdlePrewarmArmedForTest, isFalse);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isTrue);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    manager.scheduleQuickInputIdlePrewarmOnce();
    expect(manager.quickInputIdlePrewarmArmedForTest, isFalse);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isTrue);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('quick input idle prewarm stays disabled outside windows', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final adapter = _FakeBootstrapAdapter(
      initialSession: const AppSessionState(accounts: [], currentKey: null),
    );
    final completer = Completer<DesktopWindowManager>();

    await tester.pumpWidget(
      ProviderScope(
        child: _ManagerHarness(adapter: adapter, onReady: completer.complete),
      ),
    );
    await tester.pump();

    final manager = await completer.future;
    manager.scheduleQuickInputIdlePrewarmOnce();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(manager.quickInputIdlePrewarmArmedForTest, isFalse);
    expect(manager.quickInputIdlePrewarmCompletedForTest, isFalse);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'visibility sync clears blur when tracked sub-window disappears',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final adapter = _FakeBootstrapAdapter(
        initialSession: const AppSessionState(accounts: [], currentKey: null),
      );
      final subWindowClient = _FakeSubWindowClient()
        ..existingIds = <int>{7}
        ..visibleByWindowId[7] = true;
      var visibilityChanges = 0;
      final completer = Completer<DesktopWindowManager>();

      await tester.pumpWidget(
        ProviderScope(
          child: _ManagerHarness(
            adapter: adapter,
            onReady: completer.complete,
            subWindowClient: subWindowClient,
            onVisibilityChanged: () => visibilityChanges += 1,
          ),
        ),
      );
      await tester.pump();

      final manager = await completer.future;
      manager.setSubWindowVisibility(windowId: 7, visible: true);

      expect(manager.shouldBlurMainWindow, isTrue);
      expect(manager.visibleSubWindowIdsForTest, <int>{7});

      subWindowClient.existingIds = <int>{};
      await manager.syncDesktopSubWindowVisibilityForTest();

      expect(manager.shouldBlurMainWindow, isFalse);
      expect(manager.visibleSubWindowIdsForTest, isEmpty);
      expect(visibilityChanges, 2);
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('visibility watchdog clears stale blur without another build', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final adapter = _FakeBootstrapAdapter(
      initialSession: const AppSessionState(accounts: [], currentKey: null),
    );
    final subWindowClient = _FakeSubWindowClient()
      ..existingIds = <int>{7}
      ..visibleByWindowId[7] = true;
    final completer = Completer<DesktopWindowManager>();

    await tester.pumpWidget(
      ProviderScope(
        child: _ManagerHarness(
          adapter: adapter,
          onReady: completer.complete,
          subWindowClient: subWindowClient,
          visibilityWatchdogInterval: const Duration(milliseconds: 10),
        ),
      ),
    );
    await tester.pump();

    final manager = await completer.future;
    manager.setSubWindowVisibility(windowId: 7, visible: true);
    await tester.pump();

    expect(manager.shouldBlurMainWindow, isTrue);

    subWindowClient.existingIds = <int>{};
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pump();

    expect(manager.shouldBlurMainWindow, isFalse);
    expect(manager.visibleSubWindowIdsForTest, isEmpty);
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'blur overlay focus clears hidden sub-window without showing it',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final adapter = _FakeBootstrapAdapter(
        initialSession: const AppSessionState(accounts: [], currentKey: null),
      );
      final subWindowClient = _FakeSubWindowClient()
        ..existingIds = <int>{7}
        ..visibleByWindowId[7] = false;
      final completer = Completer<DesktopWindowManager>();

      await tester.pumpWidget(
        ProviderScope(
          child: _ManagerHarness(
            adapter: adapter,
            onReady: completer.complete,
            subWindowClient: subWindowClient,
          ),
        ),
      );
      await tester.pump();

      final manager = await completer.future;
      manager.setSubWindowVisibility(windowId: 7, visible: true);
      expect(manager.shouldBlurMainWindow, isTrue);

      await manager.focusVisibleSubWindow();

      expect(manager.shouldBlurMainWindow, isFalse);
      expect(manager.visibleSubWindowIdsForTest, isEmpty);
      expect(subWindowClient.showCalls, isEmpty);
      expect(
        subWindowClient.methodCalls,
        isNot(contains('7:$desktopSettingsFocusMethod')),
      );
      expect(
        subWindowClient.methodCalls,
        isNot(contains('7:$desktopQuickInputFocusMethod')),
      );
      debugDefaultTargetPlatformOverride = null;
    },
  );
}
