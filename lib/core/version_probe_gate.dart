import 'package:flutter/foundation.dart';

bool shouldEnableVersionProbe({required bool isReleaseMode}) {
  return !isReleaseMode;
}

bool get isVersionProbeEnabled =>
    shouldEnableVersionProbe(isReleaseMode: kReleaseMode);
