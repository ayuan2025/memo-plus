import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/top_toast.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../i18n/strings.g.dart';
import '../../platform/widgets/platform_controls.dart';
import '../../state/settings/ai_settings_provider.dart';
import 'ai_provider_logo.dart';
import 'ai_proxy_settings_screen.dart';
import 'ai_service_detail_screen.dart';
import 'ai_service_model_screen.dart';
import 'ai_service_wizard_screen.dart';
import 'ai_user_profile_screen.dart';
import 'settings_ui.dart';

class AiSettingsScreen extends ConsumerWidget {
  const AiSettingsScreen({super.key, this.showBackButton = true});

  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(aiSettingsProvider);
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final useDesktopAddAction =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.windows ||
            defaultTargetPlatform == TargetPlatform.linux ||
            defaultTargetPlatform == TargetPlatform.macOS);

    void openAddService() {
      openAiServiceWizard(context);
    }

    return SettingsPage(
      title: Text(context.t.strings.legacy.msg_ai_settings),
      showBackButton: showBackButton,
      actions: [
        if (useDesktopAddAction)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: openAddService,
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(isZh ? '\u6dfb\u52a0\u670d\u52a1' : 'Add Service'),
            ),
          ),
      ],
      children: [
        SettingsSection(
          children: [
            SettingsNavigationRow(
              label: context.t.strings.legacy.msg_my_profile,
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiUserProfileScreen(),
                  ),
                );
              },
            ),
            SettingsNavigationRow(
              label: context.t.strings.aiProxy.title,
              description: _proxySummary(context, settings.proxySettings),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const AiProxySettingsScreen(),
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 20),
        SettingsSection(
          header: Text(isZh ? '\u670d\u52a1\u5217\u8868' : 'Services'),
          children: [
            if (settings.services.isEmpty)
              SettingsInfoRow(
                description: isZh
                    ? '\u8fd8\u6ca1\u6709 AI \u670d\u52a1\uff0c\u70b9\u51fb\u300c\u6dfb\u52a0\u670d\u52a1\u300d\u5f00\u59cb\u914d\u7f6e\u3002'
                    : 'No AI services yet. Tap Add Service to get started.',
              )
            else
              for (final service in settings.services)
                _ServiceCard(service: service),
          ],
        ),
        if (!useDesktopAddAction) ...[
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: SettingsAction(
              onPressed: openAddService,
              icon: const Icon(Icons.add_rounded),
              label: Text(isZh ? '\u6dfb\u52a0\u670d\u52a1' : 'Add Service'),
            ),
          ),
        ],
      ],
    );
  }
}

class _ServiceCard extends ConsumerWidget {
  const _ServiceCard({required this.service});

  final AiServiceInstance service;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = settingsPageTokens(context);
    final colorScheme = Theme.of(context).colorScheme;
    final settings = ref.watch(aiSettingsProvider);
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final template = findAiProviderTemplate(service.templateId);
    final defaultModelIds = _defaultModelIds(settings);

    return Material(
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.65),
        ),
      ),
      child: InkWell(
        onTap: () {
          openAiServiceDetail(context, serviceId: service.serviceId);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AiProviderLogo(template: template, size: 44, iconSize: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SettingsRowTitle(service.displayName),
                        const SizedBox(height: 4),
                        Text(
                          template == null
                              ? service.templateId
                              : localizedAiProviderTemplateDisplayName(
                                  template,
                                  isZh: isZh,
                                ),
                          style: TextStyle(
                            fontSize: 12,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PlatformSwitch(
                    value: service.enabled,
                    onChanged: (value) {
                      ref
                          .read(aiSettingsProvider.notifier)
                          .setServiceEnabled(service.serviceId, value);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...service.models.map(
                    (model) => _ServiceBadge(
                      label: model.modelKey,
                      leadingCheck: defaultModelIds.contains(model.modelId),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                service.baseUrl.trim().isEmpty
                    ? (isZh
                          ? '\u672a\u8bbe\u7f6e Base URL'
                          : 'Base URL not configured')
                    : service.baseUrl,
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => _addModel(context, ref),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(
                      isZh ? '\u6dfb\u52a0\u6a21\u578b' : 'Add Model',
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      openAiServiceDetail(
                        context,
                        serviceId: service.serviceId,
                      );
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: Text(
                      isZh ? '\u7ba1\u7406\u670d\u52a1' : 'Manage Service',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addModel(BuildContext context, WidgetRef ref) async {
    final result = await showAiModelEditorDialog(context, service: service);
    if (result == null) return;
    await ref
        .read(aiSettingsProvider.notifier)
        .upsertServiceModel(service.serviceId, result);
    if (!context.mounted) return;
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    showTopToast(
      context,
      isZh ? '\u6a21\u578b\u5df2\u6dfb\u52a0\u3002' : 'Model added.',
    );
  }

  Set<String> _defaultModelIds(AiSettings settings) {
    final result = <String>{};
    for (final binding in settings.taskRouteBindings) {
      if (binding.serviceId != service.serviceId) continue;
      result.add(binding.modelId);
    }
    _markSelectedProfileModel(
      result,
      modelKey: settings.selectedGenerationProfile.model,
      baseUrl: settings.selectedGenerationProfile.baseUrl,
      apiKey: settings.selectedGenerationProfile.apiKey,
    );
    final embeddingProfile = settings.selectedEmbeddingProfile;
    if (embeddingProfile != null) {
      _markSelectedProfileModel(
        result,
        modelKey: embeddingProfile.model,
        baseUrl: embeddingProfile.baseUrl,
        apiKey: embeddingProfile.apiKey,
      );
    }
    return result;
  }

  void _markSelectedProfileModel(
    Set<String> result, {
    required String modelKey,
    required String baseUrl,
    required String apiKey,
  }) {
    final normalizedModelKey = modelKey.trim().toLowerCase();
    final normalizedBaseUrl = baseUrl.trim().toLowerCase();
    final normalizedApiKey = apiKey.trim();
    if (normalizedModelKey.isEmpty) return;
    for (final model in service.models) {
      if (model.modelKey.trim().toLowerCase() != normalizedModelKey) continue;
      if (normalizedBaseUrl.isNotEmpty &&
          service.baseUrl.trim().toLowerCase() != normalizedBaseUrl) {
        continue;
      }
      if (normalizedApiKey.isNotEmpty &&
          service.apiKey.trim() != normalizedApiKey) {
        continue;
      }
      result.add(model.modelId);
    }
  }
}

class _ServiceBadge extends StatelessWidget {
  const _ServiceBadge({required this.label, this.leadingCheck = false});

  final String label;
  final bool leadingCheck;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leadingCheck) ...[
            Icon(
              Icons.check_circle_rounded,
              size: 14,
              color: Colors.green.shade600,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          ),
        ],
      ),
    );
  }
}

String _proxySummary(BuildContext context, AiProxySettings settings) {
  final t = context.t.strings.aiProxy;
  if (!settings.isConfigured) return t.notConfigured;
  return switch (settings.protocol) {
    AiProxyProtocol.http => t.statusHttp(
      host: settings.host,
      port: settings.port,
    ),
    AiProxyProtocol.socks5 => t.statusSocks5(
      host: settings.host,
      port: settings.port,
    ),
  };
}
