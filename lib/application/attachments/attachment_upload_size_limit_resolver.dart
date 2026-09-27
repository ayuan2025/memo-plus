import '../../data/api/memos_api.dart';

typedef ReadIsLocalLibraryMode = bool Function();
typedef ReadMemosApi = MemosApi Function();

class AttachmentUploadSizeLimitResolver {
  const AttachmentUploadSizeLimitResolver({
    required ReadIsLocalLibraryMode readIsLocalLibraryMode,
    required ReadMemosApi readMemosApi,
  }) : _readIsLocalLibraryMode = readIsLocalLibraryMode,
       _readMemosApi = readMemosApi;

  final ReadIsLocalLibraryMode _readIsLocalLibraryMode;
  final ReadMemosApi _readMemosApi;

  Future<AttachmentUploadSizeLimit> resolve() async {
    if (_readIsLocalLibraryMode()) {
      return const AttachmentUploadSizeLimit.unknown(
        AttachmentUploadSizeLimitUnknownReason.localLibrary,
      );
    }
    try {
      return await _readMemosApi().getAttachmentUploadSizeLimit();
    } catch (_) {
      return const AttachmentUploadSizeLimit.unknown(
        AttachmentUploadSizeLimitUnknownReason.requestFailed,
      );
    }
  }
}
