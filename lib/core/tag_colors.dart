import 'package:flutter/material.dart';

class TagChipColors {
  const TagChipColors({
    required this.background,
    required this.border,
    required this.text,
  });

  final Color background;
  final Color border;
  final Color text;
}

String? normalizeTagColorHex(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  var hex = trimmed.startsWith('#') ? trimmed.substring(1) : trimmed;
  if (hex.length == 8) {
    hex = hex.substring(2);
  }
  if (hex.length != 6) return null;
  final upper = hex.toUpperCase();
  if (!RegExp(r'^[0-9A-F]{6}$').hasMatch(upper)) return null;
  return '#$upper';
}

Color? parseTagColor(String? raw) {
  final normalized = normalizeTagColorHex(raw);
  if (normalized == null) return null;
  final value = int.parse(normalized.substring(1), radix: 16);
  return Color(0xFF000000 | value);
}

Color resolveReadableTextColor(Color background) {
  final luminance = background.computeLuminance();
  return luminance > 0.6 ? Colors.black : Colors.white;
}

TagChipColors buildTagChipColors({
  required Color baseColor,
  required Color surfaceColor,
  required bool isDark,
}) {
  final background = baseColor;
  final text = resolveReadableTextColor(background);
  final border =
      isDark ? baseColor.withValues(alpha: 0.7) : baseColor.withValues(alpha: 0.85);
  return TagChipColors(background: background, border: border, text: text);
}
