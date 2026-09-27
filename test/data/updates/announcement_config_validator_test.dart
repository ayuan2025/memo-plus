import 'package:flutter_test/flutter_test.dart';

import '../../../tool/validate_announcement_config.dart';

void main() {
  group('AnnouncementConfigValidator', () {
    test('blocks unsafe production config', () {
      final result = AnnouncementConfigValidator().validate('''
{
  "notices": [
    {
      "id": "duplicate",
      "status": "draft",
      "publish_at": "2026-05-11T00:00:00Z",
      "expire_at": "2026-05-10T00:00:00Z",
      "content": {"body": {"zh": ["\\u6d4b\\u8bd5\\u516c\\u544a"]}}
    }
  ],
  "updates": [
    {
      "id": "duplicate",
      "status": "public",
      "force": true,
      "download_url": "not-a-url"
    }
  ]
}
''');

      expect(
        result.errors,
        contains('notice[0] uses draft status in production config.'),
      );
      expect(
        result.errors,
        contains('notice[0].expire_at must be after publish_at.'),
      );
      expect(result.errors, contains('Duplicate announcement id: duplicate.'));
      expect(
        result.errors,
        contains('update[0].publish_at is required for public items.'),
      );
      expect(
        result.errors,
        contains(
          'update[0] forced update requires a valid HTTP(S) download URL.',
        ),
      );
      expect(result.warnings, isNotEmpty);
    });

    test('warns for ambiguous but valid config', () {
      final result = AnnouncementConfigValidator().validate('''
{
  "notices": [
    {
      "id": "notice-1",
      "status": "public",
      "publish_at": "2026-05-01T00:00:00Z",
      "expire_at": "2026-07-01T00:00:00Z",
      "content": {"body": {"zh": ["\\u516c\\u544a"]}}
    }
  ],
  "updates": [
    {
      "id": "update-1",
      "status": "public",
      "publish_at": "2026-05-01T00:00:00Z",
      "version": "1.0.2",
      "download_url": "https://example.com/app.apk",
      "release_note_id": "missing"
    }
  ]
}
''');

      expect(result.errors, isEmpty);
      expect(
        result.warnings,
        contains('notice[0] has an expiry window longer than 45 days.'),
      );
      expect(
        result.warnings,
        contains('notice[0] does not include English body content.'),
      );
      expect(
        result.warnings,
        contains('Update references missing release note: missing.'),
      );
    });

    test('accepts safe example config', () {
      final result = AnnouncementConfigValidator().validate('''
{
  "schema_version": 3,
  "notices": [
    {
      "id": "notice-2026-05",
      "status": "public",
      "publish_at": "2026-05-01T00:00:00Z",
      "expire_at": "2026-05-10T00:00:00Z",
      "content": {
        "body": {
          "zh": ["\\u516c\\u544a"],
          "en": ["Notice"]
        }
      }
    }
  ],
  "updates": [
    {
      "id": "update-1.0.2",
      "status": "public",
      "publish_at": "2026-05-01T00:00:00Z",
      "version": "1.0.2",
      "force": true,
      "download_url": "https://example.com/app.apk",
      "release_note_id": "1.0.2"
    }
  ],
  "release_notes": [
    {
      "version": "1.0.2",
      "items": []
    }
  ]
}
''');

      expect(result.errors, isEmpty);
      expect(result.warnings, isEmpty);
    });
  });
}
