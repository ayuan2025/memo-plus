import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../../data/models/local_memo.dart';
import '../memo_markdown.dart';
import 'memo_card_theme.dart';

/// 笔记分享卡片：把一条 memo 渲染成「纸面卡片」，可经 [captureWidgetPng] 导出 PNG。
///
/// 结构：纸面圆角容器（带暖色投影）+ 标题 + 时间 + Markdown 正文（[MemoMarkdown]，
/// 外层套 [Theme] 应用卡片主题配色）+ 底部分隔线 + 品牌页脚。
class MemoShareCard extends StatelessWidget {
  const MemoShareCard({
    super.key,
    required this.memo,
    required this.theme,
    this.footerBrand = 'memo+',
    this.footerVia = '由 memo+ 生成',
    this.width = 360,
  });

  final LocalMemo memo;
  final MemoCardTheme theme;
  final String footerBrand;
  final String footerVia;
  final double width;

  @override
  Widget build(BuildContext context) {
    return MemoCardPaper(
      title: deriveCardTitle(memo.content),
      timeText: formatCardTime(memo.effectiveDisplayTime),
      body: memo.content,
      theme: theme,
      footerBrand: footerBrand,
      footerVia: footerVia,
      width: width,
    );
  }
}

/// 纸面卡片本体：标题 + 时间 + Markdown 正文 + 品牌页脚。
///
/// [MemoShareCard]（导出图片）与 `MemoThemedPreview`（编辑器/阅读页内嵌预览）
/// 共用这一个排版实现，改样式只需改这里。
class MemoCardPaper extends StatelessWidget {
  const MemoCardPaper({
    super.key,
    required this.body,
    required this.theme,
    required this.timeText,
    this.title,
    this.footerBrand = 'memo+',
    this.footerVia = '由 memo+ 生成',
    this.width = 360,
    this.showFooter = true,
  });

  /// Markdown 正文源文本。
  final String body;

  /// 卡片主题（[kMemoCardThemes] 之一）。
  final MemoCardTheme theme;

  /// 已格式化的时间文本。
  final String timeText;

  /// 卡片标题；为空则不渲染标题行。
  final String? title;

  final String footerBrand;
  final String footerVia;
  final double width;

  /// 是否显示底部品牌页脚。
  final bool showFooter;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      decoration: BoxDecoration(
        color: theme.paper,
        borderRadius: BorderRadius.circular(18),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: theme.paperShadowAlpha),
            blurRadius: theme.paperShadowBlur,
            offset: Offset(0, theme.paperShadowOffset),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.all(22),
      child: Theme(
        data: theme.toThemeData(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (title != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  title!,
                  style: TextStyle(
                    fontFamily: theme.headingFontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.heading,
                    height: 1.25,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                timeText,
                style: TextStyle(
                  fontFamily: theme.fontFamily,
                  fontSize: 12,
                  color: theme.footer,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            MemoMarkdown(
              data: body,
              shrinkWrap: true,
              renderImages: true,
              blockSpacing: 8,
              textStyle: TextStyle(
                fontFamily: theme.fontFamily,
                fontSize: 15,
                height: 1.5,
                color: theme.text,
              ),
            ),
            if (showFooter) ...[
              const SizedBox(height: 18),
              Divider(color: theme.border.withValues(alpha: 0.6), height: 1),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    footerBrand,
                    style: TextStyle(
                      fontFamily: theme.headingFontFamily,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: theme.accent,
                    ),
                  ),
                  Text(
                    footerVia,
                    style: TextStyle(
                      fontFamily: theme.fontFamily,
                      fontSize: 11,
                      color: theme.footerVia,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 取正文第一行非空内容作为卡片标题（去掉 Markdown 的 `#` 前缀）。
String? deriveCardTitle(String content) {
  for (final raw in content.split('\n')) {
    final line = raw.replaceAll(RegExp(r'^#+\s*'), '').trim();
    if (line.isNotEmpty) return line;
  }
  return null;
}

/// 把时间格式化成卡片上显示的 `YYYY-MM-DD HH:mm`。
String formatCardTime(DateTime time) {
  String pad(int v) => v.toString().padLeft(2, '0');
  return '${time.year}-${pad(time.month)}-${pad(time.day)} '
      '${pad(time.hour)}:${pad(time.minute)}';
}

/// 通过 [RepaintBoundary] 的 [GlobalKey] 把卡片导出为 PNG 字节。
///
/// [pixelRatio] 控制清晰度，分享/保存建议 3。
Future<Uint8List?> captureWidgetPng(
  GlobalKey key, {
  double pixelRatio = 3,
}) async {
  final boundary =
      key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
  if (boundary == null) return null;
  final image = await boundary.toImage(pixelRatio: pixelRatio);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData?.buffer.asUint8List();
}
