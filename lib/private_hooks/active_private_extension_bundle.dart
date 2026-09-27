import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../access_boundary/access_boundary.dart';
import '../access_boundary/access_decision.dart';
import '../access_boundary/app_capability.dart';
import '../module_boundary/settings_entry_contribution.dart';
import 'private_extension_bundle.dart';

PrivateExtensionBundle createActivePrivateExtensionBundle() =>
    const _PublicPrivateExtensionBundle();

class _PublicPrivateExtensionBundle implements PrivateExtensionBundle {
  const _PublicPrivateExtensionBundle();

  @override
  AccessBoundary get diagnosticsAccessBoundary =>
      const _PublicDiagnosticsAccessBoundary();

  @override
  Future<void> onAppReady(WidgetRef ref) async {}

  @override
  List<SettingsEntryContribution> settingsEntries(
    BuildContext context,
    WidgetRef ref,
  ) {
    return const <SettingsEntryContribution>[];
  }
}

class _PublicDiagnosticsAccessBoundary implements AccessBoundary {
  const _PublicDiagnosticsAccessBoundary();

  @override
  AccessDecision decisionFor(AppCapability capability) {
    return const AccessDecision.disabled('public-default');
  }
}
