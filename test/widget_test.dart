import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/legal/legal_consent_policy.dart';
import 'package:memos_flutter_app/core/storage_read.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/features/legal/legal_consent_gate.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';
import 'package:memos_flutter_app/state/settings/device_preferences_provider.dart';
import 'package:memos_flutter_app/state/settings/preferences_migration_service.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'MemoFlow',
      packageName: 'com.example.memoflow',
      version: '1.0.27',
      buildNumber: '27',
      buildSignature: '',
    );
  });

  testWidgets('LegalConsentGate blocks access when consent is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        prefs: DevicePreferences.defaultsForLanguage(
          AppLanguage.en,
        ).copyWith(onboardingMode: null),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Review agreements'), findsOneWidget);
    expect(find.text('allowed'), findsNothing);
  });

  testWidgets('LegalConsentGate allows access after consent is persisted', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        prefs: DevicePreferences.defaultsForLanguage(AppLanguage.en).copyWith(
          onboardingMode: null,
          acceptedLegalDocumentsHash:
              MemoFlowLegalConsentPolicy.currentDocumentsHash,
          acceptedLegalDocumentsAt: '2026-04-09T00:00:00.000Z',
        ),
      ),
    );

    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('allowed'), findsOneWidget);
    expect(find.text('Review agreements'), findsNothing);
  });
}

Widget _buildTestApp({required DevicePreferences prefs}) {
  LocaleSettings.setLocale(AppLocale.en);
  return ProviderScope(
    overrides: [
      devicePreferencesProvider.overrideWith(
        (ref) => _TestDevicePreferencesController(ref, prefs),
      ),
    ],
    child: TranslationProvider(
      child: MaterialApp(
        locale: AppLocale.en.flutterLocale,
        supportedLocales: AppLocaleUtils.supportedLocales,
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: LegalConsentGate(
          placeholder: const SizedBox.shrink(),
          child: const Text('allowed'),
        ),
      ),
    ),
  );
}

class _TestDevicePreferencesRepository extends DevicePreferencesRepository {
  _TestDevicePreferencesRepository(this._stored)
    : super(PreferencesMigrationService(const FlutterSecureStorage()));

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
  _TestDevicePreferencesController(Ref ref, DevicePreferences initial)
    : super(
        ref,
        _TestDevicePreferencesRepository(initial),
        onLoaded: () {
          ref.read(devicePreferencesLoadedProvider.notifier).state = true;
        },
      );
}
