import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../core/storage_read.dart';
import '../models/local_library.dart';

class LocalLibraryState {
  const LocalLibraryState({required this.libraries});

  final List<LocalLibrary> libraries;

  Map<String, dynamic> toJson() => {
        'libraries': libraries.map((l) => l.toJson()).toList(growable: false),
      };

  factory LocalLibraryState.fromJson(Map<String, dynamic> json) {
    final list = <LocalLibrary>[];
    final raw = json['libraries'];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          list.add(LocalLibrary.fromJson(item.cast<String, dynamic>()));
        }
      }
    }
    return LocalLibraryState(libraries: list);
  }
}

class LocalLibraryRepository {
  LocalLibraryRepository(this._storage);

  static const _kStateKey = 'local_library_state_v1';

  final FlutterSecureStorage _storage;

  Future<StorageReadResult<LocalLibraryState>> readWithStatus() async {
    String? raw;
    try {
      raw = await _storage.read(key: _kStateKey);
    } catch (error, stackTrace) {
      return StorageReadResult.failure(cause: error, stackTrace: stackTrace);
    }
    if (raw == null || raw.trim().isEmpty) {
      return StorageReadResult.empty();
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return StorageReadResult.success(
          LocalLibraryState.fromJson(decoded.cast<String, dynamic>()),
        );
      }
      return StorageReadResult.failure(
        cause: const FormatException('Expected JSON object'),
        stackTrace: StackTrace.current,
      );
    } catch (error, stackTrace) {
      return StorageReadResult.failure(cause: error, stackTrace: stackTrace);
    }
  }

  Future<LocalLibraryState> read() async {
    final result = await readWithStatus();
    if (result.isSuccess) {
      return result.data!;
    }
    return const LocalLibraryState(libraries: []);
  }

  Future<void> write(LocalLibraryState state) async {
    await _storage.write(key: _kStateKey, value: jsonEncode(state.toJson()));
  }

  Future<void> clear() async {
    await _storage.delete(key: _kStateKey);
  }
}
