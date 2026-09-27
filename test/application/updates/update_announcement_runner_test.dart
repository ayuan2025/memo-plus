import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/updates/announcement_presenter.dart';
import 'package:memos_flutter_app/application/updates/update_announcement_runner.dart';
import 'package:memos_flutter_app/core/app_channel.dart';
import 'package:memos_flutter_app/data/models/app_preferences.dart';
import 'package:memos_flutter_app/data/models/device_preferences.dart';
import 'package:memos_flutter_app/data/updates/update_config.dart';
import 'package:memos_flutter_app/features/updates/announcement_notice_resolver.dart';
import 'package:memos_flutter_app/state/memos/app_bootstrap_adapter_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    _TestBootstrapAdapter.reset();
    debugAppChannelOverride = AppChannel.full;
    PackageInfo.setMockInitialValues(
      appName: 'MemoFlow',
      packageName: 'com.example.memoflow',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  tearDown(() {
    debugAppChannelOverride = null;
  });

  testWidgets('v3 notice delivery uses presenter and records revision', (
    tester,
  ) async {
    final adapter = _TestBootstrapAdapter(
      config: _config(notices: [_notice(id: 'notice-1', revision: 3)]),
    );
    final presenter = _TestAnnouncementPresenter(
      result: const AnnouncementPresentationResult(
        AnnouncementPresentationAction.acknowledged,
      ),
    );
    final runner = UpdateAnnouncementRunner(
      bootstrapAdapter: adapter,
      presenter: presenter,
      isMounted: () => true,
      shouldFetchStartupUpdateAnnouncements: () => true,
    );

    runner.scheduleIfNeeded(_UnusedWidgetRef());
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();

    expect(presenter.requests, hasLength(1));
    expect(
      presenter.requests.single.kind,
      AnnouncementPresentationRequestKind.notice,
    );
    expect(presenter.requests.single.noticeCandidate?.id, 'notice-1');
    expect(adapter.seenNoticeId, 'notice-1');
    expect(adapter.seenNoticeRevision, 3);
  });

  testWidgets('v3 optional update uses presenter and can be skipped', (
    tester,
  ) async {
    final adapter = _TestBootstrapAdapter(
      config: _config(updates: [_update(version: '1.0.2')]),
    );
    final presenter = _TestAnnouncementPresenter(
      result: const AnnouncementPresentationResult(
        AnnouncementPresentationAction.later,
      ),
    );
    final runner = UpdateAnnouncementRunner(
      bootstrapAdapter: adapter,
      presenter: presenter,
      isMounted: () => true,
      shouldFetchStartupUpdateAnnouncements: () => true,
    );

    runner.scheduleIfNeeded(_UnusedWidgetRef());
    tester.binding.scheduleFrame();
    await tester.pump();
    await tester.pump();

    expect(presenter.requests, hasLength(1));
    expect(
      presenter.requests.single.kind,
      AnnouncementPresentationRequestKind.update,
    );
    expect(
      presenter.requests.single.updateConfig?.versionInfo.latestVersion,
      '1.0.2',
    );
    expect(adapter.skippedUpdateVersion, '1.0.2');
  });

  test('debug preview resolves v3 notices without legacy notice state', () {
    final config = _config(
      notices: [
        _notice(
          id: 'notice-preview',
          revision: 1,
          status: AnnouncementDeliveryStatus.preview,
        ),
      ],
    );

    final notice = previewNoticeForAnnouncementConfig(config, 'en');

    expect(notice?.title, 'Notice');
    expect(notice?.contentsForLanguageCode('en'), ['Body']);
    expect(_TestBootstrapAdapter._seenNoticeId, isNull);
    expect(_TestBootstrapAdapter._seenNoticeRevision, isNull);
  });
}

class _TestBootstrapAdapter extends AppBootstrapAdapter {
  const _TestBootstrapAdapter({required this.config});

  final UpdateAnnouncementConfig config;
  static String? _seenNoticeId;
  static int? _seenNoticeRevision;
  static String? _skippedUpdateVersion;

  String? get seenNoticeId => _seenNoticeId;
  int? get seenNoticeRevision => _seenNoticeRevision;
  String? get skippedUpdateVersion => _skippedUpdateVersion;

  static void reset() {
    _seenNoticeId = null;
    _seenNoticeRevision = null;
    _skippedUpdateVersion = null;
  }

  @override
  DevicePreferences readDevicePreferences(WidgetRef ref) {
    return DevicePreferences.defaultsForLanguage(AppLanguage.en);
  }

  @override
  Future<UpdateAnnouncementConfig?> fetchLatestUpdateConfig(
    WidgetRef ref, {
    String localeTag = '',
  }) {
    return Future.value(config);
  }

  @override
  void setSeenNoticeRevision({
    required WidgetRef ref,
    required String id,
    required int revision,
  }) {
    _seenNoticeId = id;
    _seenNoticeRevision = revision;
  }

  @override
  void setSkippedUpdateVersion({
    required WidgetRef ref,
    required String version,
  }) {
    _skippedUpdateVersion = version;
  }
}

class _TestAnnouncementPresenter implements AnnouncementPresenter {
  _TestAnnouncementPresenter({required this.result});

  final AnnouncementPresentationResult result;
  final requests = <AnnouncementPresentationRequest>[];

  @override
  Future<AnnouncementPresentationResult?> present(
    AnnouncementPresentationRequest request,
  ) async {
    requests.add(request);
    return result;
  }
}

class _UnusedWidgetRef implements WidgetRef {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw StateError('WidgetRef should not be used by this test');
  }
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
      debugVersion: '1.0.0',
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
  required int revision,
  AnnouncementDeliveryStatus status = AnnouncementDeliveryStatus.public,
}) {
  return AnnouncementNoticeCandidate(
    id: id,
    revision: revision,
    status: status,
    priority: 0,
    severity: AnnouncementSeverity.info,
    publishAt: null,
    expireAt: null,
    audience: const AnnouncementAudience(
      platforms: <String>{},
      channels: <String>{},
      minAppVersion: '',
      maxAppVersion: '',
    ),
    display: const AnnouncementDisplayPolicy(
      surface: AnnouncementDisplaySurface.startupDialog,
      dismissPolicy: AnnouncementDismissPolicy.oncePerRevision,
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

AnnouncementUpdateCandidate _update({required String version}) {
  return AnnouncementUpdateCandidate(
    id: 'update-$version',
    status: AnnouncementDeliveryStatus.public,
    priority: 0,
    platform: '',
    channel: '',
    version: version,
    force: false,
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
