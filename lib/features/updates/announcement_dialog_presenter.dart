import 'package:flutter/material.dart';

import '../../application/updates/announcement_presenter.dart';
import 'announcement_notice_resolver.dart';
import 'notice_dialog.dart';
import 'update_announcement_dialog.dart';

class DialogAnnouncementPresenter implements AnnouncementPresenter {
  const DialogAnnouncementPresenter({
    required GlobalKey<NavigatorState> navigatorKey,
    required bool Function() isMounted,
  }) : _navigatorKey = navigatorKey,
       _isMounted = isMounted;

  final GlobalKey<NavigatorState> _navigatorKey;
  final bool Function() _isMounted;

  @override
  Future<AnnouncementPresentationResult?> present(
    AnnouncementPresentationRequest request,
  ) async {
    final context = _navigatorKey.currentContext;
    if (context == null || !context.mounted) return null;
    switch (request.kind) {
      case AnnouncementPresentationRequestKind.update:
        final config = request.updateConfig;
        final currentVersion = request.currentVersion;
        if (config == null || currentVersion == null) return null;
        final action = await UpdateAnnouncementDialog.show(
          context,
          config: config,
          currentVersion: currentVersion,
        );
        if (!_isMounted()) return null;
        return switch (action) {
          AnnouncementAction.update => const AnnouncementPresentationResult(
            AnnouncementPresentationAction.update,
          ),
          AnnouncementAction.later => const AnnouncementPresentationResult(
            AnnouncementPresentationAction.later,
          ),
          AnnouncementAction.exitApp => const AnnouncementPresentationResult(
            AnnouncementPresentationAction.exitApp,
          ),
          null => null,
        };
      case AnnouncementPresentationRequestKind.notice:
        final notice =
            request.notice ??
            (request.noticeCandidate == null
                ? null
                : noticeForAnnouncementCandidate(
                    request.noticeCandidate!,
                    Localizations.localeOf(context).languageCode,
                  ));
        if (notice == null) return null;
        final acknowledged = await NoticeDialog.show(context, notice: notice);
        if (!_isMounted() || acknowledged != true) return null;
        return const AnnouncementPresentationResult(
          AnnouncementPresentationAction.acknowledged,
        );
    }
  }
}
