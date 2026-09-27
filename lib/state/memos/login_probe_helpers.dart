part of 'login_provider.dart';

class LoginApiVersion {
  LoginApiVersion._(this._value);

  final MemoApiVersion _value;

  String get versionString => _value.versionString;
  bool get isV023 => _value == MemoApiVersion.v023;
  bool get isV025 => _value == MemoApiVersion.v025;
}

class LoginProbeCleanup {
  const LoginProbeCleanup({
    required this.hasPending,
    this.attachmentName,
    this.memoUid,
  });

  final bool hasPending;
  final String? attachmentName;
  final String? memoUid;
}

class LoginProbeReport {
  const LoginProbeReport({
    required this.passed,
    required this.diagnostics,
    required this.cleanup,
  });

  final bool passed;
  final String diagnostics;
  final LoginProbeCleanup cleanup;
}