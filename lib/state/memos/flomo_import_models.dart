import '../../data/db/app_database.dart';

typedef ImportProgressCallback = void Function(ImportProgressUpdate update);
typedef ImportCancelCheck = bool Function();

class ImportException implements Exception {
  const ImportException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ImportCancelled implements Exception {
  const ImportCancelled();
}

class ImportProgressUpdate {
  const ImportProgressUpdate({
    required this.progress,
    this.statusText,
    this.progressLabel,
    this.progressDetail,
  });

  final double progress;
  final String? statusText;
  final String? progressLabel;
  final String? progressDetail;
}

class ImportResult {
  const ImportResult({
    required this.memoCount,
    required this.attachmentCount,
    required this.failedCount,
    required this.newTags,
  });

  final int memoCount;
  final int attachmentCount;
  final int failedCount;
  final List<String> newTags;
}

typedef FlomoImportDatabase = AppDatabase;