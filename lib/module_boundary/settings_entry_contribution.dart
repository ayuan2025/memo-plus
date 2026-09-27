import 'package:flutter/material.dart';

typedef SettingsEntryTextBuilder = String Function(BuildContext context);

class SettingsEntryContribution {
  const SettingsEntryContribution({
    required this.id,
    required this.order,
    required this.icon,
    required this.titleBuilder,
    this.subtitleBuilder,
    required this.onTap,
  });

  final String id;
  final int order;
  final IconData icon;
  final SettingsEntryTextBuilder titleBuilder;
  final SettingsEntryTextBuilder? subtitleBuilder;
  final VoidCallback onTap;
}
