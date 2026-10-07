/// 应用外观偏好：决定整个 App 套用哪一套主题。
///
/// 范围是**全 App**，不只是笔记正文——AppBar、工具栏、列表、对话框、设置页
/// 全部取自所选主题（见 `MemoCardTheme.applyToPalette` 与
/// `MaterialApp.theme`）。主题自带明暗，所以这里没有、也再需要单独的
/// 「跟随系统 / 浅色 / 深色」开关。
///
/// 与 [MemoCardTheme] 对应；`themeId` 为空或无法匹配时回落到默认暖白主题。
class NoteDisplayThemeSettings {
  static const defaults = NoteDisplayThemeSettings(themeId: 'warm_white');

  const NoteDisplayThemeSettings({required this.themeId});

  final String themeId;

  NoteDisplayThemeSettings copyWith({String? themeId}) {
    return NoteDisplayThemeSettings(themeId: themeId ?? this.themeId);
  }

  Map<String, dynamic> toJson() => {'themeId': themeId};

  factory NoteDisplayThemeSettings.fromJson(Map<String, dynamic> json) {
    final raw = json['themeId'];
    final id = raw is String && raw.trim().isNotEmpty
        ? raw.trim()
        : defaults.themeId;
    return NoteDisplayThemeSettings(themeId: id);
  }
}
