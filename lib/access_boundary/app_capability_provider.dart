import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../private_hooks/private_extension_bundle_provider.dart';
import 'access_decision.dart';
import 'app_capability.dart';

final appCapabilityDecisionProvider =
    Provider.family<AccessDecision, AppCapability>((ref, capability) {
      final bundle = ref.watch(privateExtensionBundleProvider);
      return bundle.diagnosticsAccessBoundary.decisionFor(capability);
    });

final appCapabilityEnabledProvider = Provider.family<bool, AppCapability>((
  ref,
  capability,
) {
  return ref.watch(appCapabilityDecisionProvider(capability)).enabled;
});
