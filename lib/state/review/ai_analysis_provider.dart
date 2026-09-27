import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_analysis_repository.dart';
import '../../data/ai/ai_analysis_service.dart';
import '../../data/ai/ai_task_runtime.dart';
import '../settings/ai_settings_provider.dart';
import '../system/database_provider.dart';

final aiAnalysisRepositoryProvider = Provider<AiAnalysisRepository>((ref) {
  return AiAnalysisRepository(
    ref.watch(databaseProvider),
    writeGateway: ref.watch(desktopDbWriteGatewayProvider),
  );
});

final aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService(
    repository: ref.watch(aiAnalysisRepositoryProvider),
    runtime: AiTaskRuntime(registry: ref.watch(aiProviderRegistryProvider)),
    readCurrentSettings: () => ref.read(aiSettingsProvider),
    dio: Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 60),
        sendTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 180),
      ),
    ),
  );
});
