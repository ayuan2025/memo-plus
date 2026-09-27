import '../../data/db/app_database.dart';

class WebDavBackupImportMutationService {
  WebDavBackupImportMutationService({required this.db});

  final AppDatabase db;

  Future<void> clearOutbox() {
    return db.clearOutbox();
  }
}
