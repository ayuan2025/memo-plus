import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/access_boundary/app_capability.dart';
import 'package:memos_flutter_app/access_boundary/app_capability_provider.dart';
import 'package:memos_flutter_app/private_hooks/private_extension_bundle_provider.dart';

void main() {
  testWidgets('public bundle stays disabled and exposes no settings entries', (
    tester,
  ) async {
    late bool enabled;
    late String source;
    late List<Object> entries;
    late Future<void> readyFuture;

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            final bundle = ref.watch(privateExtensionBundleProvider);
            final decision = bundle.diagnosticsAccessBoundary.decisionFor(
              AppCapability.subscriptionCenter,
            );
            enabled = decision.enabled;
            source = decision.source;
            entries = bundle.settingsEntries(context, ref);
            readyFuture = bundle.onAppReady(ref);
            return const MaterialApp(home: SizedBox.shrink());
          },
        ),
      ),
    );

    await readyFuture;

    expect(enabled, isFalse);
    expect(source, 'public-default');
    expect(entries, isEmpty);
  });

  testWidgets('public capability seam disables commercial capabilities', (
    tester,
  ) async {
    final decisions = <AppCapability, bool>{};

    await tester.pumpWidget(
      ProviderScope(
        child: Consumer(
          builder: (context, ref, _) {
            for (final capability in AppCapability.values) {
              decisions[capability] = ref.watch(
                appCapabilityEnabledProvider(capability),
              );
            }
            return const MaterialApp(home: SizedBox.shrink());
          },
        ),
      ),
    );

    expect(decisions, hasLength(AppCapability.values.length));
    expect(decisions.values, everyElement(isFalse));
  });
}
