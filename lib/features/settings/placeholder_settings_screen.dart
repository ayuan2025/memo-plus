import 'package:flutter/material.dart';

import '../../i18n/strings.g.dart';
import 'settings_ui.dart';

class SettingsPlaceholderScreen extends StatelessWidget {
  const SettingsPlaceholderScreen({
    super.key,
    required this.titleKey,
    required this.messageKey,
  });

  final String titleKey;
  final String messageKey;

  @override
  Widget build(BuildContext context) {
    final title = context.t['strings.legacy.$titleKey'] as String;
    final message = context.t['strings.legacy.$messageKey'] as String;

    return SettingsPage(
      title: Text(title),
      children: [
        SettingsSection(
          children: [
            SettingsProfileSummary(icon: Icons.hourglass_empty, title: message),
          ],
        ),
      ],
    );
  }
}
