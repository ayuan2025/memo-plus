import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/top_toast.dart';
import '../../core/windows_adaptive_surface.dart';
import '../../data/ai/ai_route_config.dart';
import '../../data/repositories/ai_settings_repository.dart';
import '../../state/settings/ai_settings_provider.dart';
import 'settings_ui.dart';

class AiRouteSettingsScreen extends ConsumerWidget {
  const AiRouteSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final generationTileKey = GlobalKey();
    final embeddingTileKey = GlobalKey();
    final settings = ref.watch(aiSettingsProvider);
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final generation = AiRouteResolver.resolveTaskRoute(
      services: settings.services,
      bindings: settings.taskRouteBindings,
      routeId: AiTaskRouteId.summary,
      capability: AiCapability.chat,
    );
    final embedding = AiRouteResolver.resolveTaskRoute(
      services: settings.services,
      bindings: settings.taskRouteBindings,
      routeId: AiTaskRouteId.embeddingRetrieval,
      capability: AiCapability.embedding,
    );

    return SettingsPage(
      title: Text(isZh ? '默认用途' : 'Default Routes'),
      children: [
        SettingsSection(
          children: [
            SettingsValueRow(
              key: generationTileKey,
              label: isZh ? '生成默认' : 'Generation Default',
              value: generation == null
                  ? (isZh ? '未绑定模型' : 'No model selected')
                  : '${generation.service.displayName} · ${generation.model.displayName}',
              onTap: () => _pickRoute(
                context,
                ref,
                anchorContext: generationTileKey.currentContext,
                routeIds: const <AiTaskRouteId>[
                  AiTaskRouteId.summary,
                  AiTaskRouteId.analysisReport,
                  AiTaskRouteId.quickPrompt,
                  AiTaskRouteId.scanMetadata,
                ],
                capability: AiCapability.chat,
              ),
            ),
            SettingsValueRow(
              key: embeddingTileKey,
              label: 'Embedding Default',
              value: embedding == null
                  ? (isZh ? '未绑定模型' : 'No model selected')
                  : '${embedding.service.displayName} · ${embedding.model.displayName}',
              onTap: () => _pickRoute(
                context,
                ref,
                anchorContext: embeddingTileKey.currentContext,
                routeIds: const <AiTaskRouteId>[
                  AiTaskRouteId.embeddingRetrieval,
                ],
                capability: AiCapability.embedding,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _pickRoute(
    BuildContext context,
    WidgetRef ref, {
    BuildContext? anchorContext,
    required List<AiTaskRouteId> routeIds,
    required AiCapability capability,
  }) async {
    final settings = ref.read(aiSettingsProvider);
    final isZh =
        Localizations.localeOf(context).languageCode.toLowerCase() == 'zh';
    final options = selectableRouteOptionsForCapability(
      settings,
      capability: capability,
    );
    if (options.isEmpty) {
      showTopToast(
        context,
        isZh ? '请先添加可用模型。' : 'Add a compatible model first.',
      );
      return;
    }

    Widget buildRoutePicker(BuildContext surfaceContext) {
      return SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: SettingsContentHeader(
                title: isZh ? '选择默认模型' : 'Choose Default Model',
              ),
            ),
            for (final option in options)
              ListTile(
                title: Text(option.model.displayName),
                subtitle: Text(option.service.displayName),
                onTap: () => Navigator.of(surfaceContext).pop(option),
              ),
          ],
        ),
      );
    }

    final selected = await _showRoutePickerSurface(
      context,
      buildRoutePicker,
      anchorContext: anchorContext,
    );
    if (selected == null) return;

    final replacements = routeIds
        .map(
          (routeId) => AiTaskRouteBinding(
            routeId: routeId,
            serviceId: selected.service.serviceId,
            modelId: selected.model.modelId,
            capability: capability,
          ),
        )
        .toList(growable: false);
    final current =
        settings.taskRouteBindings
            .where((binding) => !routeIds.contains(binding.routeId))
            .toList(growable: true)
          ..addAll(replacements);
    await ref
        .read(aiSettingsProvider.notifier)
        .replaceTaskRouteBindings(current);
    if (!context.mounted) return;
    showTopToast(context, isZh ? '默认用途已更新。' : 'Default routes updated.');
  }

  Future<AiSelectableRouteOption?> _showRoutePickerSurface(
    BuildContext context,
    WidgetBuilder builder, {
    BuildContext? anchorContext,
  }) {
    if (shouldUseWindowsAdaptiveSurface(context)) {
      return showWindowsAdaptiveSurface<AiSelectableRouteOption>(
        context: context,
        kind: WindowsAdaptiveSurfaceKind.popover,
        anchorContext: anchorContext,
        fallbackAlignment: Alignment.topLeft,
        maxWidth: 480,
        builder: builder,
      );
    }
    return showModalBottomSheet<AiSelectableRouteOption>(
      context: context,
      showDragHandle: true,
      builder: builder,
    );
  }
}
