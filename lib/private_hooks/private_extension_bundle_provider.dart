import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'active_private_extension_bundle.dart';
import 'private_extension_bundle.dart';

final privateExtensionBundleProvider = Provider<PrivateExtensionBundle>((ref) {
  return createActivePrivateExtensionBundle();
});
