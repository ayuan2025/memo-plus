import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/updates/update_config.dart';
import 'package:memos_flutter_app/features/updates/update_announcement_dialog.dart';
import 'package:memos_flutter_app/i18n/strings.g.dart';

void main() {
  testWidgets('shows new donor labels in the announcement dialog', (
    WidgetTester tester,
  ) async {
    LocaleSettings.setLocale(AppLocale.en);

    await tester.pumpWidget(
      TranslationProvider(
        child: MaterialApp(
          home: Scaffold(
            body: UpdateAnnouncementDialog(
              currentVersion: '1.0.15',
              config: const UpdateAnnouncementConfig(
                schemaVersion: 2,
                versionInfo: UpdateVersionInfo(
                  latestVersion: '1.0.16',
                  isForce: false,
                  downloadUrl: 'https://example.com/app.apk',
                  updateSource: 'google_play',
                  publishAt: null,
                  debugVersion: '',
                  skipUpdateVersion: '',
                ),
                announcement: UpdateAnnouncement(
                  id: 20260307,
                  title: 'Release Notes',
                  showWhenUpToDate: false,
                  contentsByLocale: {},
                  fallbackContents: [],
                  newDonorIds: ['alice', 'bob'],
                ),
                donors: [
                  UpdateDonor(id: 'alice', name: 'Alice', avatar: ''),
                  UpdateDonor(id: 'bob', name: 'Bob', avatar: ''),
                ],
                releaseNotes: [],
                noticeEnabled: false,
                notice: null,
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('@Alice'), findsOneWidget);
    expect(find.text('@Bob'), findsOneWidget);
    expect(find.text("Don't remind me for this version"), findsOneWidget);
  });
}
