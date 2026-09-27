part of 'startup_coordinator.dart';

class _StartupSnapshot {
  const _StartupSnapshot({
    required this.prefsLoaded,
    required this.settings,
    required this.hasAccount,
    required this.hasWorkspace,
    required this.navigatorReady,
    required this.contextReady,
  });

  final bool prefsLoaded;
  final ResolvedAppSettings settings;
  final bool hasAccount;
  final bool hasWorkspace;
  final bool navigatorReady;
  final bool contextReady;
}

class _StartupSelection {
  const _StartupSelection({required this.action, required this.reason});

  final _StartupAction action;
  final String reason;
}

class _StartupBlockEvaluation {
  const _StartupBlockEvaluation({
    required this.reason,
    required this.shouldRetry,
  });

  final String reason;
  final bool shouldRetry;
}

class _StartupExecutionResult {
  const _StartupExecutionResult({required this.handled, this.blockReason});

  final bool handled;
  final String? blockReason;
}
