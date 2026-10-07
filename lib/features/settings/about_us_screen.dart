import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../application/legal/legal_consent_policy.dart';
import '../../core/app_links.dart';
import '../../core/app_version.dart';
import '../../i18n/strings.g.dart';
import '../../platform/platform_route.dart';
import '../../state/system/update_config_provider.dart';
import '../debug/debug_tools_screen.dart';
import '../updates/donors_wall_screen.dart';
import '../updates/release_notes_screen.dart';
import '../updates/update_announcement_dialog.dart';
import 'settings_ui.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  static final Future<PackageInfo> _packageInfoFuture =
      PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return SettingsPage(
      showBackButton: showBackButton,
      title: Text(context.t.strings.legacy.msg_about),
      children: const [AboutUsContent()],
    );
  }
}

class AboutUsContent extends ConsumerStatefulWidget {
  const AboutUsContent({super.key});

  @override
  ConsumerState<AboutUsContent> createState() => _AboutUsContentState();
}

class _AboutUsContentState extends ConsumerState<AboutUsContent> {
  int _debugTapCount = 0;
  DateTime? _lastDebugTapAt;
  bool _checkingUpdate = false;

  /// 手动检查更新。
  ///
  /// 与启动时那次自动检测是**两条独立的路**：启动检测有幂等锁，而且用户点过
  /// 「以后再说」会写 `skipUpdateVersion`——那两条路都会导致之后不再提示，所以
  /// 必须有一条能随时重查的路，否则用户永远看不到新版本。
  ///
  /// 已经是最新时只给一条 SnackBar，不开弹窗：弹窗在无更新时只剩一个「以后再说」
  /// 按钮（`showUpdateAction` 会算成 false），点它等于什么都没发生。
  Future<void> _checkForUpdate(BuildContext context) async {
    if (_checkingUpdate) return;
    setState(() => _checkingUpdate = true);
    try {
      final config = await ref
          .read(updateConfigServiceProvider)
          .fetchLatest(
            localeTag: Localizations.localeOf(context).toLanguageTag(),
          );
      if (!context.mounted) return;
      if (config == null) {
        _say(context, '检查更新失败，请检查网络后重试');
        return;
      }
      final info = await AboutUsScreen._packageInfoFuture;
      if (!context.mounted) return;
      final latest = config.versionInfo.latestVersion.trim();
      // 比较逻辑与启动弹窗一致：只比版本号的前三段数字，versionCode 不参与。
      if (!_isNewerVersion(latest, info.version)) {
        _say(context, '已是最新版本（${info.version}）');
        return;
      }
      await UpdateAnnouncementDialog.show(
        context,
        config: config,
        currentVersion: info.version,
      );
    } catch (_) {
      if (context.mounted) _say(context, '检查更新失败，请检查网络后重试');
    } finally {
      if (mounted) setState(() => _checkingUpdate = false);
    }
  }

  static void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// 远端版本是否比本地新。规则由 `core/app_version.dart` 统一提供：剥掉
  /// `+build`/`-suffix` 段，每段取其中的数字，只比前三段。启动弹窗、设置页
  /// 与更新策略共用同一份实现，避免同一版本在两处得出相反结论。
  static bool _isNewerVersion(String remote, String local) =>
      isNewerVersion(remote, local);

  void _handleDebugTap() {
    if (!kDebugMode) return;
    final now = DateTime.now();
    final last = _lastDebugTapAt;
    if (last == null ||
        now.difference(last) > const Duration(milliseconds: 1500)) {
      _debugTapCount = 0;
    }
    _debugTapCount++;
    _lastDebugTapAt = now;
    if (_debugTapCount < 5) return;
    _debugTapCount = 0;
    Navigator.of(context).push(
      buildPlatformPageRoute<void>(
        context: context,
        builder: (_) => const DebugToolsScreen(),
      ),
    );
  }

  Future<void> _openExternalLink(BuildContext context, String rawUrl) async {
    final uri = Uri.parse(rawUrl);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.t.strings.legacy.msg_unable_open_browser_try),
          ),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.t.strings.legacy.msg_failed_open_try)),
      );
    }
  }

  String _versionDescription(BuildContext context, PackageInfo? info) {
    final version = info?.version.trim() ?? '';
    final buildNumber = info?.buildNumber.trim() ?? '';
    if (version.isEmpty) {
      return context.t.strings.legacy.msg_version_description_unknown;
    }
    if (buildNumber.isEmpty || buildNumber == version) {
      return context.t.strings.legacy.msg_version_description_v(
        version: version,
      );
    }
    return context.t.strings.legacy.msg_version_description_v_build(
      version: version,
      build: buildNumber,
    );
  }

  @override
  Widget build(BuildContext context) {
    final tokens = settingsPageTokens(context);
    // 品牌入口统一由 core/app_links.dart 定义（GitHub 仓库）。
    const websiteUrl = MemoPlusLinks.websiteUrl;
    const helpUrl = MemoPlusLinks.helpUrl;
    const feedbackUrl = MemoPlusLinks.feedbackUrl;
    final entries = <_AboutEntry>[
      _AboutEntry(
        icon: Icons.public_outlined,
        title: context.t.strings.legacy.msg_about_website_link,
        subtitle: context.t.strings.legacy.msg_about_website_link_subtitle,
        external: true,
        onTap: () => _openExternalLink(context, websiteUrl),
      ),
      _AboutEntry(
        icon: Icons.privacy_tip_outlined,
        title: context.t.strings.legacy.msg_about_privacy_policy,
        subtitle: context.t.strings.legacy.msg_about_privacy_policy_subtitle,
        external: true,
        onTap: () => _openExternalLink(
          context,
          MemoFlowLegalConsentPolicy.privacyPolicyUrl,
        ),
      ),
      _AboutEntry(
        icon: Icons.description_outlined,
        title: context.t.strings.legacy.msg_about_user_agreement,
        subtitle: context.t.strings.legacy.msg_about_user_agreement_subtitle,
        external: true,
        onTap: () => _openExternalLink(
          context,
          MemoFlowLegalConsentPolicy.termsOfServiceUrl,
        ),
      ),
      _AboutEntry(
        icon: Icons.help_outline,
        title: context.t.strings.legacy.msg_about_help_center,
        subtitle: context.t.strings.legacy.msg_about_help_center_subtitle,
        external: true,
        onTap: () => _openExternalLink(context, helpUrl),
      ),
      _AboutEntry(
        icon: Icons.system_update_alt_outlined,
        title: '检查更新',
        subtitle: '从发布页获取最新版本',
        onTap: () => _checkForUpdate(context),
      ),
      _AboutEntry(
        icon: Icons.update_outlined,
        title: context.t.strings.legacy.msg_release_notes_2,
        subtitle: context.t.strings.legacy.msg_about_release_notes_subtitle,
        onTap: () {
          Navigator.of(context).push(
            buildPlatformPageRoute<void>(
              context: context,
              builder: (_) => const ReleaseNotesScreen(),
            ),
          );
        },
      ),
      _AboutEntry(
        icon: Icons.feedback_outlined,
        title: context.t.strings.legacy.msg_about_submit_feedback,
        subtitle: context.t.strings.legacy.msg_about_submit_feedback_subtitle,
        external: true,
        onTap: () => _openExternalLink(context, feedbackUrl),
      ),
      _AboutEntry(
        icon: Icons.favorite_border,
        title: context.t.strings.legacy.msg_contributors,
        subtitle: context.t.strings.legacy.msg_about_contributors_subtitle,
        onTap: () {
          Navigator.of(context).push(
            buildPlatformPageRoute<void>(
              context: context,
              builder: (_) => const DonorsWallScreen(),
            ),
          );
        },
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _AboutSummary(
          onTap: _handleDebugTap,
          versionBuilder: (snapshot) =>
              _versionDescription(context, snapshot.data),
        ),
        const SizedBox(height: 16),
        SettingsSection(
          children: [
            for (final entry in entries)
              SettingsNavigationRow(
                leading: Icon(entry.icon, size: 20, color: tokens.textMuted),
                label: entry.title,
                description: entry.subtitle,
                trailingIcon: entry.external
                    ? Icons.open_in_new
                    : Icons.chevron_right,
                onTap: entry.onTap,
              ),
          ],
        ),
        if (kDebugMode) ...[
          const SizedBox(height: 10),
          Text(
            context.t.strings.legacy.msg_debug_tap_logo_enter_debug_tools,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: tokens.textMuted),
          ),
        ],
        const SizedBox(height: 4),
      ],
    );
  }
}

class _AboutSummary extends StatelessWidget {
  const _AboutSummary({required this.onTap, required this.versionBuilder});

  final VoidCallback onTap;
  final String Function(AsyncSnapshot<PackageInfo> snapshot) versionBuilder;

  @override
  Widget build(BuildContext context) {
    final tokens = settingsPageTokens(context);
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: Image.asset(
              'assets/splash/splash_logo_native.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          const SizedBox(height: 12),
          const SettingsContentHeader(
            title: 'memo+',
            textAlign: TextAlign.center,
            prominent: true,
          ),
          const SizedBox(height: 6),
          FutureBuilder<PackageInfo>(
            future: AboutUsScreen._packageInfoFuture,
            builder: (context, snapshot) {
              return Text(
                versionBuilder(snapshot),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.35,
                  color: tokens.textMuted,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AboutEntry {
  const _AboutEntry({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.external = false,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool external;
  final VoidCallback onTap;
}
