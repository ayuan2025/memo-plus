import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/share_inline_image_content.dart';
import '../../data/models/attachment.dart';
import '../../data/models/local_memo.dart';
import '../attachments/queued_attachment_stager_provider.dart';
import '../system/database_provider.dart';
import 'memo_mutation_service.dart';

final thirdPartyShareAttachmentAppenderProvider =
    Provider<ThirdPartyShareAttachmentAppender>((ref) {
      return ThirdPartyShareAttachmentAppender(ref);
    });

enum ThirdPartyShareAttachmentKind { inlineImage, video, attachment }

enum ThirdPartyShareAttachmentAppendStatus {
  appended,
  skippedDuplicate,
  skippedNotReferenced,
}

class ThirdPartyShareAttachmentAppendRequest {
  const ThirdPartyShareAttachmentAppendRequest({
    required this.memoUid,
    required this.attachmentUid,
    required this.filePath,
    required this.filename,
    required this.mimeType,
    required this.size,
    required this.kind,
    this.skipCompression = false,
    this.shareInlineImage = false,
    this.fromThirdPartyShare = true,
    this.sourceUrl,
    this.replaceSourceUrl,
  });

  final String memoUid;
  final String attachmentUid;
  final String filePath;
  final String filename;
  final String mimeType;
  final int size;
  final ThirdPartyShareAttachmentKind kind;
  final bool skipCompression;
  final bool shareInlineImage;
  final bool fromThirdPartyShare;
  final String? sourceUrl;
  final String? replaceSourceUrl;
}

class ThirdPartyShareAttachmentAppendResult {
  const ThirdPartyShareAttachmentAppendResult({
    required this.status,
    required this.memoUid,
    required this.attachmentUid,
    required this.localUrl,
  });

  final ThirdPartyShareAttachmentAppendStatus status;
  final String memoUid;
  final String attachmentUid;
  final String localUrl;

  bool get appended => status == ThirdPartyShareAttachmentAppendStatus.appended;
}

class ThirdPartyShareAttachmentAppender {
  ThirdPartyShareAttachmentAppender(this._ref);

  final Ref _ref;

  Future<ThirdPartyShareAttachmentAppendResult> append(
    ThirdPartyShareAttachmentAppendRequest request,
  ) async {
    final db = _ref.read(databaseProvider);
    final row = await db.getMemoByUid(request.memoUid);
    if (row == null) {
      throw StateError('Memo not found: ${request.memoUid}');
    }
    final memo = LocalMemo.fromDb(row);
    final duplicateName = 'attachments/${request.attachmentUid.trim()}';
    final duplicateUidExists = memo.attachments.any(
      (item) => item.name.trim() == duplicateName,
    );
    if (duplicateUidExists) {
      return ThirdPartyShareAttachmentAppendResult(
        status: ThirdPartyShareAttachmentAppendStatus.skippedDuplicate,
        memoUid: memo.uid,
        attachmentUid: request.attachmentUid,
        localUrl: '',
      );
    }

    final stager = _ref.read(queuedAttachmentStagerProvider);
    final staged = await stager.stageDraftAttachment(
      uid: request.attachmentUid,
      filePath: request.filePath,
      filename: request.filename,
      mimeType: request.mimeType,
      size: request.size,
      scopeKey: request.memoUid,
    );
    final localUrl = shareInlineLocalUrlFromPath(staged.filePath);
    final attachmentAlreadyExists = memo.attachments.any((item) {
      return item.externalLink.trim() == localUrl ||
          item.name.trim() == duplicateName;
    });
    if (attachmentAlreadyExists) {
      return ThirdPartyShareAttachmentAppendResult(
        status: ThirdPartyShareAttachmentAppendStatus.skippedDuplicate,
        memoUid: memo.uid,
        attachmentUid: staged.uid,
        localUrl: localUrl,
      );
    }

    var updatedContent = memo.content;
    final normalizedSourceUrl = request.sourceUrl?.trim().isNotEmpty == true
        ? request.sourceUrl!.trim()
        : request.replaceSourceUrl?.trim() ?? '';
    if (request.shareInlineImage) {
      final replaceSourceUrl =
          request.replaceSourceUrl?.trim().isNotEmpty == true
          ? request.replaceSourceUrl!.trim()
          : normalizedSourceUrl;
      if (replaceSourceUrl.isNotEmpty) {
        updatedContent = replaceShareInlineImageUrl(
          updatedContent,
          fromUrl: replaceSourceUrl,
          toUrl: localUrl,
        );
      }
      final originalLocalUrl = shareInlineLocalUrlFromPath(request.filePath);
      if (originalLocalUrl.isNotEmpty && originalLocalUrl != localUrl) {
        updatedContent = replaceShareInlineImageUrl(
          updatedContent,
          fromUrl: originalLocalUrl,
          toUrl: localUrl,
        );
      }
      final contentAlreadyContainsLocalUrl = contentContainsShareInlineImageUrl(
        updatedContent,
        localUrl,
      );
      if (updatedContent == memo.content && !contentAlreadyContainsLocalUrl) {
        return ThirdPartyShareAttachmentAppendResult(
          status: ThirdPartyShareAttachmentAppendStatus.skippedNotReferenced,
          memoUid: memo.uid,
          attachmentUid: staged.uid,
          localUrl: localUrl,
        );
      }
    }

    final updatedAttachments = <Map<String, dynamic>>[
      ...memo.attachments.map((item) => item.toJson()),
      Attachment(
        name: duplicateName,
        filename: staged.filename,
        type: staged.mimeType,
        size: staged.size,
        externalLink: localUrl,
      ).toJson(),
    ];
    final stagedUploadPayload = await stager.stageUploadPayload({
      'uid': staged.uid,
      'memo_uid': memo.uid,
      'file_path': staged.filePath,
      'filename': staged.filename,
      'mime_type': staged.mimeType,
      'file_size': staged.size,
      'skip_compression': request.skipCompression,
      'share_inline_image': request.shareInlineImage,
      'from_third_party_share': request.fromThirdPartyShare,
      if (request.shareInlineImage) 'share_inline_local_url': localUrl,
    }, scopeKey: memo.uid);

    await _ref
        .read(memoMutationServiceProvider)
        .appendThirdPartyShareAttachment(
          memo: memo,
          updatedContent: updatedContent,
          updatedAttachments: updatedAttachments,
          localUrl: localUrl,
          normalizedSourceUrl: normalizedSourceUrl,
          stagedUploadPayload: stagedUploadPayload,
        );

    return ThirdPartyShareAttachmentAppendResult(
      status: ThirdPartyShareAttachmentAppendStatus.appended,
      memoUid: memo.uid,
      attachmentUid: staged.uid,
      localUrl: localUrl,
    );
  }
}
