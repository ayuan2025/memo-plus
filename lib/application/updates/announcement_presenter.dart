import '../../data/updates/update_config.dart';

enum AnnouncementPresentationRequestKind { update, notice }

enum AnnouncementPresentationAction { update, later, acknowledged, exitApp }

class AnnouncementPresentationRequest {
  const AnnouncementPresentationRequest._({
    required this.kind,
    this.updateConfig,
    this.currentVersion,
    this.notice,
    this.noticeCandidate,
  });

  factory AnnouncementPresentationRequest.update({
    required UpdateAnnouncementConfig config,
    required String currentVersion,
  }) {
    return AnnouncementPresentationRequest._(
      kind: AnnouncementPresentationRequestKind.update,
      updateConfig: config,
      currentVersion: currentVersion,
    );
  }

  factory AnnouncementPresentationRequest.notice({
    UpdateNotice? notice,
    AnnouncementNoticeCandidate? candidate,
  }) {
    return AnnouncementPresentationRequest._(
      kind: AnnouncementPresentationRequestKind.notice,
      notice: notice,
      noticeCandidate: candidate,
    );
  }

  final AnnouncementPresentationRequestKind kind;
  final UpdateAnnouncementConfig? updateConfig;
  final String? currentVersion;
  final UpdateNotice? notice;
  final AnnouncementNoticeCandidate? noticeCandidate;
}

class AnnouncementPresentationResult {
  const AnnouncementPresentationResult(this.action);

  final AnnouncementPresentationAction action;
}

abstract class AnnouncementPresenter {
  Future<AnnouncementPresentationResult?> present(
    AnnouncementPresentationRequest request,
  );
}
