/// memo+ 品牌与外部链接的**唯一定义处**。
///
/// GitHub 仓库：<https://github.com/ayuan2025/memo-plus>。
/// 关于页、反馈、隐私/条款、检查更新等所有入口都从这里派生。
///
/// 注意：`memoflow.hzc073.com`（上游官网）与上游的赞赏/捐赠链接不属于本品牌，
/// 不要把它们写回这里。
abstract final class MemoPlusLinks {
  /// GitHub 仓库主页（同时充当「官方网站」入口）。
  static const String githubRepo = 'https://github.com/ayuan2025/memo-plus';

  /// 关于页「官网」入口：仓库主页。
  static const String websiteUrl = githubRepo;

  /// 帮助中心：仓库 README。
  static const String helpUrl = '$githubRepo#readme';

  /// 问题反馈：仓库 Issues。
  static const String feedbackUrl = '$githubRepo/issues';

  /// 隐私政策 / 用户协议：仓库内文档（docs/ 目录）。
  static const String privacyPolicyUrl =
      '$githubRepo/blob/main/docs/privacy-policy.md';
  static const String termsOfServiceUrl =
      '$githubRepo/blob/main/docs/terms-of-service.md';

  /// 「检查更新」配置文件的稳定地址。
  ///
  /// GitHub Releases 提供永久指向最新 release 附件的下载地址
  /// `releases/latest/download/<文件名>`，把 latest.json（及各语言副本
  /// `latest.<locale>.json`）作为 release 附件上传即可，无需每次改代码。
  static const String updateConfigBaseUrl =
      'https://github.com/ayuan2025/memo-plus/releases/latest/download';
}
