import '../../data/updates/update_config.dart';

UpdateNotice noticeForAnnouncementCandidate(
  AnnouncementNoticeCandidate candidate,
  String languageCode,
) {
  return UpdateNotice(
    title: candidate.titleForLanguageCode(languageCode),
    contentsByLocale: candidate.contentsByLocale,
    fallbackContents: candidate.fallbackContents,
  );
}

UpdateNotice? previewNoticeForAnnouncementConfig(
  UpdateAnnouncementConfig config,
  String languageCode,
) {
  final legacyNotice = config.notice;
  if (legacyNotice != null && legacyNotice.hasContents) return legacyNotice;
  for (final candidate in config.noticeCandidates) {
    if (!_isPreviewableNoticeCandidate(candidate)) continue;
    return noticeForAnnouncementCandidate(candidate, languageCode);
  }
  return null;
}

bool _isPreviewableNoticeCandidate(AnnouncementNoticeCandidate candidate) {
  if (!candidate.hasContents) return false;
  return switch (candidate.status) {
    AnnouncementDeliveryStatus.preview ||
    AnnouncementDeliveryStatus.public => true,
    AnnouncementDeliveryStatus.draft ||
    AnnouncementDeliveryStatus.archived => false,
  };
}
