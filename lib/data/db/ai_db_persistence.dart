import 'dart:convert';
import 'dart:typed_data';

import 'package:sqflite/sqflite.dart';

import '../ai/ai_analysis_models.dart';
import '../ai/ai_settings_models.dart';

final class AiDbPersistence {
  const AiDbPersistence._();

  static Future<void> ensureTables(Database db) async {
    await ensureMemoPolicyTable(db);
    await ensureChunksTable(db);
    await ensureEmbeddingsTable(db);
    await ensureIndexJobsTable(db);
    await ensureAnalysisTasksTable(db);
    await ensureAnalysisResultsTable(db);
    await ensureAnalysisSectionsTable(db);
    await ensureAnalysisEvidencesTable(db);
  }

  static Future<void> ensureMemoPolicyTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_memo_policy (
  memo_uid TEXT PRIMARY KEY,
  allow_ai INTEGER NOT NULL DEFAULT 1,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (memo_uid) REFERENCES memos(uid) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
  }

  static Future<void> ensureChunksTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_chunks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT NOT NULL,
  chunk_index INTEGER NOT NULL,
  content TEXT NOT NULL,
  content_hash TEXT NOT NULL,
  memo_content_hash TEXT NOT NULL,
  char_start INTEGER NOT NULL,
  char_end INTEGER NOT NULL,
  token_estimate INTEGER NOT NULL,
  memo_create_time INTEGER NOT NULL,
  memo_update_time INTEGER NOT NULL,
  memo_visibility TEXT NOT NULL,
  is_active INTEGER NOT NULL DEFAULT 1,
  invalidated_time INTEGER,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (memo_uid) REFERENCES memos(uid) ON DELETE CASCADE ON UPDATE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_chunks_memo_active_idx ON ai_chunks(memo_uid, is_active, chunk_index);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_chunks_time_active ON ai_chunks(memo_create_time DESC, is_active);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_chunks_content_hash ON ai_chunks(content_hash);',
    );
  }

  static Future<void> ensureEmbeddingsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_embeddings (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  chunk_id INTEGER NOT NULL,
  backend_kind TEXT NOT NULL,
  provider_kind TEXT NOT NULL,
  base_url TEXT NOT NULL,
  model TEXT NOT NULL,
  model_version TEXT NOT NULL DEFAULT '',
  dimensions INTEGER NOT NULL,
  vector_blob BLOB,
  status TEXT NOT NULL,
  error_text TEXT,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (chunk_id) REFERENCES ai_chunks(id) ON DELETE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_embeddings_chunk_status ON ai_embeddings(chunk_id, status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_embeddings_model_status ON ai_embeddings(model, status);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_embeddings_profile ON ai_embeddings(base_url, model, chunk_id);',
    );
  }

  static Future<void> ensureIndexJobsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_index_jobs (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  memo_uid TEXT,
  reason TEXT NOT NULL,
  memo_content_hash TEXT NOT NULL DEFAULT '',
  embedding_profile_key TEXT NOT NULL,
  status TEXT NOT NULL,
  attempt_count INTEGER NOT NULL DEFAULT 0,
  priority INTEGER NOT NULL DEFAULT 100,
  retry_at INTEGER,
  error_text TEXT,
  created_time INTEGER NOT NULL,
  started_time INTEGER,
  finished_time INTEGER
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_index_jobs_status_priority ON ai_index_jobs(status, priority, created_time);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_index_jobs_memo_profile_hash ON ai_index_jobs(memo_uid, embedding_profile_key, memo_content_hash);',
    );
  }

  static Future<void> ensureAnalysisTasksTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_analysis_tasks (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_uid TEXT NOT NULL UNIQUE,
  analysis_type TEXT NOT NULL,
  status TEXT NOT NULL,
  range_start INTEGER NOT NULL,
  range_end_exclusive INTEGER NOT NULL,
  include_public INTEGER NOT NULL DEFAULT 1,
  include_private INTEGER NOT NULL DEFAULT 0,
  include_protected INTEGER NOT NULL DEFAULT 0,
  prompt_template TEXT NOT NULL,
  template_kind TEXT NOT NULL DEFAULT 'legacy',
  template_id TEXT NOT NULL DEFAULT '',
  template_title_snapshot TEXT NOT NULL DEFAULT '',
  template_icon_key_snapshot TEXT NOT NULL DEFAULT '',
  generation_profile_key TEXT NOT NULL,
  embedding_profile_key TEXT NOT NULL,
  retrieval_profile_json TEXT NOT NULL,
  error_text TEXT,
  mailbox_delivery_state TEXT NOT NULL DEFAULT 'hidden',
  mailbox_open_state TEXT NOT NULL DEFAULT 'unread',
  reply_animation_state TEXT NOT NULL DEFAULT 'idle',
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  completed_time INTEGER
);
''');
    await ensureAnalysisTaskIncludePublicColumn(db);
    await ensureAnalysisTaskTemplateColumns(db);
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_tasks_status_time ON ai_analysis_tasks(status, created_time DESC);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_tasks_type_time ON ai_analysis_tasks(analysis_type, created_time DESC);',
    );
  }

  static Future<void> ensureAnalysisTaskIncludePublicColumn(Database db) async {
    await _ensureColumnExists(
      db,
      table: 'ai_analysis_tasks',
      column: 'include_public',
      definition: 'include_public INTEGER NOT NULL DEFAULT 1',
    );
  }

  static Future<void> ensureAnalysisTaskTemplateColumns(Database db) async {
    await _ensureColumnExists(
      db,
      table: 'ai_analysis_tasks',
      column: 'template_kind',
      definition: "template_kind TEXT NOT NULL DEFAULT 'legacy'",
    );
    await _ensureColumnExists(
      db,
      table: 'ai_analysis_tasks',
      column: 'template_id',
      definition: "template_id TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      table: 'ai_analysis_tasks',
      column: 'template_title_snapshot',
      definition: "template_title_snapshot TEXT NOT NULL DEFAULT ''",
    );
    await _ensureColumnExists(
      db,
      table: 'ai_analysis_tasks',
      column: 'template_icon_key_snapshot',
      definition: "template_icon_key_snapshot TEXT NOT NULL DEFAULT ''",
    );
  }

  static Future<void> ensureAnalysisResultsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_analysis_results (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  task_id INTEGER NOT NULL UNIQUE,
  schema_version INTEGER NOT NULL,
  analysis_type TEXT NOT NULL,
  summary TEXT NOT NULL,
  follow_up_suggestions_json TEXT NOT NULL,
  raw_response_text TEXT NOT NULL DEFAULT '',
  normalized_result_json TEXT NOT NULL,
  is_stale INTEGER NOT NULL DEFAULT 0,
  created_time INTEGER NOT NULL,
  updated_time INTEGER NOT NULL,
  FOREIGN KEY (task_id) REFERENCES ai_analysis_tasks(id) ON DELETE CASCADE
);
''');
  }

  static Future<void> ensureAnalysisSectionsTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_analysis_sections (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result_id INTEGER NOT NULL,
  section_key TEXT NOT NULL,
  section_order INTEGER NOT NULL,
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  created_time INTEGER NOT NULL,
  FOREIGN KEY (result_id) REFERENCES ai_analysis_results(id) ON DELETE CASCADE,
  UNIQUE(result_id, section_key)
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_sections_result_order ON ai_analysis_sections(result_id, section_order);',
    );
  }

  static Future<void> ensureAnalysisEvidencesTable(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS ai_analysis_evidences (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  result_id INTEGER NOT NULL,
  section_id INTEGER NOT NULL,
  evidence_order INTEGER NOT NULL,
  memo_uid TEXT NOT NULL,
  chunk_id INTEGER NOT NULL,
  quote_text TEXT NOT NULL,
  char_start INTEGER NOT NULL,
  char_end INTEGER NOT NULL,
  relevance_score REAL NOT NULL,
  created_time INTEGER NOT NULL,
  FOREIGN KEY (result_id) REFERENCES ai_analysis_results(id) ON DELETE CASCADE,
  FOREIGN KEY (section_id) REFERENCES ai_analysis_sections(id) ON DELETE CASCADE,
  FOREIGN KEY (chunk_id) REFERENCES ai_chunks(id) ON DELETE CASCADE
);
''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_evidences_result_section_order ON ai_analysis_evidences(result_id, section_id, evidence_order);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_evidences_memo_uid ON ai_analysis_evidences(memo_uid);',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ai_analysis_evidences_chunk_id ON ai_analysis_evidences(chunk_id);',
    );
  }

  static Future<void> upsertMemoPolicy(
    DatabaseExecutor executor, {
    required String memoUid,
    required bool allowAi,
  }) async {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await executor.insert('ai_memo_policy', <String, Object?>{
      'memo_uid': trimmedUid,
      'allow_ai': allowAi ? 1 : 0,
      'updated_time': now,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<int> enqueueIndexJob(
    DatabaseExecutor executor, {
    required String? memoUid,
    required AiIndexJobReason reason,
    required String memoContentHash,
    required String embeddingProfileKey,
    int priority = 100,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return executor.insert('ai_index_jobs', <String, Object?>{
      'memo_uid': memoUid?.trim(),
      'reason': aiIndexJobReasonToStorage(reason),
      'memo_content_hash': memoContentHash,
      'embedding_profile_key': embeddingProfileKey,
      'status': aiIndexJobStatusToStorage(AiIndexJobStatus.queued),
      'attempt_count': 0,
      'priority': priority,
      'created_time': now,
    });
  }

  static Future<void> updateIndexJobStatus(
    DatabaseExecutor executor,
    int jobId, {
    required AiIndexJobStatus status,
    int? attemptCount,
    String? errorText,
    bool markStarted = false,
    bool markFinished = false,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final values = <String, Object?>{
      'status': aiIndexJobStatusToStorage(status),
      'error_text': errorText,
    };
    if (attemptCount != null) {
      values['attempt_count'] = attemptCount;
    }
    if (markStarted) {
      values['started_time'] = now;
    }
    if (markFinished) {
      values['finished_time'] = now;
    }
    await executor.update(
      'ai_index_jobs',
      values,
      where: 'id = ?',
      whereArgs: <Object?>[jobId],
    );
  }

  static Future<void> invalidateActiveChunksForMemo(
    DatabaseExecutor executor,
    String memoUid,
  ) async {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rows = await executor.query(
      'ai_chunks',
      columns: const ['id'],
      where: 'memo_uid = ? AND is_active = 1',
      whereArgs: <Object?>[trimmedUid],
    );
    final chunkIds = rows
        .map((row) => _readInt(row['id']))
        .whereType<int>()
        .toList(growable: false);
    await executor.update(
      'ai_chunks',
      <String, Object?>{
        'is_active': 0,
        'invalidated_time': now,
        'updated_time': now,
      },
      where: 'memo_uid = ? AND is_active = 1',
      whereArgs: <Object?>[trimmedUid],
    );
    if (chunkIds.isNotEmpty) {
      final placeholders = List.filled(chunkIds.length, '?').join(', ');
      await executor.rawUpdate(
        'UPDATE ai_embeddings SET status = ?, updated_time = ? WHERE chunk_id IN ($placeholders) AND status != ?',
        <Object?>[
          aiEmbeddingStatusToStorage(AiEmbeddingStatus.stale),
          now,
          ...chunkIds,
          aiEmbeddingStatusToStorage(AiEmbeddingStatus.stale),
        ],
      );
    }
    await markResultsStaleForMemo(executor, trimmedUid, nowMs: now);
  }

  static Future<List<int>> insertActiveChunks(
    DatabaseExecutor executor, {
    required String memoUid,
    required List<AiChunkDraft> chunks,
  }) async {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty || chunks.isEmpty) return const <int>[];
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final ids = <int>[];
    for (final chunk in chunks) {
      final id = await executor.insert('ai_chunks', <String, Object?>{
        'memo_uid': trimmedUid,
        'chunk_index': chunk.chunkIndex,
        'content': chunk.content,
        'content_hash': chunk.contentHash,
        'memo_content_hash': chunk.memoContentHash,
        'char_start': chunk.charStart,
        'char_end': chunk.charEnd,
        'token_estimate': chunk.tokenEstimate,
        'memo_create_time': chunk.memoCreateTime,
        'memo_update_time': chunk.memoUpdateTime,
        'memo_visibility': chunk.memoVisibility,
        'is_active': 1,
        'created_time': now,
        'updated_time': now,
      });
      ids.add(id);
    }
    return ids;
  }

  static Future<void> insertEmbeddingRecord(
    DatabaseExecutor executor, {
    required int chunkId,
    required AiEmbeddingProfile profile,
    required AiEmbeddingStatus status,
    Float32List? vector,
    String? errorText,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    Uint8List? vectorBlob;
    var dimensions = 0;
    if (vector != null && vector.isNotEmpty) {
      vectorBlob = vector.buffer.asUint8List(
        vector.offsetInBytes,
        vector.lengthInBytes,
      );
      dimensions = vector.length;
    }
    await executor.insert('ai_embeddings', <String, Object?>{
      'chunk_id': chunkId,
      'backend_kind': _backendKindToStorage(profile.backendKind),
      'provider_kind': _providerKindToStorage(profile.providerKind),
      'base_url': profile.baseUrl,
      'model': profile.model,
      'model_version': '',
      'dimensions': dimensions,
      'vector_blob': vectorBlob,
      'status': aiEmbeddingStatusToStorage(status),
      'error_text': errorText,
      'created_time': now,
      'updated_time': now,
    });
  }

  static Future<int> createAnalysisTask(
    DatabaseExecutor executor, {
    required String taskUid,
    required AiAnalysisType analysisType,
    required AiTaskStatus status,
    required int rangeStart,
    required int rangeEndExclusive,
    required bool includePublic,
    required bool includePrivate,
    required bool includeProtected,
    required String promptTemplate,
    AiAnalysisTemplateKind templateKind = AiAnalysisTemplateKind.legacy,
    String templateId = '',
    String templateTitleSnapshot = '',
    String templateIconKeySnapshot = '',
    required String generationProfileKey,
    required String embeddingProfileKey,
    required Map<String, dynamic> retrievalProfile,
  }) {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    return executor.insert('ai_analysis_tasks', <String, Object?>{
      'task_uid': taskUid,
      'analysis_type': aiAnalysisTypeToStorage(analysisType),
      'status': aiTaskStatusToStorage(status),
      'range_start': rangeStart,
      'range_end_exclusive': rangeEndExclusive,
      'include_public': includePublic ? 1 : 0,
      'include_private': includePrivate ? 1 : 0,
      'include_protected': includeProtected ? 1 : 0,
      'prompt_template': promptTemplate,
      'template_kind': aiAnalysisTemplateKindToStorage(templateKind),
      'template_id': templateId.trim(),
      'template_title_snapshot': templateTitleSnapshot.trim(),
      'template_icon_key_snapshot': templateIconKeySnapshot.trim(),
      'generation_profile_key': generationProfileKey,
      'embedding_profile_key': embeddingProfileKey,
      'retrieval_profile_json': jsonEncode(retrievalProfile),
      'mailbox_delivery_state': 'hidden',
      'mailbox_open_state': 'unread',
      'reply_animation_state': 'idle',
      'created_time': now,
      'updated_time': now,
    });
  }

  static Future<void> updateAnalysisTaskStatus(
    DatabaseExecutor executor,
    int taskId, {
    required AiTaskStatus status,
    String? errorText,
    bool markCompleted = false,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    await executor.update(
      'ai_analysis_tasks',
      <String, Object?>{
        'status': aiTaskStatusToStorage(status),
        'error_text': errorText,
        'updated_time': now,
        if (markCompleted) 'completed_time': now,
      },
      where: 'id = ?',
      whereArgs: <Object?>[taskId],
    );
  }

  static Future<void> saveAnalysisResult(
    DatabaseExecutor executor, {
    required int taskId,
    required AiStructuredAnalysisResult result,
  }) async {
    final now = DateTime.now().toUtc().millisecondsSinceEpoch;
    final resultId = await executor
        .insert('ai_analysis_results', <String, Object?>{
          'task_id': taskId,
          'schema_version': result.schemaVersion,
          'analysis_type': aiAnalysisTypeToStorage(result.analysisType),
          'summary': result.summary,
          'follow_up_suggestions_json': jsonEncode(result.followUpSuggestions),
          'raw_response_text': result.rawResponseText,
          'normalized_result_json': result.normalizedResultJson,
          'is_stale': 0,
          'created_time': now,
          'updated_time': now,
        });
    final sectionIdByKey = <String, int>{};
    for (var index = 0; index < result.sections.length; index++) {
      final section = result.sections[index];
      final sectionId = await executor
          .insert('ai_analysis_sections', <String, Object?>{
            'result_id': resultId,
            'section_key': section.sectionKey,
            'section_order': index,
            'title': section.title,
            'body': section.body,
            'created_time': now,
          });
      sectionIdByKey[section.sectionKey] = sectionId;
    }
    for (var index = 0; index < result.evidences.length; index++) {
      final evidence = result.evidences[index];
      final sectionId = sectionIdByKey[evidence.sectionKey];
      if (sectionId == null) continue;
      await executor.insert('ai_analysis_evidences', <String, Object?>{
        'result_id': resultId,
        'section_id': sectionId,
        'evidence_order': index,
        'memo_uid': evidence.memoUid,
        'chunk_id': evidence.chunkId,
        'quote_text': evidence.quoteText,
        'char_start': evidence.charStart,
        'char_end': evidence.charEnd,
        'relevance_score': evidence.relevanceScore,
        'created_time': now,
      });
    }
  }

  static Future<void> markResultsStaleForMemo(
    DatabaseExecutor executor,
    String memoUid, {
    int? nowMs,
  }) async {
    final trimmedUid = memoUid.trim();
    if (trimmedUid.isEmpty) return;
    final now = nowMs ?? DateTime.now().toUtc().millisecondsSinceEpoch;
    await executor.rawUpdate(
      '''
UPDATE ai_analysis_results
SET is_stale = 1,
    updated_time = ?
WHERE id IN (
  SELECT DISTINCT result_id
  FROM ai_analysis_evidences
  WHERE memo_uid = ?
);
''',
      <Object?>[now, trimmedUid],
    );
  }

  static Future<void> _ensureColumnExists(
    Database db, {
    required String table,
    required String column,
    required String definition,
  }) async {
    final rows = await db.rawQuery(
      'PRAGMA table_info(${_quoteIdentifier(table)});',
    );
    if (rows.any((row) => row['name'] == column)) {
      return;
    }
    await db.execute(
      'ALTER TABLE ${_quoteIdentifier(table)} ADD COLUMN $definition;',
    );
  }

  static String _quoteIdentifier(String identifier) {
    final escaped = identifier.replaceAll('"', '""');
    return '"$escaped"';
  }

  static int? _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  static String _backendKindToStorage(AiBackendKind value) => switch (value) {
    AiBackendKind.remoteApi => 'remote_api',
    AiBackendKind.localApi => 'local_api',
  };

  static String _providerKindToStorage(AiProviderKind value) => switch (value) {
    AiProviderKind.openAiCompatible => 'openai_compatible',
    AiProviderKind.anthropicCompatible => 'anthropic_compatible',
  };
}
