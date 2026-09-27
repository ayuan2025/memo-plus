class StorageLoadError {
  const StorageLoadError({
    required this.source,
    required this.error,
    required this.stackTrace,
  });

  final String source;
  final Object error;
  final StackTrace stackTrace;
}

enum StorageReadStatus { success, empty, error }

class StorageReadResult<T> {
  const StorageReadResult._({
    required this.status,
    this.data,
    this.error,
    this.stackTrace,
  });

  final StorageReadStatus status;
  final T? data;
  final Object? error;
  final StackTrace? stackTrace;

  bool get isSuccess => status == StorageReadStatus.success;
  bool get isEmpty => status == StorageReadStatus.empty;
  bool get isError => status == StorageReadStatus.error;

  static StorageReadResult<T> success<T>(T value) =>
      StorageReadResult<T>._(status: StorageReadStatus.success, data: value);

  static StorageReadResult<T> empty<T>() =>
      StorageReadResult<T>._(status: StorageReadStatus.empty);

  static StorageReadResult<T> failure<T>({
    required Object cause,
    required StackTrace stackTrace,
  }) =>
      StorageReadResult<T>._(
        status: StorageReadStatus.error,
        error: cause,
        stackTrace: stackTrace,
      );
}
