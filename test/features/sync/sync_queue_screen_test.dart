import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/sync/sync_coordinator.dart';
import 'package:memos_flutter_app/application/sync/sync_request.dart';
import 'package:memos_flutter_app/application/sync/sync_types.dart';
import 'package:memos_flutter_app/data/logs/sync_queue_progress_tracker.dart';
import 'package:memos_flutter_app/data/logs/sync_status_tracker.dart';
import 'package:memos_flutter_app/data/models/account.dart';
import 'package:memos_flutter_app/features/home/home_navigation_host.dart';
import 'package:memos_flutter_app/features/sync/sync_queue_screen.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_models.dart';
import 'package:memos_flutter_app/state/memos/sync_queue_provider.dart';
import 'package:memos_flutter_app/state/sync/memo_sync_service.dart';
import 'package:memos_flutter_app/state/sync/sync_coordinator_provider.dart';
import 'package:memos_flutter_app/state/system/logging_provider.dart';
import 'package:memos_flutter_app/state/system/session_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
  });

  testWidgets('desktop embedded sync queue has local back action', (
    tester,
  ) async {
    var backCount = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appSessionProvider.overrideWith((ref) => _TestSessionController()),
          syncQueueItemsProvider.overrideWith(
            (ref) => Stream.value(const <SyncQueueItem>[]),
          ),
          syncQueueAttentionItemsProvider.overrideWith(
            (ref) => Stream.value(const <SyncQueueItem>[]),
          ),
          syncQueuePendingCountProvider.overrideWith((ref) => Stream.value(0)),
          syncQueueAttentionCountProvider.overrideWith(
            (ref) => Stream.value(0),
          ),
          syncQueueProgressTrackerProvider.overrideWith(
            (ref) => SyncQueueProgressTracker(),
          ),
          syncStatusTrackerProvider.overrideWith((ref) => SyncStatusTracker()),
          syncCoordinatorProvider.overrideWith(
            (ref) => _TestDesktopSyncFacade(),
          ),
          memoBridgeServiceProvider.overrideWith((ref) => null),
        ],
        child: TranslationProvider(
          child: MaterialApp(
            locale: AppLocale.en.flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(platform: TargetPlatform.macOS),
            home: MediaQuery(
              data: const MediaQueryData(size: Size(900, 700)),
              child: SyncQueueScreen(
                presentation: HomeScreenPresentation.desktopEmbedded,
                onDesktopEmbeddedBack: () => backCount++,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sync queue'), findsOneWidget);
    expect(find.byType(AppBar), findsNothing);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(backCount, 1);
  });
}

class _TestSessionController extends AppSessionController {
  _TestSessionController()
    : super(
        const AsyncValue.data(
          AppSessionState(accounts: <Account>[], currentKey: null),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _TestDesktopSyncFacade extends DesktopSyncFacade {
  _TestDesktopSyncFacade() : super(SyncCoordinatorState.initial);

  @override
  Future<SyncRunResult> requestSync(SyncRequest request) async {
    return const SyncRunStarted();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
