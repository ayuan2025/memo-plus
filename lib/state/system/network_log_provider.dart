import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/logs/network_log_store.dart';
import '../settings/device_preferences_provider.dart';

final networkLogStoreProvider = Provider<NetworkLogStore>((ref) {
  final store = NetworkLogStore();
  store.setEnabled(ref.read(devicePreferencesProvider).networkLoggingEnabled);
  ref.listen<bool>(
    devicePreferencesProvider.select((p) => p.networkLoggingEnabled),
    (prev, next) {
      store.setEnabled(next);
    },
  );
  return store;
});
