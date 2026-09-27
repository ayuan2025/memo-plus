import 'package:flutter/widgets.dart';

import '../data/models/device_preferences.dart';
import 'system_fonts.dart';

class FontLoader {
  Future<void> ensureLoaded(
    DevicePreferences prefs, {
    VoidCallback? onLoaded,
  }) async {
    final family = prefs.fontFamily;
    final filePath = prefs.fontFile;
    if (family == null || family.trim().isEmpty) return;
    if (filePath == null || filePath.trim().isEmpty) return;
    final loaded = await SystemFonts.ensureLoaded(
      SystemFontInfo(family: family, displayName: family, filePath: filePath),
    );
    if (loaded) {
      onLoaded?.call();
    }
  }
}
