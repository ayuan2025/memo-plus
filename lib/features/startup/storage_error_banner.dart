import 'package:flutter/material.dart';

import '../../core/storage_read.dart';
import '../../i18n/strings.g.dart';

class StorageErrorBanner extends StatelessWidget {
  const StorageErrorBanner({
    super.key,
    required this.error,
    required this.onRetry,
    required this.onExit,
  });

  final StorageLoadError? error;
  final VoidCallback onRetry;
  final VoidCallback onExit;

  @override
  Widget build(BuildContext context) {
    final bg = Colors.orange.shade700;
    return SafeArea(
      bottom: false,
      child: Container(
        margin: const EdgeInsets.all(12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              offset: const Offset(0, 6),
              color: Colors.black.withValues(alpha: 0.2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                context
                    .t
                    .strings
                    .legacy
                    .msg_storage_read_failed_some_features_limited,
                style: const TextStyle(color: Colors.white, fontSize: 12.5),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: Text(
                context.t.strings.legacy.msg_retry,
                style: const TextStyle(color: Colors.white),
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: onExit,
              child: Text(
                context.t.strings.legacy.msg_exit_app,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
