import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/ai/ai_semantic_memo_search_service.dart';
import 'package:memos_flutter_app/data/models/attachment.dart';
import 'package:memos_flutter_app/data/models/local_memo.dart';
import 'package:memos_flutter_app/data/models/memo_location.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';

void main() {
  group('AdvancedSearchFilters.matches', () {
    test('matches created date range inclusively by day', () {
      final filters = AdvancedSearchFilters(
        createdDateRange: DateTimeRange(
          start: DateTime(2025, 1, 1),
          end: DateTime(2025, 1, 31),
        ),
      );

      expect(
        filters.matches(_memo(createTime: DateTime(2025, 1, 1, 0, 0, 0))),
        isTrue,
      );
      expect(
        filters.matches(_memo(createTime: DateTime(2025, 1, 31, 23, 59, 59))),
        isTrue,
      );
      expect(
        filters.matches(_memo(createTime: DateTime(2024, 12, 31, 23, 59, 59))),
        isFalse,
      );
      expect(
        filters.matches(_memo(createTime: DateTime(2025, 2, 1, 0, 0, 0))),
        isFalse,
      );
    });

    test('matches location presence and location contains', () {
      final memo = _memo(
        location: const MemoLocation(
          placeholder: 'Shanghai Pudong',
          latitude: 31.2,
          longitude: 121.5,
        ),
      );

      expect(
        const AdvancedSearchFilters(
          hasLocation: SearchToggleFilter.yes,
        ).matches(memo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          hasLocation: SearchToggleFilter.no,
        ).matches(memo),
        isFalse,
      );
      expect(
        const AdvancedSearchFilters(locationContains: 'pudong').matches(memo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(locationContains: 'beijing').matches(memo),
        isFalse,
      );
    });

    test('matches attachment presence and attachment name fallback', () {
      final memo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/abc123',
            filename: '',
            type: 'text/plain',
            size: 1,
            externalLink: '',
          ),
        ],
      );

      expect(
        const AdvancedSearchFilters(
          hasAttachments: SearchToggleFilter.yes,
        ).matches(memo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          hasAttachments: SearchToggleFilter.no,
        ).matches(memo),
        isFalse,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentNameContains: 'abc123',
        ).matches(memo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentNameContains: 'missing',
        ).matches(memo),
        isFalse,
      );
    });

    test('matches attachment types', () {
      final imageMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/image',
            filename: 'photo.jpg',
            type: 'image/jpeg',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final audioMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/audio',
            filename: 'voice.m4a',
            type: 'audio/mp4',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final documentMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/document',
            filename: 'invoice.pdf',
            type: 'application/pdf',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final docxMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/docx',
            filename: 'report.docx',
            type:
                'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final ofdMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/ofd',
            filename: 'invoice.ofd',
            type: 'application/ofd',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final xmlMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/xml',
            filename: 'fapiao.xml',
            type: 'application/xml',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final otherMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/other',
            filename: 'archive.zip',
            type: 'application/zip',
            size: 1,
            externalLink: '',
          ),
        ],
      );
      final videoMemo = _memo(
        attachments: const [
          Attachment(
            name: 'attachments/video',
            filename: 'clip.mp4',
            type: 'video/mp4',
            size: 1,
            externalLink: '',
          ),
        ],
      );

      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.image,
        ).matches(imageMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.audio,
        ).matches(audioMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.document,
        ).matches(documentMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.document,
        ).matches(docxMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.document,
        ).matches(ofdMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.document,
        ).matches(xmlMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.other,
        ).matches(otherMemo),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          attachmentType: AdvancedAttachmentType.other,
        ).matches(videoMemo),
        isTrue,
      );
    });

    test('matches relation presence', () {
      final linked = _memo(relationCount: 2);
      final unlinked = _memo(relationCount: 0);

      expect(
        const AdvancedSearchFilters(
          hasRelations: SearchToggleFilter.yes,
        ).matches(linked),
        isTrue,
      );
      expect(
        const AdvancedSearchFilters(
          hasRelations: SearchToggleFilter.yes,
        ).matches(unlinked),
        isFalse,
      );
      expect(
        const AdvancedSearchFilters(
          hasRelations: SearchToggleFilter.no,
        ).matches(unlinked),
        isTrue,
      );
    });
  });

  group('AdvancedSearchFilters.normalized', () {
    test('keeps location text when location is any', () {
      final normalized = const AdvancedSearchFilters(
        locationContains: 'shanghai',
      ).normalized();

      expect(normalized.hasLocation, SearchToggleFilter.any);
      expect(normalized.locationContains, 'shanghai');
    });

    test('clears location text when location is no', () {
      final normalized = const AdvancedSearchFilters(
        hasLocation: SearchToggleFilter.no,
        locationContains: 'shanghai',
      ).normalized();

      expect(normalized.hasLocation, SearchToggleFilter.no);
      expect(normalized.locationContains, isEmpty);
    });

    test('keeps attachment details when attachments is any', () {
      final normalized = const AdvancedSearchFilters(
        attachmentNameContains: 'invoice',
        attachmentType: AdvancedAttachmentType.document,
      ).normalized();

      expect(normalized.hasAttachments, SearchToggleFilter.any);
      expect(normalized.attachmentNameContains, 'invoice');
      expect(normalized.attachmentType, AdvancedAttachmentType.document);
    });

    test('clears attachment detail fields when attachments is no', () {
      final normalized = const AdvancedSearchFilters(
        hasAttachments: SearchToggleFilter.no,
        attachmentNameContains: 'invoice',
        attachmentType: AdvancedAttachmentType.document,
      ).normalized();

      expect(normalized.hasAttachments, SearchToggleFilter.no);
      expect(normalized.attachmentNameContains, isEmpty);
      expect(normalized.attachmentType, isNull);
    });
  });

  group('AI search result filtering', () {
    test('applies advanced filters before result limit', () {
      final hits = <AiSemanticMemoSearchHit>[
        _semanticHit(_memo(uid: 'memo-no-relations')),
        _semanticHit(_memo(uid: 'memo-related-1', relationCount: 1)),
        _semanticHit(_memo(uid: 'memo-related-2', relationCount: 2)),
      ];

      final filtered = filterAiSearchHitsForMemoList(
        hits,
        advancedFilters: const AdvancedSearchFilters(
          hasRelations: SearchToggleFilter.yes,
        ),
        pageSize: 1,
      );

      expect(filtered.map((memo) => memo.uid), <String>['memo-related-1']);
    });

    test('keeps ranked order for keyword-default handoff', () {
      final hits = <AiSemanticMemoSearchHit>[
        _semanticHit(_memo(uid: 'memo-first')),
        _semanticHit(_memo(uid: 'memo-second')),
        _semanticHit(_memo(uid: 'memo-third')),
      ];

      final filtered = filterAiSearchHitsForMemoList(
        hits,
        advancedFilters: AdvancedSearchFilters.empty,
        pageSize: 2,
      );

      expect(filtered.map((memo) => memo.uid), <String>[
        'memo-first',
        'memo-second',
      ]);
    });
  });
}

LocalMemo _memo({
  String uid = 'memo-1',
  DateTime? createTime,
  List<Attachment> attachments = const [],
  MemoLocation? location,
  int relationCount = 0,
}) {
  return LocalMemo(
    uid: uid,
    content: 'memo content',
    contentFingerprint: 'fingerprint',
    visibility: 'PRIVATE',
    pinned: false,
    state: 'NORMAL',
    createTime: createTime ?? DateTime(2025, 1, 15, 9),
    updateTime: createTime ?? DateTime(2025, 1, 15, 9),
    tags: const [],
    attachments: attachments,
    relationCount: relationCount,
    location: location,
    syncState: SyncState.synced,
    lastError: null,
  );
}

AiSemanticMemoSearchHit _semanticHit(LocalMemo memo) {
  return AiSemanticMemoSearchHit(
    memo: memo,
    score: 1,
    bestChunkId: 1,
    bestChunkText: memo.content,
    matchingChunkCount: 1,
  );
}
