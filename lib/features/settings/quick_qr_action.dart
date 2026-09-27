import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/migration/memoflow_migration_protocol.dart';
import '../../core/top_toast.dart';
import '../../i18n/strings.g.dart';
import 'memoflow_bridge_screen.dart';
import 'migration/memoflow_migration_sender_screen.dart';

enum QuickQrActionKind { bridgePairing, migrationSender }

class QuickQrActionTarget {
  const QuickQrActionTarget({required this.kind, required this.rawPayload});

  final QuickQrActionKind kind;
  final String rawPayload;
}

QuickQrActionTarget? classifyQuickQrPayload(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  if (parseMemoFlowMigrationConnectUri(trimmed) != null) {
    return QuickQrActionTarget(
      kind: QuickQrActionKind.migrationSender,
      rawPayload: trimmed,
    );
  }
  if (MemoFlowBridgePairingPayload.tryParse(trimmed) != null) {
    return QuickQrActionTarget(
      kind: QuickQrActionKind.bridgePairing,
      rawPayload: trimmed,
    );
  }
  return null;
}

String _universalQuickQrHint(BuildContext context) {
  final tag = Localizations.localeOf(context).toLanguageTag().toLowerCase();
  if (tag.startsWith('zh-hant') ||
      tag.startsWith('zh-tw') ||
      tag.startsWith('zh-hk')) {
    return '\u6383\u63cf\u5c0d\u65b9\u88dd\u7f6e\u6216\u5916\u639b\u986f\u793a\u7684\u4e8c\u7dad\u78bc\u4ee5\u7e7c\u7e8c';
  }
  if (tag.startsWith('zh')) {
    return '\u626b\u63cf\u5bf9\u65b9\u8bbe\u5907\u6216\u63d2\u4ef6\u663e\u793a\u7684\u4e8c\u7ef4\u7801\u4ee5\u7ee7\u7eed';
  }
  return 'Scan the QR code shown on the other device or plugin to continue.';
}

Future<void> startUniversalQuickQrAction({
  required BuildContext context,
  required WidgetRef ref,
}) async {
  if (!supportsMemoFlowQrScannerOnCurrentPlatform()) {
    showMemoFlowQrUnsupportedNotice(context);
    return;
  }

  final tr = context.t.strings.legacy;
  final raw = await Navigator.of(context, rootNavigator: true).push<String>(
    MaterialPageRoute<String>(
      builder: (_) => MemoFlowPairQrScanScreen(
        titleText: tr.msg_bridge_scan_title,
        hintText: _universalQuickQrHint(context),
      ),
    ),
  );
  if (raw == null || raw.trim().isEmpty) return;
  if (!context.mounted) return;

  final target = classifyQuickQrPayload(raw);
  if (target == null) {
    showTopToast(context, tr.msg_bridge_qr_invalid);
    return;
  }

  switch (target.kind) {
    case QuickQrActionKind.bridgePairing:
      await pairMemoFlowBridgeFromQrRaw(
        context: context,
        ref: ref,
        raw: target.rawPayload,
      );
      return;
    case QuickQrActionKind.migrationSender:
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute<void>(
          builder: (_) => MemoFlowMigrationSenderScreen(
            initialReceiverQrPayload: target.rawPayload,
          ),
        ),
      );
      return;
  }
}
