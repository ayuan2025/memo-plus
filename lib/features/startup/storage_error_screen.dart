import 'package:flutter/material.dart';

import '../../core/splash_tokens.g.dart';
import '../../core/storage_read.dart';
import '../../i18n/strings.g.dart';

class StorageErrorScreen extends StatelessWidget {
  const StorageErrorScreen({
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
    final bg = SplashTokens.backgroundColor;
    final primary = SplashTokens.brandColor;
    final text = primary.withValues(alpha: 0.9);
    final detail = primary.withValues(alpha: 0.75);

    return ColoredBox(
      color: bg,
      child: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 56, color: primary),
                const SizedBox(height: 16),
                Text(
                  context.t.strings.legacy.msg_local_storage_unavailable,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: text,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  context.t.strings.legacy.msg_check_system_permissions_or_retry_later,
                  style: TextStyle(fontSize: 13, color: detail, height: 1.4),
                  textAlign: TextAlign.center,
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    context.t.strings.legacy.msg_source_value(source: error!.source),
                    style: TextStyle(fontSize: 11, color: detail),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ElevatedButton(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(context.t.strings.legacy.msg_retry),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: onExit,
                      child: Text(
                        context.t.strings.legacy.msg_exit_app,
                        style: TextStyle(color: detail),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
