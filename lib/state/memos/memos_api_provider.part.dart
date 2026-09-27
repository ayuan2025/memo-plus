part of 'memos_providers.dart';

final memosApiProvider = Provider<MemosApi>((ref) {
  final authContext = ref.watch(
    appSessionProvider.select(_currentAccountAuthContext),
  );
  if (authContext == null) {
    throw StateError('Not authenticated');
  }
  final account = ref.read(appSessionProvider).valueOrNull?.currentAccount;
  if (account == null) {
    throw StateError('Not authenticated');
  }
  final sessionController = ref.read(appSessionProvider.notifier);
  final effectiveVersion = sessionController
      .resolveEffectiveServerVersionForAccount(account: account);
  final parsedVersion = parseMemoApiVersion(effectiveVersion);
  if (parsedVersion == null) {
    throw StateError(
      'No fixed API version selected for current account. Please select API version manually.',
    );
  }
  final logStore = ref.watch(networkLogStoreProvider);
  final logBuffer = ref.watch(networkLogBufferProvider);
  final breadcrumbStore = ref.watch(breadcrumbStoreProvider);
  final logManager = ref.watch(logManagerProvider);
  return MemoApiFacade.authenticated(
    baseUrl: account.baseUrl,
    personalAccessToken: account.personalAccessToken,
    version: parsedVersion,
    logStore: logStore,
    logBuffer: logBuffer,
    breadcrumbStore: breadcrumbStore,
    logManager: logManager,
  );
});
