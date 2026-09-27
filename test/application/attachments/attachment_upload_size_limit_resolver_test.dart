import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/application/attachments/attachment_upload_size_limit_resolver.dart';
import 'package:memos_flutter_app/data/api/memo_api_facade.dart';
import 'package:memos_flutter_app/data/api/memo_api_version.dart';
import 'package:memos_flutter_app/data/api/memos_api.dart';

void main() {
  group('AttachmentUploadSizeLimitResolver', () {
    test('local library returns unknown without reading remote api', () async {
      var apiRead = false;
      final resolver = AttachmentUploadSizeLimitResolver(
        readIsLocalLibraryMode: () => true,
        readMemosApi: () {
          apiRead = true;
          return _unusedApi();
        },
      );

      final limit = await resolver.resolve();

      expect(limit.isUnknown, isTrue);
      expect(
        limit.unknownReason,
        AttachmentUploadSizeLimitUnknownReason.localLibrary,
      );
      expect(apiRead, isFalse);
    });

    test('remote api read failure returns unknown request failure', () async {
      final resolver = AttachmentUploadSizeLimitResolver(
        readIsLocalLibraryMode: () => false,
        readMemosApi: () => throw StateError('not authenticated'),
      );

      final limit = await resolver.resolve();

      expect(limit.isUnknown, isTrue);
      expect(
        limit.unknownReason,
        AttachmentUploadSizeLimitUnknownReason.requestFailed,
      );
    });
  });
}

MemosApi _unusedApi() {
  return MemoApiFacade.authenticated(
    baseUrl: Uri.parse('http://127.0.0.1'),
    personalAccessToken: 'unused',
    version: MemoApiVersion.v027,
  );
}
