import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/app_localization.dart';
import '../../data/models/device_preferences.dart';
import '../../data/updates/update_config.dart';
import '../../state/memos/app_bootstrap_adapter_provider.dart';
import 'announcement_delivery_policy.dart';
import 'announcement_presenter.dart';
import 'update_announcement_channel_policy.dart';

class UpdateAnnouncementRunner {
  UpdateAnnouncementRunner({
    required AppBootstrapAdapter bootstrapAdapter,
    required AnnouncementPresenter presenter,
    required bool Function() isMounted,
    bool Function()? shouldFetchStartupUpdateAnnouncements,
    AnnouncementDeliveryPolicy deliveryPolicy =
        const AnnouncementDeliveryPolicy(),
  }) : _bootstrapAdapter = bootstrapAdapter,
       _presenter = presenter,
       _isMounted = isMounted,
       _deliveryPolicy = deliveryPolicy,
       _shouldFetchStartupUpdateAnnouncements =
           shouldFetchStartupUpdateAnnouncements ??
           shouldFetchStartupUpdateAnnouncementsForCurrentBuild;

  final AppBootstrapAdapter _bootstrapAdapter;
  final AnnouncementPresenter _presenter;
  final bool Function() _isMounted;
  final AnnouncementDeliveryPolicy _deliveryPolicy;
  final bool Function() _shouldFetchStartupUpdateAnnouncements;

  bool _updateAnnouncementChecked = false;
  Future<String?>? _appVersionFuture;

  static const UpdateAnnouncementConfig _fallbackUpdateConfig =
      UpdateAnnouncementConfig(
        schemaVersion: 1,
        versionInfo: UpdateVersionInfo(
          latestVersion: '',
          isForce: false,
          downloadUrl: '',
          updateSource: '',
          publishAt: null,
          debugVersion: '',
          skipUpdateVersion: '',
        ),
        announcement: UpdateAnnouncement(
          id: 0,
          title: '',
          showWhenUpToDate: false,
          contentsByLocale: {},
          fallbackContents: [],
          newDonorIds: [],
        ),
        donors: [],
        releaseNotes: [],
        noticeEnabled: false,
        notice: null,
      );

  void scheduleIfNeeded(WidgetRef ref) {
    if (_updateAnnouncementChecked) return;
    if (!_shouldFetchStartupUpdateAnnouncements()) {
      _updateAnnouncementChecked = true;
      return;
    }
    _updateAnnouncementChecked = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isMounted()) return;
      unawaited(_maybeShowAnnouncements(ref));
    });
  }

  Future<String?> _fetchAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final version = info.version.trim();
      return version.isEmpty ? null : version;
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveAppVersion() {
    return _appVersionFuture ??= _fetchAppVersion();
  }

  int _compareVersionTriplets(String remote, String local) {
    final remoteParts = _parseVersionTriplet(remote);
    final localParts = _parseVersionTriplet(local);
    for (var i = 0; i < 3; i++) {
      final diff = remoteParts[i].compareTo(localParts[i]);
      if (diff != 0) return diff;
    }
    return 0;
  }

  List<int> _parseVersionTriplet(String version) {
    if (version.trim().isEmpty) return const [0, 0, 0];
    final trimmed = version.split(RegExp(r'[-+]')).first;
    final parts = trimmed.split('.');
    final values = <int>[0, 0, 0];
    for (var i = 0; i < 3; i++) {
      if (i >= parts.length) break;
      final match = RegExp(r'\d+').firstMatch(parts[i]);
      if (match == null) continue;
      values[i] = int.tryParse(match.group(0) ?? '') ?? 0;
    }
    return values;
  }

  Future<void> _maybeShowAnnouncements(WidgetRef ref) async {
    var version = await _resolveAppVersion();
    if (!_isMounted() || version == null || version.isEmpty) return;

    final prefs = _bootstrapAdapter.readDevicePreferences(ref);
    if (!prefs.hasSelectedLanguage) return;

    final config = await _bootstrapAdapter.fetchLatestUpdateConfig(
      ref,
      localeTag: localeTagForAppLanguage(prefs.language),
    );
    if (!_isMounted()) return;
    final effectiveConfig = config ?? _fallbackUpdateConfig;

    var displayVersion = version;
    if (kDebugMode) {
      final debugVersion = effectiveConfig.versionInfo.debugVersion.trim();
      displayVersion = debugVersion.isNotEmpty ? debugVersion : '999.0';
    }

    final hasV3Candidates =
        effectiveConfig.noticeCandidates.isNotEmpty ||
        effectiveConfig.updateCandidates.isNotEmpty;
    if (hasV3Candidates) {
      final selection = _deliveryPolicy.selectStartupCandidate(
        config: effectiveConfig,
        context: AnnouncementDeliveryContext.current(
          currentVersion: displayVersion,
          seenNoticeRevisions: prefs.seenNoticeRevisions,
          skippedUpdateVersion: prefs.skippedUpdateVersion,
        ),
      );
      if (selection == null) return;
      await _maybeShowDeliverySelection(
        ref: ref,
        config: effectiveConfig,
        currentVersion: displayVersion,
        selection: selection,
      );
      return;
    }

    await _maybeShowUpdateAnnouncementWithConfig(
      ref: ref,
      config: effectiveConfig,
      currentVersion: displayVersion,
      prefs: prefs,
    );
    await _maybeShowNoticeWithConfig(
      ref: ref,
      config: effectiveConfig,
      prefs: prefs,
    );
  }

  Future<void> _maybeShowDeliverySelection({
    required WidgetRef ref,
    required UpdateAnnouncementConfig config,
    required String currentVersion,
    required AnnouncementDeliverySelection selection,
  }) async {
    switch (selection.kind) {
      case AnnouncementDeliveryKind.update:
        final update = selection.update;
        if (update == null) return;
        await _maybeShowUpdateCandidate(
          ref: ref,
          config: config,
          currentVersion: currentVersion,
          update: update,
        );
      case AnnouncementDeliveryKind.notice:
        final notice = selection.notice;
        if (notice == null) return;
        await _maybeShowNoticeCandidate(ref: ref, notice: notice);
    }
  }

  Future<void> _maybeShowUpdateCandidate({
    required WidgetRef ref,
    required UpdateAnnouncementConfig config,
    required String currentVersion,
    required AnnouncementUpdateCandidate update,
  }) async {
    final result = await _presenter.present(
      AnnouncementPresentationRequest.update(
        config: _configForUpdateCandidate(config, update),
        currentVersion: currentVersion,
      ),
    );
    if (!_isMounted() || update.force) return;
    if (result?.action == AnnouncementPresentationAction.later) {
      _bootstrapAdapter.setSkippedUpdateVersion(
        ref: ref,
        version: update.version,
      );
    }
  }

  Future<void> _maybeShowNoticeCandidate({
    required WidgetRef ref,
    required AnnouncementNoticeCandidate notice,
  }) async {
    final result = await _presenter.present(
      AnnouncementPresentationRequest.notice(candidate: notice),
    );
    if (!_isMounted()) return;
    if (result?.action != AnnouncementPresentationAction.acknowledged) return;
    if (notice.display.dismissPolicy == AnnouncementDismissPolicy.everyStart) {
      return;
    }
    _bootstrapAdapter.setSeenNoticeRevision(
      ref: ref,
      id: notice.id,
      revision: notice.revision,
    );
  }

  UpdateAnnouncementConfig _configForUpdateCandidate(
    UpdateAnnouncementConfig config,
    AnnouncementUpdateCandidate update,
  ) {
    return UpdateAnnouncementConfig(
      schemaVersion: config.schemaVersion,
      locale: config.locale,
      fallbackLocale: config.fallbackLocale,
      versionInfo: UpdateVersionInfo(
        latestVersion: update.version,
        isForce: update.force,
        downloadUrl: update.downloadUrl,
        updateSource: update.channel,
        publishAt: update.publishAt,
        debugVersion: config.versionInfo.debugVersion,
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
      donors: config.donors,
      releaseNotes: config.releaseNotes,
      noticeEnabled: false,
      notice: null,
      debugAnnouncement: config.debugAnnouncement,
      debugAnnouncementSource: config.debugAnnouncementSource,
      noticeCandidates: config.noticeCandidates,
      updateCandidates: config.updateCandidates,
    );
  }

  Future<void> _maybeShowUpdateAnnouncementWithConfig({
    required WidgetRef ref,
    required UpdateAnnouncementConfig config,
    required String currentVersion,
    required DevicePreferences prefs,
  }) async {
    final nowUtc = DateTime.now().toUtc();
    final publishReady = config.versionInfo.isPublishedAt(nowUtc);
    final latestVersion = config.versionInfo.latestVersion.trim();
    final skipUpdateVersion = config.versionInfo.skipUpdateVersion.trim();
    final hasUpdate =
        publishReady &&
        latestVersion.isNotEmpty &&
        (skipUpdateVersion.isEmpty || latestVersion != skipUpdateVersion) &&
        _compareVersionTriplets(latestVersion, currentVersion) > 0;
    final isForce = config.versionInfo.isForce && hasUpdate;
    final skippedUpdateVersion = prefs.skippedUpdateVersion.trim();
    final skippedThisVersion =
        latestVersion.isNotEmpty &&
        skippedUpdateVersion.isNotEmpty &&
        _compareVersionTriplets(latestVersion, skippedUpdateVersion) == 0;

    final showWhenUpToDate = config.announcement.showWhenUpToDate;
    final announcementId = config.announcement.id;
    final hasUnseenAnnouncement =
        announcementId > 0 && announcementId != prefs.lastSeenAnnouncementId;
    final shouldShow =
        isForce ||
        (hasUpdate && !skippedThisVersion) ||
        (showWhenUpToDate && hasUnseenAnnouncement);
    if (!shouldShow) return;

    final action = await _presenter.present(
      AnnouncementPresentationRequest.update(
        config: config,
        currentVersion: currentVersion,
      ),
    );
    if (!_isMounted() || isForce) return;
    if (action?.action == AnnouncementPresentationAction.update ||
        action?.action == AnnouncementPresentationAction.later) {
      _bootstrapAdapter.setLastSeenAnnouncement(
        ref: ref,
        version: currentVersion,
        announcementId: config.announcement.id,
      );
    }
    if (action?.action == AnnouncementPresentationAction.later && hasUpdate) {
      _bootstrapAdapter.setSkippedUpdateVersion(
        ref: ref,
        version: latestVersion,
      );
    }
  }

  Future<void> _maybeShowNoticeWithConfig({
    required WidgetRef ref,
    required UpdateAnnouncementConfig config,
    required DevicePreferences prefs,
  }) async {
    if (!config.noticeEnabled) return;
    final notice = config.notice;
    if (notice == null || !notice.hasContents) return;

    final noticeHash = _hashNotice(notice);
    if (noticeHash.isEmpty) return;
    if (prefs.lastSeenNoticeHash.trim() == noticeHash) return;

    final acknowledged = await _presenter.present(
      AnnouncementPresentationRequest.notice(notice: notice),
    );
    if (!_isMounted() ||
        acknowledged?.action != AnnouncementPresentationAction.acknowledged) {
      return;
    }
    _bootstrapAdapter.setLastSeenNoticeHash(ref, noticeHash);
  }

  String _hashNotice(UpdateNotice notice) {
    final buffer = StringBuffer();
    buffer.write(notice.title.trim());
    final localeKeys = notice.contentsByLocale.keys.toList()..sort();
    for (final key in localeKeys) {
      buffer.write('|$key=');
      final entries = notice.contentsByLocale[key] ?? const <String>[];
      for (final line in entries) {
        buffer.write(line.trim());
        buffer.write('\n');
      }
    }
    if (notice.fallbackContents.isNotEmpty) {
      buffer.write('|fallback=');
      for (final line in notice.fallbackContents) {
        buffer.write(line.trim());
        buffer.write('\n');
      }
    }
    final raw = buffer.toString().trim();
    if (raw.isEmpty) return '';
    return sha1.convert(utf8.encode(raw)).toString();
  }
}
