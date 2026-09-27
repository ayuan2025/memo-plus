import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/ai/ai_scan_metadata_service.dart';
import '../../data/ai/ai_task_runtime.dart';
import '../../data/scan/local_document_text_service.dart';
import '../../data/scan/local_scan_metadata_service.dart';
import '../../data/scan/ocr_page_preprocessor.dart';
import '../settings/ai_settings_provider.dart';

/// Flattens the lighting out of a page before the recogniser sees it.
final ocrPagePreprocessorProvider = Provider<OcrPagePreprocessor>((ref) {
  return const OcrPagePreprocessor();
});

/// Runs the on-device recogniser.
final localDocumentTextServiceProvider = Provider<LocalDocumentTextService>((
  ref,
) {
  return const LocalDocumentTextService();
});

/// Reads a scanned page without a model and proposes a memo title and tags.
///
/// This is what the scanner uses by default, so the feature works with no AI
/// configured; [aiScanMetadataServiceProvider] stays available for pages the
/// rules cannot make sense of.
final localScanMetadataServiceProvider = Provider<LocalScanMetadataService>((
  ref,
) {
  return LocalScanMetadataService(
    textService: ref.watch(localDocumentTextServiceProvider),
    preprocessor: ref.watch(ocrPagePreprocessorProvider),
  );
});

/// Reads a scanned page and proposes a memo title and tags.
///
/// Shares the provider registry and the user's AI settings with every other AI
/// feature, so a service the user has already configured works here without any
/// scan-specific setup.
final aiScanMetadataServiceProvider = Provider<AiScanMetadataService>((ref) {
  return AiScanMetadataService(
    runtime: AiTaskRuntime(registry: ref.watch(aiProviderRegistryProvider)),
  );
});
