import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/attachments/attachment_upload_size_limit_resolver.dart';
import '../system/local_library_provider.dart';
import 'memos_providers.dart';

final attachmentUploadSizeLimitResolverProvider =
    Provider<AttachmentUploadSizeLimitResolver>((ref) {
      return AttachmentUploadSizeLimitResolver(
        readIsLocalLibraryMode: () =>
            ref.read(currentLocalLibraryProvider) != null,
        readMemosApi: () => ref.read(memosApiProvider),
      );
    });
