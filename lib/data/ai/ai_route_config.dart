import 'ai_provider_models.dart';
import 'ai_provider_templates.dart';
import 'ai_route_resolver.dart';
import 'ai_settings_models.dart';

class AiSelectableRouteOption {
  const AiSelectableRouteOption({required this.service, required this.model});

  final AiServiceInstance service;
  final AiModelEntry model;
}

bool hasConfiguredChatRoute(
  AiSettings settings, {
  required AiTaskRouteId routeId,
}) {
  final resolved = AiRouteResolver.resolveTaskRoute(
    services: settings.services,
    bindings: settings.taskRouteBindings,
    routeId: routeId,
    capability: AiCapability.chat,
  );
  if (resolved != null) {
    return _hasResolvedRouteConfig(resolved);
  }

  final fallback = _fallbackGenerationProfile(settings);
  if (fallback == null) return false;
  return _hasLegacyProfileConfig(
    baseUrl: fallback.baseUrl,
    model: fallback.model,
    apiKey: fallback.apiKey,
    requiresApiKey: fallback.backendKind != AiBackendKind.localApi,
  );
}

bool hasConfiguredEmbeddingRoute(AiSettings settings) {
  final resolved = AiRouteResolver.resolveTaskRoute(
    services: settings.services,
    bindings: settings.taskRouteBindings,
    routeId: AiTaskRouteId.embeddingRetrieval,
    capability: AiCapability.embedding,
  );
  if (resolved != null) {
    return _hasResolvedRouteConfig(resolved);
  }

  final fallback = _fallbackEmbeddingProfile(settings);
  if (fallback == null) return false;
  return _hasLegacyProfileConfig(
    baseUrl: fallback.baseUrl,
    model: fallback.model,
    apiKey: fallback.apiKey,
    requiresApiKey: fallback.backendKind != AiBackendKind.localApi,
  );
}

List<AiSelectableRouteOption> selectableRouteOptionsForCapability(
  AiSettings settings, {
  required AiCapability capability,
}) {
  final options = <AiSelectableRouteOption>[];
  for (final service in settings.services) {
    if (!service.enabled || service.baseUrl.trim().isEmpty) continue;
    for (final model in service.enabledModelsFor(capability)) {
      if (model.modelKey.trim().isEmpty) continue;
      options.add(AiSelectableRouteOption(service: service, model: model));
    }
  }
  return List<AiSelectableRouteOption>.unmodifiable(options);
}

AiGenerationProfile? _fallbackGenerationProfile(AiSettings settings) {
  if (settings.selectedGenerationProfile.enabled) {
    return settings.selectedGenerationProfile;
  }
  for (final profile in settings.generationProfiles) {
    if (profile.enabled) return profile;
  }
  return null;
}

AiEmbeddingProfile? _fallbackEmbeddingProfile(AiSettings settings) {
  final selected = settings.selectedEmbeddingProfile;
  if (selected != null && selected.enabled) return selected;
  for (final profile in settings.embeddingProfiles) {
    if (profile.enabled) return profile;
  }
  return null;
}

bool _hasResolvedRouteConfig(AiResolvedTaskRoute route) {
  final service = route.service;
  final model = route.model;
  final template = findAiProviderTemplate(service.templateId);
  return _hasLegacyProfileConfig(
    baseUrl: service.baseUrl,
    model: model.modelKey,
    apiKey: service.apiKey,
    requiresApiKey: template?.requiresApiKey ?? true,
  );
}

bool _hasLegacyProfileConfig({
  required String baseUrl,
  required String model,
  required String apiKey,
  required bool requiresApiKey,
}) {
  return baseUrl.trim().isNotEmpty &&
      model.trim().isNotEmpty &&
      (!requiresApiKey || apiKey.trim().isNotEmpty);
}
