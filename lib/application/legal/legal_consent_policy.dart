import '../../data/models/device_preferences.dart';

abstract final class MemoFlowLegalConsentPolicy {
  static const String privacyPolicyUrl =
      'https://memoflow.hzc073.com/help/privacy-policy';
  static const String termsOfServiceUrl =
      'https://memoflow.hzc073.com/help/terms-of-service';
  static const String requiredSinceAppVersion = '1.0.27';
  static const String currentDocumentsHash = 'memoflow-legal-2026-04-09';

  static bool requiresConsent({
    required DevicePreferences prefs,
    required String currentAppVersion,
  }) {
    final acceptedHash = prefs.acceptedLegalDocumentsHash.trim();
    if (acceptedHash == currentDocumentsHash) {
      return false;
    }
    if (!prefs.hasSelectedLanguage) {
      return true;
    }
    if (acceptedHash.isNotEmpty) {
      return true;
    }
    if (compareVersionTriplets(currentAppVersion, requiredSinceAppVersion) <
        0) {
      return false;
    }
    final lastSeenAppVersion = prefs.lastSeenAppVersion.trim();
    return lastSeenAppVersion.isEmpty ||
        compareVersionTriplets(lastSeenAppVersion, requiredSinceAppVersion) < 0;
  }

  static int compareVersionTriplets(String left, String right) {
    final leftParts = _parseVersionTriplet(left);
    final rightParts = _parseVersionTriplet(right);
    for (var i = 0; i < 3; i++) {
      final diff = leftParts[i].compareTo(rightParts[i]);
      if (diff != 0) {
        return diff;
      }
    }
    return 0;
  }

  static List<int> _parseVersionTriplet(String version) {
    if (version.trim().isEmpty) {
      return const [0, 0, 0];
    }
    final trimmed = version.split(RegExp(r'[-+]')).first;
    final parts = trimmed.split('.');
    final values = <int>[0, 0, 0];
    for (var i = 0; i < 3; i++) {
      if (i >= parts.length) {
        break;
      }
      final match = RegExp(r'\d+').firstMatch(parts[i]);
      if (match == null) {
        continue;
      }
      values[i] = int.tryParse(match.group(0) ?? '') ?? 0;
    }
    return values;
  }
}
