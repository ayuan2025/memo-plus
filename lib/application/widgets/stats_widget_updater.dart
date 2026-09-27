import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../state/memos/app_bootstrap_adapter_provider.dart';
import 'home_widgets_updater.dart';

@Deprecated('Use HomeWidgetsUpdater instead.')
class StatsWidgetUpdater {
  StatsWidgetUpdater({
    required AppBootstrapAdapter bootstrapAdapter,
    required bool Function() isMounted,
  }) : _delegate = HomeWidgetsUpdater(
         bootstrapAdapter: bootstrapAdapter,
         isMounted: isMounted,
       );

  final HomeWidgetsUpdater _delegate;

  void scheduleUpdate(WidgetRef ref) {
    _delegate.scheduleUpdate(ref);
  }

  Future<void> updateIfNeeded(WidgetRef ref, {bool force = false}) {
    return _delegate.updateIfNeeded(ref, force: force);
  }
}
