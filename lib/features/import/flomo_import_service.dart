export '../../state/memos/flomo_import_models.dart';

import '../../data/models/account.dart';
import '../../data/models/app_preferences.dart';
import '../../state/memos/flomo_import_controller.dart';
import '../../state/memos/flomo_import_models.dart';

class FlomoImportService {
  FlomoImportService({
    required this.db,
    required this.language,
    this.account,
    this.importScopeKey,
  });

  final FlomoImportDatabase db;
  final Account? account;
  final String? importScopeKey;
  final AppLanguage language;

  Future<ImportResult> importFile({
    required String filePath,
    required ImportProgressCallback onProgress,
    required ImportCancelCheck isCancelled,
  }) async {
    return const FlomoImportController().importFlomo(
      db: db,
      language: language,
      account: account,
      importScopeKey: importScopeKey,
      filePath: filePath,
      onProgress: onProgress,
      isCancelled: isCancelled,
    );
  }
}