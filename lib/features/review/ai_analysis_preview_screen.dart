import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/memoflow_palette.dart';
import '../../i18n/strings.g.dart';
import '../../platform/widgets/platform_adaptive_layout.dart';
import '../../platform/widgets/platform_page.dart';
import 'ai_insight_models.dart';

class AiAnalysisPreviewScreen extends StatelessWidget {
  const AiAnalysisPreviewScreen({
    super.key,
    required this.definition,
    required this.payload,
    required this.allowPublic,
    required this.allowPrivate,
    required this.allowProtected,
    required this.rangeLabel,
  });

  final AiInsightDefinition definition;
  final AiAnalysisPreviewPayload payload;
  final bool allowPublic;
  final bool allowPrivate;
  final bool allowProtected;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? MemoFlowPalette.backgroundDark
        : MemoFlowPalette.backgroundLight;
    final card = isDark ? MemoFlowPalette.cardDark : MemoFlowPalette.cardLight;
    final border = isDark
        ? MemoFlowPalette.borderDark
        : MemoFlowPalette.borderLight;
    final textMain = isDark
        ? MemoFlowPalette.textDark
        : MemoFlowPalette.textLight;
    final textMuted = textMain.withValues(alpha: isDark ? 0.66 : 0.58);
    final dateFormatter = DateFormat('yyyy.MM.dd');
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';

    String formatVisibility(String value) {
      if (!isZh) return value.toUpperCase();
      return switch (value.trim().toUpperCase()) {
        'PRIVATE' => '私密',
        'PROTECTED' => '受保护',
        'PUBLIC' => '公开',
        _ => value.toUpperCase(),
      };
    }

    String formatEmbeddingStatusName(String value) {
      if (!isZh) return value;
      return switch (value.trim().toLowerCase()) {
        'ready' => '已就绪',
        'pending' => '处理中',
        'failed' => '失败',
        'stale' => '已失效',
        _ => value,
      };
    }

    final selectedVisibilities = <String>[
      if (allowPublic) isZh ? '公开' : 'Public',
      if (allowPrivate) isZh ? '私密' : 'Private',
      if (allowProtected) isZh ? '受保护' : 'Protected',
    ];

    return PlatformPage(
      backgroundColor: background,
      title: Text(isZh ? '检索预览' : 'Retrieval Preview'),
      body: PlatformBoundedContent(
        desktopMaxWidth: 860,
        tabletMaxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: card,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    definition.title(context),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: textMain,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _PreviewMetricRow(
                    label: isZh ? '匹配笔记数' : 'Matching memos',
                    value: '${payload.totalMatchingMemos}',
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: isZh ? '候选分片数' : 'Candidate chunks',
                    value: '${payload.candidateChunks}',
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: context.t.strings.aiInsight.contentPreview.timeRange,
                    value: rangeLabel,
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: isZh ? '可见性范围' : 'Visibility scope',
                    value: selectedVisibilities.isEmpty
                        ? (isZh ? '未选择' : 'None selected')
                        : selectedVisibilities.join(' / '),
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: isZh ? '向量已就绪' : 'Embeddings ready',
                    value: '${payload.embeddingReady}',
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: isZh ? '向量处理中' : 'Embeddings pending',
                    value: '${payload.embeddingPending}',
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  const SizedBox(height: 10),
                  _PreviewMetricRow(
                    label: isZh ? '向量失败数' : 'Embeddings failed',
                    value: '${payload.embeddingFailed}',
                    textColor: textMain,
                    mutedColor: textMuted,
                  ),
                  if (payload.isSampled) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: definition.accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        isZh
                            ? '候选集超过上限，当前预览为采样结果。'
                            : 'The candidate set exceeded the limit, so this preview is sampled.',
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                          color: textMain,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (payload.items.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: card,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: border),
                ),
                child: Text(
                  isZh
                      ? '当前没有可展示的证据片段。'
                      : 'No evidence snippets are available yet.',
                  style: TextStyle(fontSize: 14, height: 1.6, color: textMuted),
                ),
              )
            else
              for (final item in payload.items.reversed) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateFormatter.format(item.createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: definition.accent,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${formatVisibility(item.visibility)} · ${formatEmbeddingStatusName(item.embeddingStatus.name)}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: textMuted,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.content,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.55,
                          color: textMain,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
          ],
        ),
      ),
    );
  }
}

class _PreviewMetricRow extends StatelessWidget {
  const _PreviewMetricRow({
    required this.label,
    required this.value,
    required this.textColor,
    required this.mutedColor,
  });

  final String label;
  final String value;
  final Color textColor;
  final Color mutedColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: mutedColor,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ),
      ],
    );
  }
}
