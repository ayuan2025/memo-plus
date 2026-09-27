import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/sync/sync_request.dart';
import '../../data/api/memo_api_facade.dart';
import '../../data/api/memo_api_probe.dart';
import '../../data/api/memo_api_version.dart';
import '../sync/sync_coordinator_provider.dart';
part 'login_controller.dart';
part 'login_probe_helpers.dart';

final loginControllerProvider = Provider<LoginController>((ref) {
  return LoginController(ref);
});