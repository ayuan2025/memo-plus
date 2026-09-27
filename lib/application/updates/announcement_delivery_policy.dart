import 'package:flutter/foundation.dart';

import '../../core/app_channel.dart';
import '../../data/updates/update_config.dart';
import 'update_announcement_channel_policy.dart';

class AnnouncementDeliveryContext {
  const AnnouncementDeliveryContext({
    required this.platform,
    required this.channel,
    required this.currentVersion,
    required this.nowUtc,
    required this.seenNoticeRevisions,
    required this.skippedUpdateVersion,
    required this.allowUpdatePrompts,
  });

  final String platform;
  final String channel;
  final String currentVersion;
  final DateTime nowUtc;
  final Map<String, int> seenNoticeRevisions;
  final String skippedUpdateVersion;
  final bool allowUpdatePrompts;

  factory AnnouncementDeliveryContext.current({
    required String currentVersion,
    required Map<String, int> seenNoticeRevisions,
    required String skippedUpdateVersion,
    DateTime? nowUtc,
  }) {
    return AnnouncementDeliveryContext(
      platform: startupAnnouncementPlatformKey(
        targetPlatform: defaultTargetPlatform,
        isWeb: kIsWeb,
      ),
      channel: currentAppChannel.name,
      currentVersion: currentVersion,
      nowUtc: (nowUtc ?? DateTime.now()).toUtc(),
      seenNoticeRevisions: seenNoticeRevisions,
      skippedUpdateVersion: skippedUpdateVersion,
      allowUpdatePrompts: shouldShowStartupUpdatePromptForCurrentBuild(),
    );
  }
}

class AnnouncementDeliverySelection {
  const AnnouncementDeliverySelection._({
    required this.kind,
    required this.rank,
    this.notice,
    this.update,
  });

  factory AnnouncementDeliverySelection.notice({
    required AnnouncementNoticeCandidate notice,
    required int rank,
  }) {
    return AnnouncementDeliverySelection._(
      kind: AnnouncementDeliveryKind.notice,
      rank: rank,
      notice: notice,
    );
  }

  factory AnnouncementDeliverySelection.update({
    required AnnouncementUpdateCandidate update,
    required int rank,
  }) {
    return AnnouncementDeliverySelection._(
      kind: AnnouncementDeliveryKind.update,
      rank: rank,
      update: update,
    );
  }

  final AnnouncementDeliveryKind kind;
  final int rank;
  final AnnouncementNoticeCandidate? notice;
  final AnnouncementUpdateCandidate? update;

  bool get isForcedUpdate => update?.force ?? false;
}

class AnnouncementDeliveryPolicy {
  const AnnouncementDeliveryPolicy();

  AnnouncementDeliverySelection? selectStartupCandidate({
    required UpdateAnnouncementConfig config,
    required AnnouncementDeliveryContext context,
  }) {
    final candidates = <AnnouncementDeliverySelection>[
      for (final update in config.updateCandidates)
        if (_isUpdateEligible(update, context))
          AnnouncementDeliverySelection.update(
            update: update,
            rank: _updateRank(update),
          ),
      for (final notice in config.noticeCandidates)
        if (_isNoticeEligible(notice, context))
          AnnouncementDeliverySelection.notice(
            notice: notice,
            rank: _noticeRank(notice),
          ),
    ];
    if (candidates.isEmpty) return null;
    candidates.sort((left, right) {
      final rankDiff = right.rank.compareTo(left.rank);
      if (rankDiff != 0) return rankDiff;
      return _candidateId(left).compareTo(_candidateId(right));
    });
    return candidates.first;
  }

  bool _isNoticeEligible(
    AnnouncementNoticeCandidate notice,
    AnnouncementDeliveryContext context,
  ) {
    if (notice.status != AnnouncementDeliveryStatus.public) return false;
    if (notice.display.surface != AnnouncementDisplaySurface.startupDialog) {
      return false;
    }
    if (!notice.hasContents) return false;
    if (!_isWithinSchedule(notice.publishAt, notice.expireAt, context.nowUtc)) {
      return false;
    }
    if (!_matchesAudience(
      audience: notice.audience,
      platform: '',
      channel: '',
      version: '',
      context: context,
    )) {
      return false;
    }
    return !_isNoticeDismissed(notice, context.seenNoticeRevisions);
  }

  bool _isUpdateEligible(
    AnnouncementUpdateCandidate update,
    AnnouncementDeliveryContext context,
  ) {
    if (!context.allowUpdatePrompts) return false;
    if (update.status != AnnouncementDeliveryStatus.public) return false;
    if (update.version.trim().isEmpty) return false;
    if (update.downloadUrl.trim().isEmpty) return false;
    if (!_isWithinSchedule(update.publishAt, update.expireAt, context.nowUtc)) {
      return false;
    }
    if (!_matchesAudience(
      audience: update.audience,
      platform: update.platform,
      channel: update.channel,
      version: update.version,
      context: context,
    )) {
      return false;
    }
    if (_compareVersionTriplets(update.version, context.currentVersion) <= 0) {
      return false;
    }
    final skipped = context.skippedUpdateVersion.trim();
    if (skipped.isNotEmpty &&
        _compareVersionTriplets(update.version, skipped) == 0) {
      return false;
    }
    return true;
  }

  bool _isWithinSchedule(
    DateTime? publishAt,
    DateTime? expireAt,
    DateTime now,
  ) {
    final normalizedNow = now.toUtc();
    if (publishAt != null && publishAt.isAfter(normalizedNow)) return false;
    if (expireAt != null && !expireAt.isAfter(normalizedNow)) return false;
    return true;
  }

  bool _matchesAudience({
    required AnnouncementAudience audience,
    required String platform,
    required String channel,
    required String version,
    required AnnouncementDeliveryContext context,
  }) {
    final normalizedPlatform = platform.trim().toLowerCase();
    if (normalizedPlatform.isNotEmpty &&
        normalizedPlatform != context.platform) {
      return false;
    }
    final normalizedChannel = channel.trim().toLowerCase();
    if (normalizedChannel.isNotEmpty && normalizedChannel != context.channel) {
      return false;
    }
    if (audience.platforms.isNotEmpty &&
        !audience.platforms.contains(context.platform)) {
      return false;
    }
    if (audience.channels.isNotEmpty &&
        !audience.channels.contains(context.channel)) {
      return false;
    }
    final currentVersion = context.currentVersion;
    final minVersion = audience.minAppVersion.trim();
    if (minVersion.isNotEmpty &&
        _compareVersionTriplets(currentVersion, minVersion) < 0) {
      return false;
    }
    final maxVersion = audience.maxAppVersion.trim();
    if (maxVersion.isNotEmpty &&
        _compareVersionTriplets(currentVersion, maxVersion) > 0) {
      return false;
    }
    return true;
  }

  bool _isNoticeDismissed(
    AnnouncementNoticeCandidate notice,
    Map<String, int> seenNoticeRevisions,
  ) {
    if (notice.display.dismissPolicy == AnnouncementDismissPolicy.everyStart) {
      return false;
    }
    final seenRevision = seenNoticeRevisions[notice.id];
    if (seenRevision == null) return false;
    if (notice.display.dismissPolicy == AnnouncementDismissPolicy.oncePerId) {
      return true;
    }
    return seenRevision >= notice.revision;
  }

  int _updateRank(AnnouncementUpdateCandidate update) {
    return (update.force ? 10000 : 7000) + update.priority;
  }

  int _noticeRank(AnnouncementNoticeCandidate notice) {
    if (notice.severity == AnnouncementSeverity.critical ||
        notice.display.blocking) {
      return 9000 + notice.priority;
    }
    if (notice.display.surface == AnnouncementDisplaySurface.releaseHighlight) {
      return 5000 + notice.priority;
    }
    return 1000 + notice.priority;
  }

  String _candidateId(AnnouncementDeliverySelection selection) {
    return selection.notice?.id ?? selection.update?.id ?? '';
  }
}

int _compareVersionTriplets(String left, String right) {
  final leftParts = _parseVersionTriplet(left);
  final rightParts = _parseVersionTriplet(right);
  for (var i = 0; i < 3; i++) {
    final diff = leftParts[i].compareTo(rightParts[i]);
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
