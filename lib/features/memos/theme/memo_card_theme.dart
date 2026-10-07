import 'package:flutter/material.dart';

import '../../../core/memoflow_palette.dart';

/// 笔记分享卡片主题。
///
/// 移植自 zhaoolee/notes 的「卡片主题」设计令牌（src/lib/note-card-theme-styles.ts）。
/// 每个主题只是一组颜色 / 字体 / 阴影数据，可 1:1 对应 Web 端定义。
///
/// 移植策略：不改动 [MemoMarkdown] 的渲染代码——它取色全部来自
/// `Theme.of(context)`。我们只要在外层套一个由本主题构造的 [ThemeData]，
/// 暖白纸面 / 文字 / 强调色 / 代码底色 / 引用色就会整体生效。
class MemoCardTheme {
  const MemoCardTheme({
    required this.id,
    required this.label,
    required this.paper,
    required this.text,
    required this.heading,
    required this.accent,
    required this.border,
    required this.codeBackground,
    required this.codeText,
    required this.quote,
    required this.quoteMark,
    required this.imageFrame,
    required this.footer,
    required this.footerVia,
    required this.fontFamily,
    required this.headingFontFamily,
    this.paperShadowBlur = 42,
    this.paperShadowOffset = 24,
    this.paperShadowAlpha = 0.12,
    this.shadowColor = Colors.brown,
  });

  final String id;
  final String label;
  final Color paper;
  final Color text;
  final Color heading;
  final Color accent;
  final Color border;
  final Color codeBackground;
  final Color codeText;
  final Color quote;
  final Color quoteMark;
  final Color imageFrame;
  final Color footer;
  final Color footerVia;
  final String fontFamily;
  final String headingFontFamily;
  final double paperShadowBlur;
  final double paperShadowOffset;
  final double paperShadowAlpha;

  /// 卡片投影颜色（配 [paperShadowAlpha] 使用）。暖色纸面用棕色，深色主题用黑色。
  final Color shadowColor;

  /// 本主题是浅色还是深色，由纸面亮度决定。
  ///
  /// 主题自带明暗（7 套里 5 套浅、2 套深），所以 App 不再另设「跟随系统 / 浅 /
  /// 深」开关——那会和主题形成第三套互不相干的配色来源。这里是唯一的判定点。
  Brightness get brightness =>
      paper.computeLuminance() > 0.5 ? Brightness.light : Brightness.dark;

  bool get isDark => brightness == Brightness.dark;

  /// 把 [paper] 提亮/压暗当作「App 底色」：纸面是笔记的纸，App 底色应比它
  /// 更退后一档，否则整个界面会糊成一片同色、失去层次。
  ///
  /// 注意不能简单往 white/black lerp：纯白纸面（备忘录浅色、红色极简、杂志
  /// 衬线都是 `#FFFFFF`）往白 lerp 回去还是纯白，层次就没了。所以这里显式给
  /// 浅色方向一个**灰底**——把纸面按感知亮度朝 0.945 收，纯白收到 `#F1F1F1`，
  /// 卡片再比它亮一档，三层才拉得开。
  Color get appBackground => isDark
      ? Color.lerp(paper, Colors.black, 0.32)!
      : Color.lerp(paper, const Color(0xFFF1F1F1), 0.85)!;

  /// 卡片/列表行的底色：比 App 底色亮一档，让「纸」浮起来。纯白纸面直接取白。
  Color get appCard => isDark
      ? Color.lerp(paper, Colors.white, 0.05)!
      : Color.lerp(paper, Colors.white, 0.85)!;

  /// 音频条、底部工具条一类的次级面板色：卡在底色与卡片之间。
  Color get appSurface => isDark
      ? Color.lerp(paper, Colors.black, 0.18)!
      : Color.lerp(appBackground, Colors.white, 0.45)!;

  /// 把本主题投影到 [MemoFlowPalette]，使其 854 处静态引用自动跟随。
  ///
  /// 这是让全 App 只留一个配色来源的关键：`MemoFlowPalette` 全是静态可变字段，
  /// 遍布 88 个文件。与其逐处改成 `Theme.of(context)` 取色（改动巨大、极易漏
  /// 漏），不如让主题反过来覆盖它一次——引用点一行不用动，主题一换全 App 跟着换。
  void applyToPalette() {
    final scheme = toThemeData().colorScheme;
    MemoFlowPalette.primary = accent;
    MemoFlowPalette.primaryDark = accent;
    MemoFlowPalette.backgroundLight = appBackground;
    MemoFlowPalette.backgroundDark = appBackground;
    MemoFlowPalette.cardLight = appCard;
    MemoFlowPalette.cardDark = appCard;
    MemoFlowPalette.borderLight = border;
    MemoFlowPalette.borderDark = border;
    MemoFlowPalette.audioSurfaceLight = appSurface;
    MemoFlowPalette.audioSurfaceDark = appSurface;
    MemoFlowPalette.textLight = text;
    MemoFlowPalette.textDark = text;
    MemoFlowPalette.onSurface = text;
    MemoFlowPalette.onSurfaceDark = text;
    // 语义色（error / success…）仍走 Material 默认派生，避免 7 套主题各配一份
    // 红绿色而失去「危险=红」这类跨主题不变的约定；这里只把 surface 家族对齐。
    MemoFlowPalette.surfaceLight = scheme.surface;
    MemoFlowPalette.surfaceDark = scheme.surface;
  }

  /// 由本主题构造 App 整体使用的 [ThemeData]。
  ///
  /// 覆盖组件主题的范围是刻意选的：凡是把「从 ThemeData 取色」当默认的组件都
  /// 覆盖（AppBar、对话框、底部面板、SnackBar、Chip、输入框、列表行、卡片、
  /// 分隔线），而按钮色**不**在这里统一——架构护栏
  /// `settings_ui_drift_guardrail_test.dart` 明确禁止在 `app_theme.dart` 写
  /// `filledButtonTheme` 等四类 ButtonTheme（「不许在 app 层顺手修按钮色」），
  /// 按钮走 `colorScheme.primary`，由下面的 `primary: accent` 带动。
  ThemeData toThemeData() {
    final dark = isDark;
    final base = dark ? ThemeData.dark() : ThemeData.light();
    final bg = appBackground;
    final scheme =
        (dark ? ThemeData.dark() : ThemeData.light()).colorScheme.copyWith(
          primary: accent,
          onPrimary: paper,
          surface: appCard,
          onSurface: text,
          onSurfaceVariant: footer,
          surfaceContainerLowest: bg,
          surfaceContainerLow: appSurface,
          surfaceContainer: appCard,
          surfaceContainerHigh: appSurface,
          surfaceContainerHighest: codeBackground,
          outlineVariant: border,
        );

    TextStyle? t(TextStyle? s, {Color? color, String? family}) => s?.copyWith(
      color: color ?? text,
      fontFamily: family ?? fontFamily,
    );

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: bg,
      canvasColor: bg,
      dividerColor: border,
      shadowColor: shadowColor,
      textTheme: base.textTheme
          .copyWith(
            bodyMedium: t(base.textTheme.bodyMedium),
            bodyLarge: t(base.textTheme.bodyLarge),
            bodySmall: t(base.textTheme.bodySmall, color: footer),
            titleLarge: t(base.textTheme.titleLarge, color: heading, family: headingFontFamily),
            titleMedium: t(base.textTheme.titleMedium, color: heading, family: headingFontFamily),
            titleSmall: t(base.textTheme.titleSmall, color: heading, family: headingFontFamily),
            headlineSmall: t(base.textTheme.headlineSmall, color: heading, family: headingFontFamily),
            headlineMedium: t(base.textTheme.headlineMedium, color: heading, family: headingFontFamily),
            labelLarge: t(base.textTheme.labelLarge),
            labelMedium: t(base.textTheme.labelMedium, color: footer),
            labelSmall: t(base.textTheme.labelSmall, color: footer),
          )
          .apply(fontFamily: fontFamily),
      primaryTextTheme: base.primaryTextTheme.apply(fontFamily: fontFamily),
      appBarTheme: AppBarTheme(
        centerTitle: false,
        backgroundColor: bg.withValues(alpha: 0.9),
        foregroundColor: text,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: t(base.textTheme.titleLarge, color: heading, family: headingFontFamily),
        iconTheme: IconThemeData(color: text),
      ),
      cardTheme: CardThemeData(
        color: appCard,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        elevation: 0,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: appCard,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: t(base.textTheme.titleLarge, color: heading, family: headingFontFamily),
        contentTextStyle: t(base.textTheme.bodyMedium),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: appCard,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        dragHandleColor: border,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: codeBackground,
        contentTextStyle: TextStyle(color: codeText, fontFamily: fontFamily),
        actionTextColor: accent,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: appSurface,
        side: BorderSide(color: border),
        labelStyle: TextStyle(color: text, fontFamily: fontFamily),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(color: text.withValues(alpha: 0.45), fontFamily: fontFamily),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: text,
        textColor: text,
        titleTextStyle: t(base.textTheme.bodyLarge),
        subtitleTextStyle: t(base.textTheme.bodySmall, color: footer),
      ),
      extensions: const [],
    );
  }
}

/// 暖白质感（默认主题）。
///
/// 配色取自 zhaoolee/notes `note-card-theme-styles.ts` 的 `default` 主题
/// （纸面 #fffcf7、强调 #ac9070、暖棕描边 #dcdbbf、代码底 #f3ece1 等）。
/// 字体走中文友好栈：OPPOSans → Noto Sans SC → PingFang SC → 微软雅黑。
const MemoCardTheme kMemoCardThemeWarmWhite = MemoCardTheme(
  id: 'warm_white',
  label: '暖白质感',
  paper: Color(0xFFFCF7F2),
  text: Color(0xFF332E27),
  heading: Color(0xFF463526),
  accent: Color(0xFFAC9070),
  border: Color(0xFFDCDBBF),
  codeBackground: Color(0xFFF3ECE1),
  codeText: Color(0xFF8A6548),
  quote: Color(0xFF6B5740),
  quoteMark: Color(0xFFAC9070),
  imageFrame: Color(0xFFEBE8E3),
  footer: Color(0xFFD7CEC1),
  footerVia: Color(0xFFDED6CB),
  fontFamily:
      'OPPOSans, "Noto Sans SC", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Arial, sans-serif',
  headingFontFamily:
      'OPPOSans, "Noto Sans SC", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", "Helvetica Neue", Arial, sans-serif',
);

/// 已实现的卡片主题集合。
///
/// 配色 1:1 取自 zhaoolee/notes `note-card-theme-styles.ts` 对应主题；
/// Bear / 巴扎黑 / Telegraph 等第三方产品名已改为中性名称。
const List<MemoCardTheme> kMemoCardThemes = <MemoCardTheme>[
  kMemoCardThemeWarmWhite,
  kMemoCardThemeMidnight,
  kMemoCardThemeNoteLight,
  kMemoCardThemeNoteDark,
  kMemoCardThemeRedMinimal,
  kMemoCardThemeWarmOrange,
  kMemoCardThemeSerifPress,
];

/// 深夜便签（深色）。
///
/// 取自 web 端 `smartisan-dark` 主题：近黑纸面 #1c1a1c、金色强调 #d5ab36。
const MemoCardTheme kMemoCardThemeMidnight = MemoCardTheme(
  id: 'midnight',
  label: '深夜便签',
  paper: Color(0xFF1C1A1C),
  text: Color(0xFFCECECE),
  heading: Color(0xFFDEDCDE),
  accent: Color(0xFFD5AB36),
  border: Color(0xFF343134),
  codeBackground: Color(0xFF242224),
  codeText: Color(0xFFC5C3C5),
  quote: Color(0xFF9F9C9F),
  quoteMark: Color(0xFF5C585C),
  imageFrame: Color(0xFF3B383B),
  footer: Color(0xFF777477),
  footerVia: Color(0xFF656265),
  paperShadowBlur: 72,
  paperShadowOffset: 32,
  paperShadowAlpha: 0.42,
  shadowColor: Colors.black,
  fontFamily: 'OPPOSans',
  headingFontFamily: 'OPPOSans',
);

/// 备忘录浅色（iOS 备忘录风）。
///
/// 取自 web 端 `apple-notes-light` 主题：纯白纸面、黄色强调 #ebb800。
const MemoCardTheme kMemoCardThemeNoteLight = MemoCardTheme(
  id: 'note_light',
  label: '备忘录浅色',
  paper: Color(0xFFFFFFFF),
  text: Color(0xFF2C2C2E),
  heading: Color(0xFF1C1C1E),
  accent: Color(0xFFEBB800),
  border: Color(0xFFD1D1D6),
  codeBackground: Color(0xFFF2F2F7),
  codeText: Color(0xFF2C2C2E),
  quote: Color(0xFF636366),
  quoteMark: Color(0xFFEBB800),
  imageFrame: Color(0xFFD1D1D6),
  footer: Color(0xFF8E8E93),
  footerVia: Color(0xFFAEAEB2),
  paperShadowBlur: 64,
  paperShadowOffset: 28,
  paperShadowAlpha: 0.16,
  shadowColor: Color(0xFF40341C),
  fontFamily: 'SF Pro Text',
  headingFontFamily: 'SF Pro Text',
);

/// 备忘录深色（iOS 备忘录深色风）。
///
/// 取自 web 端 `apple-notes` 主题：碳黑纸面 #181818、黄色强调 #ebb800。
const MemoCardTheme kMemoCardThemeNoteDark = MemoCardTheme(
  id: 'note_dark',
  label: '备忘录深色',
  paper: Color(0xFF181818),
  text: Color(0xFFDCDCDC),
  heading: Color(0xFFE8E8E8),
  accent: Color(0xFFEBB800),
  border: Color(0xFF3A3A3C),
  codeBackground: Color(0xFF242426),
  codeText: Color(0xFFDEDEDE),
  quote: Color(0xFFA8A8AD),
  quoteMark: Color(0xFFEBB800),
  imageFrame: Color(0xFF3A3A3C),
  footer: Color(0xFF8E8E93),
  footerVia: Color(0xFF6E6E73),
  paperShadowBlur: 64,
  paperShadowOffset: 28,
  paperShadowAlpha: 0.34,
  shadowColor: Colors.black,
  fontFamily: 'SF Pro Text',
  headingFontFamily: 'SF Pro Text',
);

/// 红色极简（白纸红强调）。
///
/// 取自 web 端 `bear` 主题：纯白纸面、红色强调 #dd4c4f、几乎无边框装饰。
const MemoCardTheme kMemoCardThemeRedMinimal = MemoCardTheme(
  id: 'red_minimal',
  label: '红色极简',
  paper: Color(0xFFFFFFFF),
  text: Color(0xFF444444),
  heading: Color(0xFF444444),
  accent: Color(0xFFDD4C4F),
  border: Color(0xFFD9D9D9),
  codeBackground: Color(0xFFF3F5F7),
  codeText: Color(0xFF444444),
  quote: Color(0xFF444444),
  quoteMark: Color(0xFFDD4C4F),
  imageFrame: Color(0x00000000),
  footer: Color(0xFF888888),
  footerVia: Color(0xFFB0B0B0),
  paperShadowBlur: 54,
  paperShadowOffset: 24,
  paperShadowAlpha: 0.12,
  shadowColor: Color(0xFF444444),
  fontFamily: 'Avenir Next',
  headingFontFamily: 'Avenir Next',
);

/// 暖橙极简（米白纸面 + 暖橙强调）。
///
/// 取自 web 端 `bazhahei` 主题：米白纸面 #faf9f5、暖橙强调 #d4734b。
const MemoCardTheme kMemoCardThemeWarmOrange = MemoCardTheme(
  id: 'warm_orange',
  label: '暖橙极简',
  paper: Color(0xFFFAF9F5),
  text: Color(0xFF3D3D3A),
  heading: Color(0xFF141413),
  accent: Color(0xFFD4734B),
  border: Color(0xFFE6DFD8),
  codeBackground: Color(0xFFEFE9DE),
  codeText: Color(0xFF3D3D3A),
  quote: Color(0xFF6C6A64),
  quoteMark: Color(0xFFD4734B),
  imageFrame: Color(0xFFE6DFD8),
  footer: Color(0xFF8E8B82),
  footerVia: Color(0xFFAAA69D),
  paperShadowBlur: 54,
  paperShadowOffset: 24,
  paperShadowAlpha: 0.14,
  fontFamily: 'OPPOSans',
  headingFontFamily: 'OPPOSans',
);

/// 杂志衬线（黑白报刊风）。
///
/// 取自 web 端 `telegraph` 主题：纯白纸面、墨色文字、衬线标题。
const MemoCardTheme kMemoCardThemeSerifPress = MemoCardTheme(
  id: 'serif_press',
  label: '杂志衬线',
  paper: Color(0xFFFFFFFF),
  text: Color(0xCC000000),
  heading: Color(0xCC000000),
  accent: Color(0xCC000000),
  border: Color(0xFFC9CDD1),
  codeBackground: Color(0xFFF5F8FC),
  codeText: Color(0xCC000000),
  quote: Color(0xCC000000),
  quoteMark: Color(0xFF000000),
  imageFrame: Color(0x00000000),
  footer: Color(0xFF79828B),
  footerVia: Color(0xFFA0A7AE),
  paperShadowBlur: 48,
  paperShadowOffset: 18,
  paperShadowAlpha: 0.10,
  shadowColor: Colors.black,
  fontFamily: 'Georgia',
  headingFontFamily: 'Lucida Grande',
);
