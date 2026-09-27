import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/updates/announcement_delivery_policy.dart';
import 'package:memos_flutter_app/data/updates/update_config.dart';

void main() {
  group('AnnouncementDeliveryPolicy', () {
    const policy = AnnouncementDeliveryPolicy();

    test('selects eligible public notice and respects dismissal', () {
      final context = _context(seenNoticeRevisions: {'dismissed': 1});

      final selected = policy.selectStartupCandidate(
        config: _config(
          notices: [
            _notice(id: 'dismissed', revision: 1),
            _notice(id: 'eligible', priority: 10),
          ],
        ),
        context: context,
      );

      expect(selected?.kind, AnnouncementDeliveryKind.notice);
      expect(selected?.notice?.id, 'eligible');
    });

    test('filters notice by status schedule and audience', () {
      final context = _context();

      final selected = policy.selectStartupCandidate(
        config: _config(
          notices: [
            _notice(id: 'draft', status: AnnouncementDeliveryStatus.draft),
            _notice(
              id: 'future',
              publishAt: DateTime.parse('2026-05-11T00:00:00Z'),
            ),
            _notice(
              id: 'wrong-platform',
              audience: const AnnouncementAudience(
                platforms: {'windows'},
                channels: <String>{},
                minAppVersion: '',
                maxAppVersion: '',
              ),
            ),
          ],
        ),
        context: context,
      );

      expect(selected, isNull);
    });

    test('filters non-startup notice surfaces from startup delivery', () {
      final selected = policy.selectStartupCandidate(
        config: _config(
          notices: [
            _notice(
              id: 'release-highlight',
              priority: 999,
              surface: AnnouncementDisplaySurface.releaseHighlight,
            ),
          ],
        ),
        context: _context(),
      );

      expect(selected, isNull);
    });

    test('keeps startup dialog notices eligible over release highlights', () {
      final selected = policy.selectStartupCandidate(
        config: _config(
          notices: [
            _notice(
              id: 'release-highlight',
              priority: 999,
              surface: AnnouncementDisplaySurface.releaseHighlight,
            ),
            _notice(id: 'startup-dialog'),
          ],
        ),
        context: _context(),
      );

      expect(selected?.kind, AnnouncementDeliveryKind.notice);
      expect(selected?.notice?.id, 'startup-dialog');
    });

    test(
      'suppresses Play update prompts without blocking ordinary notices',
      () {
        final context = _context(allowUpdatePrompts: false);

        final selected = policy.selectStartupCandidate(
          config: _config(
            updates: [_update(force: true)],
            notices: [_notice(id: 'ordinary')],
          ),
          context: context,
        );

        expect(selected?.kind, AnnouncementDeliveryKind.notice);
        expect(selected?.notice?.id, 'ordinary');
      },
    );

    test('forced update outranks critical notice', () {
      final selected = policy.selectStartupCandidate(
        config: _config(
          updates: [_update(force: true)],
          notices: [
            _notice(
              id: 'critical',
              severity: AnnouncementSeverity.critical,
              priority: 500,
            ),
          ],
        ),
        context: _context(),
      );

      expect(selected?.kind, AnnouncementDeliveryKind.update);
      expect(selected?.update?.force, isTrue);
    });

    test('skipped optional update is ignored', () {
      final selected = policy.selectStartupCandidate(
        config: _config(
          updates: [_update(version: '1.0.2')],
          notices: [_notice(id: 'fallback')],
        ),
        context: _context(skippedUpdateVersion: '1.0.2'),
      );

      expect(selected?.kind, AnnouncementDeliveryKind.notice);
      expect(selected?.notice?.id, 'fallback');
    });
  });
}

AnnouncementDeliveryContext _context({
  String platform = 'android',
  String channel = 'full',
  String currentVersion = '1.0.0',
  DateTime? nowUtc,
  Map<String, int> seenNoticeRevisions = const {},
  String skippedUpdateVersion = '',
  bool allowUpdatePrompts = true,
}) {
  return AnnouncementDeliveryContext(
    platform: platform,
    channel: channel,
    currentVersion: currentVersion,
    nowUtc: nowUtc ?? DateTime.parse('2026-05-10T00:00:00Z'),
    seenNoticeRevisions: seenNoticeRevisions,
    skippedUpdateVersion: skippedUpdateVersion,
    allowUpdatePrompts: allowUpdatePrompts,
  );
}

UpdateAnnouncementConfig _config({
  List<AnnouncementNoticeCandidate> notices = const [],
  List<AnnouncementUpdateCandidate> updates = const [],
}) {
  return UpdateAnnouncementConfig(
    schemaVersion: 3,
    versionInfo: const UpdateVersionInfo(
      latestVersion: '',
      isForce: false,
      downloadUrl: '',
      updateSource: '',
      publishAt: null,
      debugVersion: '',
      skipUpdateVersion: '',
    ),
    announcement: const UpdateAnnouncement(
      id: 0,
      title: '',
      showWhenUpToDate: false,
      contentsByLocale: {},
      fallbackContents: [],
      newDonorIds: [],
    ),
    donors: const [],
    releaseNotes: const [],
    noticeEnabled: false,
    notice: null,
    noticeCandidates: notices,
    updateCandidates: updates,
  );
}

AnnouncementNoticeCandidate _notice({
  required String id,
  int revision = 1,
  AnnouncementDeliveryStatus status = AnnouncementDeliveryStatus.public,
  int priority = 0,
  AnnouncementSeverity severity = AnnouncementSeverity.info,
  AnnouncementDisplaySurface surface = AnnouncementDisplaySurface.startupDialog,
  DateTime? publishAt,
  DateTime? expireAt,
  AnnouncementAudience audience = const AnnouncementAudience(
    platforms: <String>{},
    channels: <String>{},
    minAppVersion: '',
    maxAppVersion: '',
  ),
}) {
  return AnnouncementNoticeCandidate(
    id: id,
    revision: revision,
    status: status,
    priority: priority,
    severity: severity,
    publishAt: publishAt,
    expireAt: expireAt,
    audience: audience,
    display: AnnouncementDisplayPolicy(
      surface: surface,
      dismissPolicy: AnnouncementDismissPolicy.oncePerId,
      blocking: false,
    ),
    titleByLocale: const {'en': 'Notice'},
    fallbackTitle: '',
    contentsByLocale: const {
      'en': ['Body'],
    },
    fallbackContents: const [],
  );
}

AnnouncementUpdateCandidate _update({
  String id = 'update-1.0.2',
  String version = '1.0.2',
  bool force = false,
}) {
  return AnnouncementUpdateCandidate(
    id: id,
    status: AnnouncementDeliveryStatus.public,
    priority: 0,
    platform: 'android',
    channel: 'full',
    version: version,
    force: force,
    downloadUrl: 'https://example.com/app.apk',
    releaseNoteId: 'release-$version',
    publishAt: null,
    expireAt: null,
    audience: const AnnouncementAudience(
      platforms: <String>{},
      channels: <String>{},
      minAppVersion: '',
      maxAppVersion: '',
    ),
  );
}
