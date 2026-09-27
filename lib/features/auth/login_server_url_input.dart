import 'package:flutter/services.dart';

class LoginServerUrlDraft {
  const LoginServerUrlDraft({required this.useHttps, required this.suffix});

  final bool useHttps;
  final String suffix;
}

String normalizeLoginServerUrlInput(String raw) {
  return raw.trim().replaceAll('\uFF1A', ':');
}

String normalizeLoginServerUrlSuffix(String raw) {
  return normalizeLoginServerUrlInput(
    raw,
  ).replaceFirst(RegExp(r'^(?:https?:)?//', caseSensitive: false), '');
}

String loginServerUrlSuffixFromUri(Uri uri) {
  final buffer = StringBuffer();
  if (uri.authority.isNotEmpty) {
    buffer.write(uri.authority);
  }
  if (uri.path.isNotEmpty && uri.path != '/') {
    buffer.write(uri.path);
  }
  return buffer.toString();
}

String composeLoginServerBaseUrl({
  required bool useHttps,
  required String rawSuffix,
}) {
  final suffix = normalizeLoginServerUrlSuffix(rawSuffix);
  if (suffix.isEmpty) return '';
  final scheme = useHttps ? 'https' : 'http';
  return '$scheme://$suffix';
}

LoginServerUrlDraft restoreLoginServerUrlDraft(String draft) {
  final normalized = normalizeLoginServerUrlInput(draft);
  if (normalized.isEmpty) {
    return const LoginServerUrlDraft(useHttps: true, suffix: '');
  }

  final parsed = Uri.tryParse(normalized);
  if (parsed != null && parsed.hasScheme && parsed.hasAuthority) {
    return LoginServerUrlDraft(
      useHttps: parsed.scheme.toLowerCase() != 'http',
      suffix: loginServerUrlSuffixFromUri(parsed),
    );
  }

  return LoginServerUrlDraft(
    useHttps: true,
    suffix: normalizeLoginServerUrlSuffix(normalized),
  );
}

class LoginServerUrlTextInputFormatter extends TextInputFormatter {
  const LoginServerUrlTextInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final normalized = newValue.text.replaceAll('\uFF1A', ':');
    if (normalized == newValue.text) return newValue;
    return newValue.copyWith(text: normalized);
  }
}
