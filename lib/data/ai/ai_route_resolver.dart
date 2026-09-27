import 'ai_provider_models.dart';

enum AiRouteResolutionSource { exact, serviceFallback, globalFallback }

class AiResolvedTaskRoute {
  const AiResolvedTaskRoute({
    required this.routeId,
    required this.binding,
    required this.service,
    required this.model,
    required this.source,
  });

  final AiTaskRouteId routeId;
  final AiTaskRouteBinding? binding;
  final AiServiceInstance service;
  final AiModelEntry model;
  final AiRouteResolutionSource source;
}

class AiRouteResolver {
  const AiRouteResolver._();

  static AiResolvedTaskRoute? resolveTaskRoute({
    required List<AiServiceInstance> services,
    required List<AiTaskRouteBinding> bindings,
    required AiTaskRouteId routeId,
    required AiCapability capability,
  }) {
    final binding = _findBinding(bindings, routeId);
    if (binding != null) {
      final boundService = services.firstById(binding.serviceId);
      final boundModel = boundService?.models.firstById(binding.modelId);
      if (_isUsable(boundService, boundModel, capability)) {
        return AiResolvedTaskRoute(
          routeId: routeId,
          binding: binding,
          service: boundService!,
          model: boundModel!,
          source: AiRouteResolutionSource.exact,
        );
      }

      if (boundService != null && boundService.enabled) {
        final fallbackModel = _firstOrNull(
          boundService.enabledModelsFor(capability),
        );
        if (fallbackModel != null) {
          return AiResolvedTaskRoute(
            routeId: routeId,
            binding: binding,
            service: boundService,
            model: fallbackModel,
            source: AiRouteResolutionSource.serviceFallback,
          );
        }
      }
    }

    for (final service in services) {
      if (!service.enabled) continue;
      final model = _firstOrNull(service.enabledModelsFor(capability));
      if (model == null) continue;
      return AiResolvedTaskRoute(
        routeId: routeId,
        binding: binding,
        service: service,
        model: model,
        source: AiRouteResolutionSource.globalFallback,
      );
    }
    return null;
  }

  static AiTaskRouteBinding? _findBinding(
    List<AiTaskRouteBinding> bindings,
    AiTaskRouteId routeId,
  ) {
    for (final binding in bindings) {
      if (binding.routeId == routeId) return binding;
    }
    return null;
  }

  static bool _isUsable(
    AiServiceInstance? service,
    AiModelEntry? model,
    AiCapability capability,
  ) {
    if (service == null || model == null) return false;
    if (!service.enabled || !model.enabled) return false;
    return model.supports(capability);
  }

  static T? _firstOrNull<T>(Iterable<T> values) {
    return values.isEmpty ? null : values.first;
  }
}
