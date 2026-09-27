import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/maintenance/media_cache_maintenance_service.dart';

final mediaCacheMaintenanceServiceProvider =
    Provider<MediaCacheMaintenanceService>((ref) {
      return MediaCacheMaintenanceService.defaults();
    });
