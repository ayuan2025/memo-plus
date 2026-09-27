import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/models/location_settings.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/data/repositories/location_settings_repository.dart';
import 'package:memos_flutter_app/features/location_picker/show_location_picker.dart';
import 'package:memos_flutter_app/state/settings/location_settings_provider.dart';

import '../settings/settings_test_harness.dart';

void main() {
  testWidgets('provider-not-ready prompt delegates settings navigation', (
    tester,
  ) async {
    final openerCalled = Completer<void>();
    MemoLocation? result;

    await tester.pumpWidget(
      buildSettingsTestApp(
        overrides: [
          locationSettingsRepositoryProvider.overrideWith(
            (_) => _FakeLocationSettingsRepository(LocationSettings.defaults),
          ),
        ],
        home: Consumer(
          builder: (context, ref, _) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () async {
                    result = await showLocationPickerSheetOrDialog(
                      context: context,
                      ref: ref,
                      openLocationSettings: (_) async {
                        if (!openerCalled.isCompleted) {
                          openerCalled.complete();
                        }
                      },
                    );
                  },
                  child: const Text('Pick location'),
                ),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Pick location'));
    await tester.pumpAndSettle();

    expect(find.text('Select location'), findsOneWidget);
    expect(
      find.text('Location is disabled. Enable it in settings first.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    await openerCalled.future.timeout(const Duration(seconds: 1));

    expect(result, isNull);
  });
}

class _FakeLocationSettingsRepository extends LocationSettingsRepository {
  _FakeLocationSettingsRepository(this._settings)
    : super(const FlutterSecureStorage(), accountKey: 'test-location-picker');

  LocationSettings _settings;

  @override
  Future<LocationSettings> read() async => _settings;

  @override
  Future<void> write(LocationSettings settings) async {
    _settings = settings;
  }

  @override
  Future<void> clear() async {
    _settings = LocationSettings.defaults;
  }
}
