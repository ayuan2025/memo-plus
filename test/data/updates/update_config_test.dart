import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/updates/update_config.dart';

void main() {
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('UpdateAnnouncementConfig.fromJson', () {
    test('reads schema v2 platform-scoped version info', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 2,
        'version_info': {
          'android': {
            'latest_version': '1.1.0',
            'force_update': false,
            'update_source': 'google_play',
            'url':
                'https://play.google.com/store/apps/details?id=com.memoflow.hzc073',
            'publish_at': '2026-03-01T00:00:00Z',
          },
          'windows': {
            'latest_version': '1.0.8',
            'force_update': true,
            'update_source': 'windows_installer',
            'url': 'https://example.com/windows.exe',
          },
        },
        'announcement': {
          'id': 2026030101,
          'title': 'Release Notes',
          'show_when_up_to_date': false,
          'contents': {
            'zh': ['new feature'],
          },
        },
      });

      expect(config.schemaVersion, 2);
      expect(config.versionInfo.latestVersion, '1.1.0');
      expect(config.versionInfo.isForce, isFalse);
      expect(
        config.versionInfo.downloadUrl,
        'https://play.google.com/store/apps/details?id=com.memoflow.hzc073',
      );
      expect(config.versionInfo.updateSource, 'google_play');
      expect(
        config.versionInfo.publishAt,
        DateTime.parse('2026-03-01T00:00:00Z').toUtc(),
      );
      expect(config.announcement.showWhenUpToDate, isFalse);
    });

    test('uses platform-specific block for windows', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 2,
        'version_info': {
          'android': {
            'latest_version': '1.1.0',
            'force_update': false,
            'url': 'https://example.com/android.apk',
          },
          'windows': {
            'latest_version': '1.1.1',
            'force_update': true,
            'update_source': 'windows_installer',
            'url': 'https://example.com/windows.exe',
          },
        },
        'announcement': {
          'id': 2026030102,
          'title': 'Release',
          'contents': {
            'en': ['Update available'],
          },
        },
      });

      expect(config.versionInfo.latestVersion, '1.1.1');
      expect(config.versionInfo.isForce, isTrue);
      expect(config.versionInfo.updateSource, 'windows_installer');
      expect(config.versionInfo.downloadUrl, 'https://example.com/windows.exe');
      expect(config.announcement.showWhenUpToDate, isFalse);
    });

    test('keeps legacy version_info fields working', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      final config = UpdateAnnouncementConfig.fromJson({
        'version_info': {
          'latest_version': '1.0.14',
          'is_force': true,
          'download_url': 'https://example.com/app-release.apk',
          'skip_update_version': '1.0.13',
          'debug_version': '999.0',
        },
        'announcement': {
          'id': 1,
          'title': 'Title',
          'showWhenUpToDate': true,
          'contents': ['line1'],
        },
      });

      expect(config.schemaVersion, 1);
      expect(config.versionInfo.latestVersion, '1.0.14');
      expect(config.versionInfo.isForce, isTrue);
      expect(
        config.versionInfo.downloadUrl,
        'https://example.com/app-release.apk',
      );
      expect(config.versionInfo.skipUpdateVersion, '1.0.13');
      expect(config.versionInfo.debugVersion, '999.0');
      expect(config.announcement.showWhenUpToDate, isTrue);
    });

    test('parses multilingual release note item contents', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'version_info': {'latest_version': '1.0.16'},
        'announcement': {
          'id': 20260221,
          'title': 'Release',
          'contents': {
            'en': ['Summary'],
          },
        },
        'release_notes': [
          {
            'version': '1.0.16',
            'date': '2026-02-21',
            'items': [
              {
                'category': 'feature',
                'contents': {
                  'zh': ['新增功能A', '新增功能B'],
                  'en': ['Added feature A', 'Added feature B'],
                },
              },
            ],
          },
        ],
      });

      expect(config.releaseNotes, hasLength(1));
      final entry = config.releaseNotes.first;
      expect(entry.items, hasLength(2));
      expect(entry.items.first.localizedContents['zh'], '新增功能A');
      expect(entry.items.first.localizedContents['en'], 'Added feature A');
      expect(entry.items.first.contentForLanguageCode('de'), 'Added feature A');
      expect(entry.items.last.contentForLanguageCode('zh-CN'), '新增功能B');
    });

    test('parses schema v3 notice candidates', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'locale': 'pt-BR',
        'fallback_locale': 'en',
        'notices': [
          {
            'id': 'notice-2026-05-maintenance',
            'revision': 2,
            'status': 'public',
            'priority': 50,
            'severity': 'critical',
            'publish_at': '2026-05-10T00:00:00Z',
            'expire_at': '2026-05-12T00:00:00Z',
            'audience': {
              'platforms': ['android'],
              'channels': ['full'],
              'min_app_version': '1.0.0',
              'max_app_version': '1.9.9',
            },
            'display': {
              'surface': 'startup_dialog',
              'dismiss_policy': 'once_per_revision',
              'blocking': true,
            },
            'content': {
              'title': {'en': 'Maintenance'},
              'body': {
                'en': ['Line one', 'Line two'],
              },
            },
          },
        ],
      });

      expect(config.schemaVersion, 3);
      expect(config.locale, 'pt-BR');
      expect(config.fallbackLocale, 'en');
      expect(config.noticeCandidates, hasLength(1));
      final notice = config.noticeCandidates.single;
      expect(notice.id, 'notice-2026-05-maintenance');
      expect(notice.revision, 2);
      expect(notice.status, AnnouncementDeliveryStatus.public);
      expect(notice.priority, 50);
      expect(notice.severity, AnnouncementSeverity.critical);
      expect(notice.audience.platforms, {'android'});
      expect(notice.audience.channels, {'full'});
      expect(notice.audience.minAppVersion, '1.0.0');
      expect(notice.audience.maxAppVersion, '1.9.9');
      expect(
        notice.display.dismissPolicy,
        AnnouncementDismissPolicy.oncePerRevision,
      );
      expect(notice.display.blocking, isTrue);
      expect(notice.titleForLanguageCode('en'), 'Maintenance');
      expect(notice.contentsForLanguageCode('de'), ['Line one', 'Line two']);
    });

    test('uses English fallback before unrelated localized content', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'announcement': {
          'id': 20260511,
          'title': 'Release',
          'contents': {
            'zh': ['Chinese summary'],
            'en': ['English summary'],
          },
        },
        'notice': {
          'title': 'Notice',
          'contents': {
            'zh': ['Chinese notice'],
            'en': ['English notice'],
          },
        },
      });

      expect(config.announcement.contentsForLanguageCode('de'), [
        'English summary',
      ]);
      expect(config.notice?.contentsForLanguageCode('de'), ['English notice']);
    });

    test('missing English fallback does not use arbitrary locale content', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'locale': 'de',
        'fallback_locale': 'en',
        'announcement': {
          'id': 20260511,
          'title': 'Release',
          'contents': {
            'zh': ['Chinese summary'],
          },
        },
        'notices': [
          {
            'id': 'notice-de',
            'status': 'public',
            'content': {
              'title': {'zh': '中文通知'},
              'body': {
                'zh': ['中文正文'],
              },
            },
          },
        ],
      });

      expect(config.announcement.contentsForLanguageCode('de'), isEmpty);
      expect(
        config.noticeCandidates.single.contentsForLanguageCode('de'),
        isEmpty,
      );
      expect(
        config.noticeCandidates.single.titleForLanguageCode('de'),
        isEmpty,
      );
    });

    test('parses schema v3 update candidates', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'updates': [
          {
            'id': 'update-1.0.17-android-full',
            'status': 'public',
            'priority': 80,
            'platform': 'android',
            'channel': 'full',
            'version': '1.0.17',
            'force': true,
            'download_url': 'https://example.com/app.apk',
            'release_note_id': 'release-1.0.17',
            'publish_at': '2026-05-10T00:00:00Z',
          },
        ],
      });

      expect(config.updateCandidates, hasLength(1));
      final update = config.updateCandidates.single;
      expect(update.id, 'update-1.0.17-android-full');
      expect(update.status, AnnouncementDeliveryStatus.public);
      expect(update.priority, 80);
      expect(update.platform, 'android');
      expect(update.channel, 'full');
      expect(update.version, '1.0.17');
      expect(update.force, isTrue);
      expect(update.downloadUrl, 'https://example.com/app.apk');
      expect(update.releaseNoteId, 'release-1.0.17');
    });

    test('keeps legacy fields when schema v3 candidates are present', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'version_info': {'latest_version': '1.0.16'},
        'notice_enabled': true,
        'notice': {
          'title': 'Legacy notice',
          'contents': ['Legacy body'],
        },
        'notices': [
          {
            'id': 'notice-v3',
            'status': 'public',
            'content': {
              'title': {'en': 'V3 notice'},
              'body': {
                'en': ['V3 body'],
              },
            },
          },
        ],
      });

      expect(config.versionInfo.latestVersion, '1.0.16');
      expect(config.noticeEnabled, isTrue);
      expect(config.notice?.title, 'Legacy notice');
      expect(config.noticeCandidates.single.id, 'notice-v3');
    });

    test('tolerates malformed optional schema v3 fields', () {
      final config = UpdateAnnouncementConfig.fromJson({
        'schema_version': 3,
        'notices': [
          {
            'id': 'notice-minimal',
            'status': 'not-a-status',
            'audience': {'platforms': 'android'},
            'display': {'dismiss_policy': 'not-a-policy'},
            'content': {'body': 'Fallback body'},
          },
          {
            'status': 'public',
            'content': {'body': 'Missing id'},
          },
        ],
      });

      expect(config.noticeCandidates, hasLength(1));
      final notice = config.noticeCandidates.single;
      expect(notice.id, 'notice-minimal');
      expect(notice.status, AnnouncementDeliveryStatus.draft);
      expect(notice.audience.platforms, {'android'});
      expect(notice.display.dismissPolicy, AnnouncementDismissPolicy.oncePerId);
      expect(notice.fallbackContents, ['Fallback body']);
    });
  });
}
