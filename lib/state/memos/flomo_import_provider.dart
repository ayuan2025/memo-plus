import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flomo_import_controller.dart';

final flomoImportControllerProvider = Provider<FlomoImportController>((ref) {
  return const FlomoImportController();
});
