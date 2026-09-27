import 'package:flutter/foundation.dart';

enum DebugAnnouncementSource { releaseNotes, debugAnnouncement }

enum AnnouncementDeliveryStatus { draft, preview, public, archived }

enum AnnouncementDeliveryKind { notice, update }

enum AnnouncementSeverity { info, warning, critical }

enum AnnouncementDismissPolicy { oncePerId, oncePerRevision, everyStart }

enum AnnouncementDisplaySurface { startupDialog, releaseHighlight }

class UpdateAnnouncementConfig {
  const UpdateAnnouncementConfig({
    required this.schemaVersion,
    this.locale = '',
    this.fallbackLocale = '',
    required this.versionInfo,
    required this.announcement,
    required this.donors,
    required this.releaseNotes,
    required this.noticeEnabled,
    required this.notice,
    this.debugAnnouncement,
    this.debugAnnouncementSource = DebugAnnouncementSource.releaseNotes,
    this.noticeCandidates = const [],
    this.updateCandidates = const [],
  });

  final int schemaVersion;
  final String locale;
  final String fallbackLocale;
  final UpdateVersionInfo versionInfo;
  final UpdateAnnouncement announcement;
  final List<UpdateDonor> donors;
  final List<UpdateReleaseNoteEntry> releaseNotes;
  final bool noticeEnabled;
  final UpdateNotice? notice;
  final UpdateAnnouncement? debugAnnouncement;
  final DebugAnnouncementSource debugAnnouncementSource;
  final List<AnnouncementNoticeCandidate> noticeCandidates;
  final List<AnnouncementUpdateCandidate> updateCandidates;

  bool get hasDonors => donors.isNotEmpty;
  bool get hasReleaseNotes => releaseNotes.isNotEmpty;

  factory UpdateAnnouncementConfig.fromJson(Map<String, dynamic> json) {
    final versionInfoRaw = _readMap(json['version_info']) ?? json;
    final versionInfo = UpdateVersionInfo.fromJson(versionInfoRaw);
    final announcement = UpdateAnnouncement.fromJson(
      _readMap(json['announcement']) ?? json,
    );
    final debugSection = _readMap(json['debug']);
    final debugAnnouncement = _readAnnouncement(
      debugSection?['announcement'] ?? json['debug_announcement'],
    );
    final debugAnnouncementSource = _readDebugAnnouncementSource(
      debugSection?['announcement_source'] ?? json['debug_announcement_source'],
    );
    final noticeEnabled = _readBool(
      json,
      'notice_enabled',
      fallbackKey: 'noticeEnabled',
    );
    final notice = _readNotice(json['notice']);
    final noticeCandidates = _readNoticeCandidates(json['notices']);
    final updateCandidates = _readUpdateCandidates(json['updates']);
    final donors = _readList(json['donors'])
        .whereType<Map>()
        .map((raw) => UpdateDonor.fromJson(raw.cast<String, dynamic>()))
        .where(
          (donor) =>
              donor.name.trim().isNotEmpty || donor.avatar.trim().isNotEmpty,
        )
        .toList(growable: false);
    final releaseNotes = _readReleaseNotes(json['release_notes']);
    return UpdateAnnouncementConfig(
      schemaVersion: _readInt(json, 'schema_version').clamp(1, 9999),
      locale: _readString(json, 'locale'),
      fallbackLocale: _readString(
        json,
        'fallback_locale',
        fallbackKey: 'fallbackLocale',
      ),
      versionInfo: versionInfo,
      announcement: announcement,
      donors: donors,
      releaseNotes: releaseNotes,
      noticeEnabled: noticeEnabled,
      notice: notice,
      debugAnnouncement: debugAnnouncement,
      debugAnnouncementSource: debugAnnouncementSource,
      noticeCandidates: noticeCandidates,
      updateCandidates: updateCandidates,
    );
  }

  UpdateReleaseNoteEntry? releaseNoteForVersion(String version) {
    final normalized = _normalizeVersionLabel(version);
    if (normalized.isEmpty || releaseNotes.isEmpty) return null;
    for (final entry in releaseNotes) {
      if (_normalizeVersionLabel(entry.version) == normalized) return entry;
    }
    return null;
  }

  static Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map) return value.cast<String, dynamic>();
    return null;
  }

  static UpdateAnnouncement? _readAnnouncement(dynamic value) {
    final map = _readMap(value);
    if (map == null) return null;
    return UpdateAnnouncement.fromJson(map);
  }

  static UpdateNotice? _readNotice(dynamic value) {
    final map = _readMap(value);
    if (map == null) return null;
    return UpdateNotice.fromJson(map);
  }

  static List<dynamic> _readList(dynamic value) {
    if (value is List) return value;
    return const [];
  }
}

class UpdateVersionInfo {
  const UpdateVersionInfo({
    required this.latestVersion,
    required this.isForce,
    required this.downloadUrl,
    required this.updateSource,
    required this.publishAt,
    required this.debugVersion,
    required this.skipUpdateVersion,
  });

  final String latestVersion;
  final bool isForce;
  final String downloadUrl;
  final String updateSource;
  final DateTime? publishAt;
  final String debugVersion;
  final String skipUpdateVersion;

  bool isPublishedAt(DateTime nowUtc) {
    final publish = publishAt;
    if (publish == null) return true;
    return !publish.isAfter(nowUtc.toUtc());
  }

  factory UpdateVersionInfo.fromJson(Map<String, dynamic> json) {
    final scoped = _resolvePlatformVersionInfo(json);
    final isForceScoped =
        _readBool(scoped, 'force_update', fallbackKey: 'is_force') ||
        _readBool(scoped, 'isForce');
    final isForceRoot =
        _readBool(json, 'force_update', fallbackKey: 'is_force') ||
        _readBool(json, 'isForce');
    return UpdateVersionInfo(
      latestVersion:
          _readString(
            scoped,
            'latest_version',
            fallbackKey: 'latestVersion',
          ).ifEmpty(
            _readString(json, 'latest_version', fallbackKey: 'latestVersion'),
          ),
      isForce: isForceScoped || isForceRoot,
      downloadUrl: _readString(scoped, 'url', fallbackKey: 'download_url')
          .ifEmpty(_readString(scoped, 'downloadUrl'))
          .ifEmpty(_readString(json, 'url', fallbackKey: 'download_url'))
          .ifEmpty(_readString(json, 'downloadUrl')),
      updateSource:
          _readString(
            scoped,
            'update_source',
            fallbackKey: 'updateSource',
          ).ifEmpty(
            _readString(json, 'update_source', fallbackKey: 'updateSource'),
          ),
      publishAt:
          _readDateTime(scoped, 'publish_at', fallbackKey: 'publishAt') ??
          _readDateTime(json, 'publish_at', fallbackKey: 'publishAt'),
      debugVersion:
          _readString(
            scoped,
            'debug_version',
            fallbackKey: 'debugVersion',
          ).ifEmpty(
            _readString(json, 'debug_version', fallbackKey: 'debugVersion'),
          ),
      skipUpdateVersion:
          _readString(
            scoped,
            'skip_update_version',
            fallbackKey: 'skipUpdateVersion',
          ).ifEmpty(
            _readString(
              json,
              'skip_update_version',
              fallbackKey: 'skipUpdateVersion',
            ),
          ),
    );
  }
}

class UpdateAnnouncement {
  const UpdateAnnouncement({
    required this.id,
    required this.title,
    required this.showWhenUpToDate,
    required this.contentsByLocale,
    required this.fallbackContents,
    required this.newDonorIds,
  });

  final int id;
  final String title;
  final bool showWhenUpToDate;
  final Map<String, List<String>> contentsByLocale;
  final List<String> fallbackContents;
  final List<String> newDonorIds;

  factory UpdateAnnouncement.fromJson(Map<String, dynamic> json) {
    var contentsByLocale = _readLocalizedContents(json['contents']);
    var fallbackContents = contentsByLocale.isEmpty
        ? _readStringList(json['contents'])
        : const <String>[];

    if (contentsByLocale.isEmpty && fallbackContents.isEmpty) {
      contentsByLocale = _readLocalizedContents(json['update_log']);
    }
    if (contentsByLocale.isEmpty && fallbackContents.isEmpty) {
      fallbackContents = _readStringList(json['update_log']);
    }
    return UpdateAnnouncement(
      id: _readInt(json, 'id'),
      title: _readString(json, 'title'),
      showWhenUpToDate: _readBool(
        json,
        'show_when_up_to_date',
        fallbackKey: 'showWhenUpToDate',
      ),
      contentsByLocale: contentsByLocale,
      fallbackContents: fallbackContents,
      newDonorIds: _readIdList(json['new_donor_ids']),
    );
  }

  List<String> contentsForLanguageCode(String languageCode) {
    final normalized = _normalizeLangKey(languageCode);
    if (normalized.isNotEmpty) {
      final exact = contentsByLocale[normalized];
      if (exact != null && exact.isNotEmpty) return exact;
    }
    if (contentsByLocale.isNotEmpty) {
      final en = contentsByLocale['en'];
      if (en != null && en.isNotEmpty) return en;
    }
    return fallbackContents;
  }

  List<UpdateDonor> newDonorsFrom(List<UpdateDonor> allDonors) {
    if (newDonorIds.isEmpty || allDonors.isEmpty) return const [];
    final target = newDonorIds
        .map((id) => id.trim())
        .where((id) => id.isNotEmpty)
        .toSet();
    if (target.isEmpty) return const [];
    return allDonors
        .where((donor) => target.contains(donor.id))
        .toList(growable: false);
  }
}

class UpdateNotice {
  const UpdateNotice({
    required this.title,
    required this.contentsByLocale,
    required this.fallbackContents,
  });

  final String title;
  final Map<String, List<String>> contentsByLocale;
  final List<String> fallbackContents;

  factory UpdateNotice.fromJson(Map<String, dynamic> json) {
    var contentsByLocale = _readLocalizedContents(json['contents']);
    var fallbackContents = contentsByLocale.isEmpty
        ? _readStringList(json['contents'])
        : const <String>[];

    if (contentsByLocale.isEmpty && fallbackContents.isEmpty) {
      contentsByLocale = _readLocalizedContents(json['content']);
    }
    if (contentsByLocale.isEmpty && fallbackContents.isEmpty) {
      fallbackContents = _readStringList(json['content']);
    }

    return UpdateNotice(
      title: _readString(json, 'title'),
      contentsByLocale: contentsByLocale,
      fallbackContents: fallbackContents,
    );
  }

  bool get hasContents =>
      contentsByLocale.values.any((entries) => entries.isNotEmpty) ||
      fallbackContents.isNotEmpty;

  List<String> contentsForLanguageCode(String languageCode) {
    final normalized = _normalizeLangKey(languageCode);
    if (normalized.isNotEmpty) {
      final exact = contentsByLocale[normalized];
      if (exact != null && exact.isNotEmpty) return exact;
    }
    if (contentsByLocale.isNotEmpty) {
      final en = contentsByLocale['en'];
      if (en != null && en.isNotEmpty) return en;
    }
    return fallbackContents;
  }
}

class AnnouncementAudience {
  const AnnouncementAudience({
    required this.platforms,
    required this.channels,
    required this.minAppVersion,
    required this.maxAppVersion,
  });

  final Set<String> platforms;
  final Set<String> channels;
  final String minAppVersion;
  final String maxAppVersion;

  bool get isEmpty =>
      platforms.isEmpty &&
      channels.isEmpty &&
      minAppVersion.trim().isEmpty &&
      maxAppVersion.trim().isEmpty;

  factory AnnouncementAudience.fromJson(Map<String, dynamic> json) {
    return AnnouncementAudience(
      platforms: _readStringSet(json['platforms']),
      channels: _readStringSet(json['channels']),
      minAppVersion: _readString(
        json,
        'min_app_version',
        fallbackKey: 'minAppVersion',
      ),
      maxAppVersion: _readString(
        json,
        'max_app_version',
        fallbackKey: 'maxAppVersion',
      ),
    );
  }
}

class AnnouncementDisplayPolicy {
  const AnnouncementDisplayPolicy({
    required this.surface,
    required this.dismissPolicy,
    required this.blocking,
  });

  final AnnouncementDisplaySurface surface;
  final AnnouncementDismissPolicy dismissPolicy;
  final bool blocking;

  factory AnnouncementDisplayPolicy.fromJson(Map<String, dynamic> json) {
    return AnnouncementDisplayPolicy(
      surface: _readDisplaySurface(json['surface']),
      dismissPolicy: _readDismissPolicy(
        json['dismiss_policy'] ?? json['dismissPolicy'],
      ),
      blocking: _readBool(json, 'blocking'),
    );
  }
}

class AnnouncementNoticeCandidate {
  const AnnouncementNoticeCandidate({
    required this.id,
    required this.revision,
    required this.status,
    required this.priority,
    required this.severity,
    required this.publishAt,
    required this.expireAt,
    required this.audience,
    required this.display,
    required this.titleByLocale,
    required this.fallbackTitle,
    required this.contentsByLocale,
    required this.fallbackContents,
  });

  final String id;
  final int revision;
  final AnnouncementDeliveryStatus status;
  final int priority;
  final AnnouncementSeverity severity;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final AnnouncementAudience audience;
  final AnnouncementDisplayPolicy display;
  final Map<String, String> titleByLocale;
  final String fallbackTitle;
  final Map<String, List<String>> contentsByLocale;
  final List<String> fallbackContents;

  bool get hasContents =>
      contentsByLocale.values.any((entries) => entries.isNotEmpty) ||
      fallbackContents.isNotEmpty;

  String titleForLanguageCode(String languageCode) {
    final normalized = _normalizeLangKey(languageCode);
    if (normalized.isNotEmpty) {
      final exact = titleByLocale[normalized];
      if (exact != null && exact.trim().isNotEmpty) return exact;
    }
    final en = titleByLocale['en'];
    if (en != null && en.trim().isNotEmpty) return en;
    return fallbackTitle;
  }

  List<String> contentsForLanguageCode(String languageCode) {
    final normalized = _normalizeLangKey(languageCode);
    if (normalized.isNotEmpty) {
      final exact = contentsByLocale[normalized];
      if (exact != null && exact.isNotEmpty) return exact;
    }
    final en = contentsByLocale['en'];
    if (en != null && en.isNotEmpty) return en;
    return fallbackContents;
  }
}

class AnnouncementUpdateCandidate {
  const AnnouncementUpdateCandidate({
    required this.id,
    required this.status,
    required this.priority,
    required this.platform,
    required this.channel,
    required this.version,
    required this.force,
    required this.downloadUrl,
    required this.releaseNoteId,
    required this.publishAt,
    required this.expireAt,
    required this.audience,
  });

  final String id;
  final AnnouncementDeliveryStatus status;
  final int priority;
  final String platform;
  final String channel;
  final String version;
  final bool force;
  final String downloadUrl;
  final String releaseNoteId;
  final DateTime? publishAt;
  final DateTime? expireAt;
  final AnnouncementAudience audience;
}

class UpdateDonor {
  const UpdateDonor({
    required this.id,
    required this.name,
    required this.avatar,
  });

  final String id;
  final String name;
  final String avatar;

  factory UpdateDonor.fromJson(Map<String, dynamic> json) {
    final name = _readString(json, 'name');
    return UpdateDonor(
      id: _readString(json, 'id', fallbackKey: 'uid').ifEmpty(name),
      name: name,
      avatar: _readString(json, 'avatar', fallbackKey: 'avatar_url'),
    );
  }
}

class UpdateReleaseNoteEntry {
  const UpdateReleaseNoteEntry({
    required this.version,
    required this.dateLabel,
    required this.items,
  });

  final String version;
  final String dateLabel;
  final List<UpdateReleaseNoteItem> items;

  factory UpdateReleaseNoteEntry.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final items = <UpdateReleaseNoteItem>[];
    if (rawItems is List) {
      for (final rawGroup in rawItems) {
        if (rawGroup is! Map) continue;
        final group = rawGroup.cast<String, dynamic>();
        final category = _readString(group, 'category');
        final localizedContents = _readLocalizedStringLists(group['contents']);
        if (localizedContents.isNotEmpty) {
          var maxLength = 0;
          for (final values in localizedContents.values) {
            if (values.length > maxLength) maxLength = values.length;
          }
          for (var index = 0; index < maxLength; index++) {
            final localizedItem = <String, String>{};
            for (final entry in localizedContents.entries) {
              if (index >= entry.value.length) continue;
              final value = entry.value[index].trim();
              if (value.isEmpty) continue;
              localizedItem[entry.key] = value;
            }
            if (localizedItem.isEmpty) continue;
            final fallbackContent =
                localizedItem['en'] ??
                localizedItem['zh'] ??
                localizedItem.values.first;
            items.add(
              UpdateReleaseNoteItem(
                category: category,
                localizedContents: localizedItem,
                fallbackContent: fallbackContent,
              ),
            );
          }
          continue;
        }

        final contents = _readStringList(group['contents']);
        for (final content in contents) {
          final fallbackContent = content.trim();
          if (fallbackContent.isEmpty) continue;
          items.add(
            UpdateReleaseNoteItem(
              category: category,
              localizedContents: const {},
              fallbackContent: fallbackContent,
            ),
          );
        }
      }
    }
    return UpdateReleaseNoteEntry(
      version: _readString(json, 'version'),
      dateLabel: _readString(json, 'date', fallbackKey: 'dateLabel'),
      items: items,
    );
  }
}

class UpdateReleaseNoteItem {
  const UpdateReleaseNoteItem({
    required this.category,
    required this.localizedContents,
    required this.fallbackContent,
  });

  final String category;
  final Map<String, String> localizedContents;
  final String fallbackContent;

  String contentForLanguageCode(String languageCode) {
    final normalized = _normalizeLangKey(languageCode);
    if (normalized.isNotEmpty) {
      final exact = localizedContents[normalized];
      if (exact != null && exact.trim().isNotEmpty) return exact;
    }
    final en = localizedContents['en'];
    if (en != null && en.trim().isNotEmpty) return en;
    return fallbackContent;
  }
}

Map<String, dynamic> _resolvePlatformVersionInfo(Map<String, dynamic> json) {
  final platformKey = _currentVersionInfoPlatformKey();
  final platformScoped = _readMapValue(json[platformKey]);
  if (platformScoped != null) return platformScoped;

  final aliasKey = switch (platformKey) {
    'windows' => 'win',
    'macos' => 'mac',
    _ => '',
  };
  if (aliasKey.isNotEmpty) {
    final aliasScoped = _readMapValue(json[aliasKey]);
    if (aliasScoped != null) return aliasScoped;
  }

  final defaultScoped =
      _readMapValue(json['default']) ?? _readMapValue(json['global']);
  if (defaultScoped != null) return defaultScoped;

  return json;
}

Map<String, dynamic>? _readMapValue(dynamic value) {
  if (value is Map) return value.cast<String, dynamic>();
  return null;
}

String _currentVersionInfoPlatformKey() {
  if (kIsWeb) return 'web';
  if (defaultTargetPlatform == TargetPlatform.android) return 'android';
  if (defaultTargetPlatform == TargetPlatform.windows) return 'windows';
  if (defaultTargetPlatform == TargetPlatform.macOS) return 'macos';
  if (defaultTargetPlatform == TargetPlatform.linux) return 'linux';
  if (defaultTargetPlatform == TargetPlatform.fuchsia) return 'fuchsia';
  return 'default';
}

DebugAnnouncementSource _readDebugAnnouncementSource(dynamic value) {
  if (value is bool) {
    return value
        ? DebugAnnouncementSource.debugAnnouncement
        : DebugAnnouncementSource.releaseNotes;
  }
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    if (normalized == 'debug' ||
        normalized == 'debug_announcement' ||
        normalized == 'announcement') {
      return DebugAnnouncementSource.debugAnnouncement;
    }
    if (normalized == 'release' ||
        normalized == 'release_notes' ||
        normalized == 'release_announcement') {
      return DebugAnnouncementSource.releaseNotes;
    }
  }
  return DebugAnnouncementSource.releaseNotes;
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final raw = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (raw is String) return raw.trim();
  return '';
}

bool _readBool(Map<String, dynamic> json, String key, {String? fallbackKey}) {
  final raw = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final lowered = raw.toLowerCase();
    if (lowered == 'true' || lowered == '1') return true;
    if (lowered == 'false' || lowered == '0') return false;
  }
  return false;
}

int _readInt(Map<String, dynamic> json, String key) {
  final raw = json[key];
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim()) ?? 0;
  return 0;
}

DateTime? _readDateTime(
  Map<String, dynamic> json,
  String key, {
  String? fallbackKey,
}) {
  final raw = json[key] ?? (fallbackKey == null ? null : json[fallbackKey]);
  if (raw is String) {
    final parsed = DateTime.tryParse(raw.trim());
    return parsed?.toUtc();
  }
  if (raw is num) {
    final value = raw.toDouble();
    final epochMillis = value.abs() < 100000000000 ? value * 1000 : value;
    return DateTime.fromMillisecondsSinceEpoch(
      epochMillis.toInt(),
      isUtc: true,
    );
  }
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is List) {
    return value
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];
    return [trimmed];
  }
  return const [];
}

Map<String, List<String>> _readLocalizedStringLists(dynamic value) {
  if (value is! Map) return const {};
  final localized = <String, List<String>>{};
  value.forEach((key, rawValue) {
    if (key is! String) return;
    final normalized = _normalizeLangKey(key);
    if (normalized.isEmpty) return;
    final values = _readStringList(rawValue);
    if (values.isEmpty) return;
    localized[normalized] = values;
  });
  return localized;
}

Map<String, String> _readLocalizedStrings(dynamic value) {
  if (value is! Map) return const {};
  final localized = <String, String>{};
  value.forEach((key, rawValue) {
    if (key is! String) return;
    final normalized = _normalizeLangKey(key);
    if (normalized.isEmpty) return;
    final text = rawValue is String ? rawValue.trim() : '';
    if (text.isEmpty) return;
    localized[normalized] = text;
  });
  return localized;
}

Set<String> _readStringSet(dynamic value) {
  if (value is List) {
    return value
        .map((entry) => entry.toString().trim().toLowerCase())
        .where((entry) => entry.isNotEmpty)
        .toSet();
  }
  if (value is String) {
    final trimmed = value.trim().toLowerCase();
    if (trimmed.isEmpty) return const {};
    return {trimmed};
  }
  return const {};
}

List<UpdateReleaseNoteEntry> _readReleaseNotes(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map>()
      .map(
        (raw) => UpdateReleaseNoteEntry.fromJson(raw.cast<String, dynamic>()),
      )
      .where(
        (entry) => entry.version.trim().isNotEmpty || entry.items.isNotEmpty,
      )
      .toList(growable: false);
}

List<AnnouncementNoticeCandidate> _readNoticeCandidates(dynamic value) {
  if (value is! List) return const [];
  final out = <AnnouncementNoticeCandidate>[];
  for (final raw in value) {
    if (raw is! Map) continue;
    final json = raw.cast<String, dynamic>();
    final id = _readString(json, 'id');
    if (id.isEmpty) continue;
    final content = _readMapValue(json['content']) ?? json;
    final titleByLocale = _readLocalizedStrings(content['title']);
    final fallbackTitle = titleByLocale.isEmpty
        ? _readString(content, 'title')
        : '';
    final contentsByLocale = _readLocalizedContents(
      content['body'] ?? content['contents'],
    );
    final fallbackContents = contentsByLocale.isEmpty
        ? _readStringList(content['body'] ?? content['contents'])
        : const <String>[];
    final audience = _readAudience(json['audience']);
    final display = _readDisplayPolicy(json['display']);
    out.add(
      AnnouncementNoticeCandidate(
        id: id,
        revision: _readInt(json, 'revision').clamp(0, 999999999),
        status: _readDeliveryStatus(json['status']),
        priority: _readInt(json, 'priority'),
        severity: _readSeverity(json['severity']),
        publishAt: _readDateTime(json, 'publish_at', fallbackKey: 'publishAt'),
        expireAt: _readDateTime(json, 'expire_at', fallbackKey: 'expireAt'),
        audience: audience,
        display: display,
        titleByLocale: titleByLocale,
        fallbackTitle: fallbackTitle,
        contentsByLocale: contentsByLocale,
        fallbackContents: fallbackContents,
      ),
    );
  }
  return out;
}

List<AnnouncementUpdateCandidate> _readUpdateCandidates(dynamic value) {
  if (value is! List) return const [];
  final out = <AnnouncementUpdateCandidate>[];
  for (final raw in value) {
    if (raw is! Map) continue;
    final json = raw.cast<String, dynamic>();
    final version = _readString(json, 'version').ifEmpty(
      _readString(json, 'latest_version', fallbackKey: 'latestVersion'),
    );
    final id = _readString(
      json,
      'id',
    ).ifEmpty(version.isEmpty ? '' : 'update-$version');
    if (id.isEmpty) continue;
    final audience = _readAudience(json['audience']);
    final force =
        _readBool(json, 'force') ||
        _readBool(json, 'force_update', fallbackKey: 'is_force') ||
        _readBool(json, 'isForce');
    out.add(
      AnnouncementUpdateCandidate(
        id: id,
        status: _readDeliveryStatus(json['status']),
        priority: _readInt(json, 'priority'),
        platform: _readString(json, 'platform'),
        channel: _readString(json, 'channel'),
        version: version,
        force: force,
        downloadUrl: _readString(
          json,
          'download_url',
          fallbackKey: 'url',
        ).ifEmpty(_readString(json, 'downloadUrl')),
        releaseNoteId: _readString(
          json,
          'release_note_id',
          fallbackKey: 'releaseNoteId',
        ),
        publishAt: _readDateTime(json, 'publish_at', fallbackKey: 'publishAt'),
        expireAt: _readDateTime(json, 'expire_at', fallbackKey: 'expireAt'),
        audience: audience,
      ),
    );
  }
  return out;
}

AnnouncementAudience _readAudience(dynamic value) {
  final map = _readMapValue(value);
  if (map == null) {
    return const AnnouncementAudience(
      platforms: <String>{},
      channels: <String>{},
      minAppVersion: '',
      maxAppVersion: '',
    );
  }
  return AnnouncementAudience.fromJson(map);
}

AnnouncementDisplayPolicy _readDisplayPolicy(dynamic value) {
  final map = _readMapValue(value);
  if (map == null) {
    return const AnnouncementDisplayPolicy(
      surface: AnnouncementDisplaySurface.startupDialog,
      dismissPolicy: AnnouncementDismissPolicy.oncePerId,
      blocking: false,
    );
  }
  return AnnouncementDisplayPolicy.fromJson(map);
}

AnnouncementDeliveryStatus _readDeliveryStatus(dynamic value) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'draft':
        return AnnouncementDeliveryStatus.draft;
      case 'preview':
        return AnnouncementDeliveryStatus.preview;
      case 'archived':
      case 'archive':
        return AnnouncementDeliveryStatus.archived;
      case 'public':
      case 'published':
        return AnnouncementDeliveryStatus.public;
    }
  }
  return AnnouncementDeliveryStatus.draft;
}

AnnouncementSeverity _readSeverity(dynamic value) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'warning':
      case 'warn':
        return AnnouncementSeverity.warning;
      case 'critical':
      case 'blocker':
      case 'blocking':
        return AnnouncementSeverity.critical;
      case 'info':
        return AnnouncementSeverity.info;
    }
  }
  return AnnouncementSeverity.info;
}

AnnouncementDismissPolicy _readDismissPolicy(dynamic value) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'once_per_revision':
      case 'onceperrevision':
        return AnnouncementDismissPolicy.oncePerRevision;
      case 'every_start':
      case 'everystart':
      case 'always':
        return AnnouncementDismissPolicy.everyStart;
      case 'once_per_id':
      case 'onceperid':
        return AnnouncementDismissPolicy.oncePerId;
    }
  }
  return AnnouncementDismissPolicy.oncePerId;
}

AnnouncementDisplaySurface _readDisplaySurface(dynamic value) {
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'release_highlight':
      case 'releasehighlight':
        return AnnouncementDisplaySurface.releaseHighlight;
      case 'startup_dialog':
      case 'startupdialog':
      case 'dialog':
        return AnnouncementDisplaySurface.startupDialog;
    }
  }
  return AnnouncementDisplaySurface.startupDialog;
}

List<String> _readIdList(dynamic value) {
  if (value is List) {
    final out = <String>[];
    for (final entry in value) {
      if (entry is String) {
        final trimmed = entry.trim();
        if (trimmed.isNotEmpty) out.add(trimmed);
      } else if (entry is num) {
        out.add(entry.toString());
      }
    }
    return out;
  }
  if (value is String) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return const [];
    return [trimmed];
  }
  if (value is num) {
    return [value.toString()];
  }
  return const [];
}

extension _StringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}

Map<String, List<String>> _readLocalizedContents(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, List<String>>{};
  value.forEach((key, rawValue) {
    if (key is! String) return;
    final normalized = _normalizeLangKey(key);
    if (normalized.isEmpty) return;
    final entries = _readStringList(rawValue);
    if (entries.isEmpty) return;
    result[normalized] = entries;
  });
  return result;
}

String _normalizeLangKey(String code) {
  final trimmed = code.trim().toLowerCase();
  if (trimmed.isEmpty) return '';
  final normalized = trimmed.replaceAll('_', '-');
  if (normalized.startsWith('zh')) return 'zh';
  if (normalized.startsWith('en')) return 'en';
  return normalized.split('-').first;
}

String _normalizeVersionLabel(String version) {
  final trimmed = version.trim();
  if (trimmed.isEmpty) return '';
  if (trimmed.length >= 2 && (trimmed[0] == 'v' || trimmed[0] == 'V')) {
    return trimmed.substring(1);
  }
  return trimmed;
}
