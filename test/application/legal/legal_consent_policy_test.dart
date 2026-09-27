import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/legal/legal_consent_policy.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';

void main() {
  group('MemoFlowLegalConsentPolicy', () {
    test('requires consent for first-run users', () {
      final prefs = DevicePreferences.defaults;

      final result = MemoFlowLegalConsentPolicy.requiresConsent(
        prefs: prefs,
        currentAppVersion: MemoFlowLegalConsentPolicy.requiredSinceAppVersion,
      );

      expect(result, isTrue);
    });

    test('requires consent when upgrading across required version', () {
      final prefs = DevicePreferences.defaults.copyWith(
        hasSelectedLanguage: true,
        lastSeenAppVersion: '1.0.26',
      );

      final result = MemoFlowLegalConsentPolicy.requiresConsent(
        prefs: prefs,
        currentAppVersion: '1.0.27',
      );

      expect(result, isTrue);
    });

    test('does not require consent after current hash is accepted', () {
      final prefs = DevicePreferences.defaults.copyWith(
        hasSelectedLanguage: true,
        lastSeenAppVersion: '1.0.27',
        acceptedLegalDocumentsHash:
            MemoFlowLegalConsentPolicy.currentDocumentsHash,
      );

      final result = MemoFlowLegalConsentPolicy.requiresConsent(
        prefs: prefs,
        currentAppVersion: '1.0.27',
      );

      expect(result, isFalse);
    });

    test('requires consent again when documents hash changes', () {
      final prefs = DevicePreferences.defaults.copyWith(
        hasSelectedLanguage: true,
        lastSeenAppVersion: '1.0.27',
        acceptedLegalDocumentsHash: 'older-legal-hash',
      );

      final result = MemoFlowLegalConsentPolicy.requiresConsent(
        prefs: prefs,
        currentAppVersion: '1.0.28',
      );

      expect(result, isTrue);
    });
  });
}
