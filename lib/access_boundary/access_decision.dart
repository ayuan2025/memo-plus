import 'package:flutter/foundation.dart';

@immutable
class AccessDecision {
  const AccessDecision({required this.enabled, required this.source});

  const AccessDecision.disabled(this.source) : enabled = false;

  final bool enabled;

  /// Diagnostic-only source marker.
  ///
  /// This field must not be used for business logic, UI visibility, routing,
  /// or entitlement decisions.
  final String source;
}
