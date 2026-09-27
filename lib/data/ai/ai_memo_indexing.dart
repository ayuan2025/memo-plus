import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import '../models/content_fingerprint.dart';
import 'ai_analysis_models.dart';

final class AiMemoIndexing {
  const AiMemoIndexing._();

  static bool looksLikeGeneratedAiSummaryMemo(String content) {
    final normalized = content.replaceAll('\r\n', '\n').trimLeft();
    if (normalized.isEmpty) {
      return false;
    }

    const headerMarkers = <String>[
      '# \u672C\u9636\u6BB5\u56DE\u4FE1',
      '# Letter Back',
      '# AI Summary Report',
      '# AI \u6D1E\u5BDF',
    ];
    for (final marker in headerMarkers) {
      if (normalized.startsWith(marker)) {
        return true;
      }
    }

    var signalCount = 0;
    const contentSignals = <String>[
      '\u8FD9\u5C01\u56DE\u4FE1\u53C2\u8003\u4E86\u8FD9\u4E9B\u7247\u6BB5',
      'This letter drew on these note fragments',
      '\u5173\u952E\u6D1E\u5BDF',
      'Key Insights',
      '\u60C5\u7EEA\u8D8B\u52BF:',
      'Mood Trend:',
    ];
    for (final signal in contentSignals) {
      if (normalized.contains(signal)) {
        signalCount += 1;
        if (signalCount >= 2) {
          return true;
        }
      }
    }
    return false;
  }

  static List<AiChunkDraft> chunkMemo(Map<String, dynamic> memoRow) {
    final content = ((memoRow['content'] as String?) ?? '').trim();
    if (content.isEmpty) return const <AiChunkDraft>[];

    final memoContentHash = computeMemoContentHash(memoRow);
    final createTime = (memoRow['create_time'] as int?) ?? 0;
    final updateTime = (memoRow['update_time'] as int?) ?? 0;
    final visibility = (memoRow['visibility'] as String?)?.trim() ?? 'PRIVATE';

    final chunks = <AiChunkDraft>[];
    final paragraphPattern = RegExp(r'\n\s*\n');
    final matches = paragraphPattern
        .allMatches(content)
        .toList(growable: false);
    var cursor = 0;
    final spans = <_ContentSpan>[];
    for (final match in matches) {
      final end = match.start;
      if (end > cursor) {
        final text = content.substring(cursor, end).trim();
        if (isChunkableText(text)) {
          spans.add(
            _ContentSpan(
              start: cursor,
              end: end,
              text: content.substring(cursor, end),
            ),
          );
        }
      }
      cursor = match.end;
    }
    if (cursor < content.length) {
      final text = content.substring(cursor).trim();
      if (isChunkableText(text)) {
        spans.add(
          _ContentSpan(
            start: cursor,
            end: content.length,
            text: content.substring(cursor),
          ),
        );
      }
    }
    if (spans.isEmpty && isChunkableText(content)) {
      spans.add(_ContentSpan(start: 0, end: content.length, text: content));
    }

    var chunkIndex = 0;
    var currentStart = -1;
    var currentEnd = -1;
    var buffer = StringBuffer();

    void pushChunk() {
      final text = buffer.toString().trim();
      if (text.isEmpty || currentStart < 0 || currentEnd <= currentStart) {
        return;
      }
      chunks.add(
        AiChunkDraft(
          chunkIndex: chunkIndex,
          content: text,
          contentHash: sha1.convert(utf8.encode(text)).toString(),
          memoContentHash: memoContentHash,
          charStart: currentStart,
          charEnd: currentEnd,
          tokenEstimate: (utf8.encode(text).length / 4).ceil(),
          memoCreateTime: createTime,
          memoUpdateTime: updateTime,
          memoVisibility: visibility,
        ),
      );
      chunkIndex += 1;
    }

    for (final span in spans) {
      final trimmed = span.text.trim();
      if (trimmed.length > 600) {
        pushChunk();
        buffer = StringBuffer();
        currentStart = -1;
        currentEnd = -1;
        var splitStart = 0;
        while (splitStart < trimmed.length) {
          final splitEnd = math.min(trimmed.length, splitStart + 500);
          final piece = trimmed.substring(splitStart, splitEnd).trim();
          if (piece.isNotEmpty) {
            chunks.add(
              AiChunkDraft(
                chunkIndex: chunkIndex,
                content: piece,
                contentHash: sha1.convert(utf8.encode(piece)).toString(),
                memoContentHash: memoContentHash,
                charStart: span.start + splitStart,
                charEnd: span.start + splitEnd,
                tokenEstimate: (utf8.encode(piece).length / 4).ceil(),
                memoCreateTime: createTime,
                memoUpdateTime: updateTime,
                memoVisibility: visibility,
              ),
            );
            chunkIndex += 1;
          }
          if (splitEnd >= trimmed.length) break;
          splitStart = math.max(0, splitEnd - 60);
        }
        continue;
      }

      final nextLength = buffer.isEmpty
          ? trimmed.length
          : buffer.length + 2 + trimmed.length;
      if (buffer.isNotEmpty && nextLength > 500) {
        pushChunk();
        final overlapStart = math.max(currentEnd - 60, 0);
        final overlapText = content.substring(overlapStart, currentEnd).trim();
        buffer = StringBuffer();
        if (overlapText.isNotEmpty) {
          buffer.write(overlapText);
          currentStart = overlapStart;
        } else {
          currentStart = -1;
          currentEnd = -1;
        }
      }
      if (buffer.isNotEmpty) buffer.writeln();
      buffer.write(trimmed);
      currentStart = currentStart < 0 ? span.start : currentStart;
      currentEnd = span.end;
    }
    pushChunk();
    return chunks;
  }

  static bool isChunkableText(String text) {
    final normalized = text
        .replaceAll(RegExp(r'#[^\s#]+'), '')
        .replaceAll(RegExp(r'!\[[^\]]*\]\([^\)]*\)'), '')
        .replaceAll(
          RegExp(r'\[[^\]]*attachment[^\]]*\]', caseSensitive: false),
          '',
        )
        .trim();
    return normalized.isNotEmpty;
  }

  static bool memoRowAllowed(
    Map<String, dynamic> row, {
    required bool includePublic,
    required bool includePrivate,
    required bool includeProtected,
    bool Function(String content)? generatedSummaryDetector,
  }) {
    final allowAi = ((row['allow_ai'] as int?) ?? 1) == 1;
    final state = (row['state'] as String?)?.trim().toUpperCase() ?? 'NORMAL';
    final visibility =
        (row['visibility'] as String?)?.trim().toUpperCase() ?? 'PRIVATE';
    final content = ((row['content'] as String?) ?? '').trim();
    if (!allowAi || state != 'NORMAL' || content.isEmpty) return false;
    if (generatedSummaryDetector?.call(content) == true) return false;
    if (!includePublic && visibility == 'PUBLIC') return false;
    if (!includePrivate && visibility == 'PRIVATE') return false;
    if (!includeProtected && visibility == 'PROTECTED') return false;
    return true;
  }

  static String computeMemoContentHash(Map<String, dynamic> row) {
    final content = (row['content'] as String?) ?? '';
    final visibility = (row['visibility'] as String?) ?? '';
    return computeContentFingerprint('$visibility\n$content');
  }

  static AiMemoEmbeddingChunk candidateChunkFromRow(Map<String, dynamic> row) {
    return AiMemoEmbeddingChunk(
      chunkId: (row['id'] as int?) ?? 0,
      memoUid: (row['memo_uid'] as String?) ?? '',
      content: ((row['content'] as String?) ?? '').trim(),
      charStart: (row['char_start'] as int?) ?? 0,
      charEnd: (row['char_end'] as int?) ?? 0,
      memoCreateTime: (row['memo_create_time'] as int?) ?? 0,
      memoVisibility: (row['memo_visibility'] as String?) ?? 'PRIVATE',
      embeddingStatus: aiEmbeddingStatusFromStorage(
        (row['embedding_status'] as String?) ?? 'pending',
      ),
      vector: decodeFloat32VectorBlob(row['vector_blob']),
    );
  }

  static double cosineSimilarity(Float32List left, Float32List right) {
    if (left.length != right.length || left.isEmpty) return 0;
    var dot = 0.0;
    var leftNorm = 0.0;
    var rightNorm = 0.0;
    for (var index = 0; index < left.length; index++) {
      final l = left[index];
      final r = right[index];
      dot += l * r;
      leftNorm += l * l;
      rightNorm += r * r;
    }
    if (leftNorm <= 0 || rightNorm <= 0) return 0;
    return dot / (math.sqrt(leftNorm) * math.sqrt(rightNorm));
  }
}

final class AiMemoEmbeddingChunk {
  const AiMemoEmbeddingChunk({
    required this.chunkId,
    required this.memoUid,
    required this.content,
    required this.charStart,
    required this.charEnd,
    required this.memoCreateTime,
    required this.memoVisibility,
    required this.embeddingStatus,
    required this.vector,
  });

  final int chunkId;
  final String memoUid;
  final String content;
  final int charStart;
  final int charEnd;
  final int memoCreateTime;
  final String memoVisibility;
  final AiEmbeddingStatus embeddingStatus;
  final Float32List? vector;
}

final class _ContentSpan {
  const _ContentSpan({
    required this.start,
    required this.end,
    required this.text,
  });

  final int start;
  final int end;
  final String text;
}
