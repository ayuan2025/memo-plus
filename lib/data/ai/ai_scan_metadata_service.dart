import 'dart:typed_data';

import '../../core/memo_scan_metadata.dart';
import '../logs/log_manager.dart';
import '../models/app_preferences.dart';
import 'ai_provider_adapter.dart';
import 'ai_provider_models.dart';
import 'ai_task_runtime.dart';

/// Why a scan-reading attempt did not produce metadata.
///
/// The distinction matters to the UI: an unusable answer is a normal thing for
/// a model to produce and should be reported quietly, whereas a request that
/// never got an answer is worth telling the user about, because it usually
/// means their provider or network needs attention.
enum AiScanMetadataFailure {
  /// Metadata was produced.
  none,

  /// No chat route could be resolved, so nothing was ever sent.
  noRoute,

  /// The provider was reached but the call failed.
  requestFailed,

  /// The provider answered, but nothing usable could be read out of it.
  unusableResponse,
}

/// The outcome of asking a model to read a scanned page.
class AiScanMetadataOutcome {
  const AiScanMetadataOutcome._(this.draft, this.failure);

  const AiScanMetadataOutcome.succeeded(ScanMetadataDraft draft)
    : this._(draft, AiScanMetadataFailure.none);

  const AiScanMetadataOutcome.failed(AiScanMetadataFailure failure)
    : this._(null, failure);

  final ScanMetadataDraft? draft;
  final AiScanMetadataFailure failure;

  bool get succeeded => draft != null;
}

/// Reads a scanned page and proposes a memo title and tags for it.
///
/// Uses the same provider, credentials and proxy the user already configured
/// for their other AI features — the image goes out through the shared adapter,
/// so a `qwen` / `zhipu` / `siliconflow` endpoint needs no separate setup.
class AiScanMetadataService {
  const AiScanMetadataService({required AiTaskRuntime runtime})
    : _runtime = runtime;

  final AiTaskRuntime _runtime;

  /// Whether the user has any chat model this could be sent to.
  ///
  /// The scan screen uses this to decide whether to offer the action at all,
  /// rather than showing a button that is guaranteed to explain it cannot work.
  bool isAvailable(AiSettings settings) =>
      _runtime.resolveChatRoute(
        settings,
        routeId: AiTaskRouteId.scanMetadata,
      ) !=
      null;

  Future<AiScanMetadataOutcome> generate({
    required AiSettings settings,
    required Uint8List imageBytes,
    AppLanguage language = AppLanguage.zhHans,
  }) async {
    if (imageBytes.isEmpty) {
      return const AiScanMetadataOutcome.failed(
        AiScanMetadataFailure.unusableResponse,
      );
    }
    if (!isAvailable(settings)) {
      return const AiScanMetadataOutcome.failed(AiScanMetadataFailure.noRoute);
    }

    final AiChatCompletionResult result;
    try {
      result = await _runtime.chatCompletion(
        settings: settings,
        routeId: AiTaskRouteId.scanMetadata,
        systemPrompt: _systemPrompt(language),
        // Low temperature: this is transcription-adjacent work, not writing,
        // and a wandering answer is more likely to fail the JSON contract.
        temperature: 0.2,
        maxOutputTokens: 400,
        messages: <AiChatMessage>[
          AiChatMessage(
            role: 'user',
            content: _instruction(language),
            images: <AiImagePart>[AiImagePart(bytes: imageBytes)],
          ),
        ],
      );
    } catch (error, stackTrace) {
      // A text-only model handed an image, a rejected key, a timeout — all of
      // them are the same thing to the user, and none of them should cost them
      // the scan they just took.
      LogManager.instance.warn(
        'AiScanMetadataService: request_failed',
        error: error,
        stackTrace: stackTrace,
        context: {'bytes': imageBytes.length},
      );
      return const AiScanMetadataOutcome.failed(
        AiScanMetadataFailure.requestFailed,
      );
    }

    final draft = parseScanMetadataResponse(result.text);
    if (draft == null) {
      LogManager.instance.info(
        'AiScanMetadataService: unusable_response',
        context: {'chars': result.text.length},
      );
      return const AiScanMetadataOutcome.failed(
        AiScanMetadataFailure.unusableResponse,
      );
    }
    return AiScanMetadataOutcome.succeeded(draft);
  }

  static String _systemPrompt(AppLanguage language) {
    if (_isChinese(language)) {
      return '你负责阅读纸质文档的照片，并为这条备忘录起标题和打标签。'
          '只输出一个 JSON 对象，形如 {"title": "标题", "tags": ["标签"]}。'
          '不要输出任何解释、前言或 Markdown 代码块。'
          '$_kKindInstructionZh';
    }
    return 'You read photos of paper documents and propose a memo title and tags. '
        'Reply with a single JSON object shaped like '
        '{"title": "...", "tags": ["..."]}. '
        'Output nothing else — no explanation, no Markdown fences. '
        '$_kKindInstructionEn';
  }

  /// Telling the model what the offline rules look for keeps the two readers in
  /// agreement: whichever of them answers, the same card lands under the same
  /// tag, and searching for it works whether the device could read it offline
  /// or had to ask.
  static const String _kKindInstructionZh =
      '如果这是常见的证件或票据，tags 里必须包含它的类别词：'
      '身份证、护照、驾照、行驶证、居住证、通行证、社保卡、营业执照、'
      '发票、收据、小票、银行卡、登机牌、车票、名片；'
      'title 写成「类别词 · 姓名或单位名」，类别词一律用上面这些短词'
      '（要写「身份证」，不要写「中华人民共和国居民身份证」），'
      '读不到姓名或单位名就只写类别词。';

  static const String _kKindInstructionEn =
      'When the page is a card or slip, tags must include its type word: '
      'passport, id-card, driving-licence, vehicle-registration, '
      'residence-permit, travel-permit, social-security, business-licence, '
      'invoice, receipt, till-receipt, bank-card, boarding-pass, ticket, '
      'business-card; and title must start with that same short type word '
      'followed by " · " and the name it bears — write "id-card", not '
      '"National Identity Card". Use the type word alone when no name can be '
      'read.';

  static String _instruction(AppLanguage language) {
    if (_isChinese(language)) {
      return '请阅读附件中的扫描件，然后用 JSON 回答：'
          'title 是不超过 $kScanMetadataMaxTitleChars 个字的中文标题，'
          '概括文档内容与用途，不要以标点结尾，不要带 # 号；'
          'tags 是不超过 $kScanMetadataMaxTags 个的短标签，'
          '每个不超过 $kScanMetadataMaxTagChars 个字，'
          '类别词要写成下面准备好的样子（身份证/护照/驾照/营业执照/发票/小票 等），'
          '只含中文、字母、数字或 -，不要用其它近义词替代，不要空格，不要带 # 前缀。';
    }
    return 'Read the attached scan and answer with JSON: '
        '"title" is a title of at most $kScanMetadataMaxTitleChars characters '
        'summarising what the document is, without trailing punctuation and '
        'without a leading #; '
        '"tags" is at most $kScanMetadataMaxTags short keyword tags, each at '
        'most $kScanMetadataMaxTagChars characters, using the prepared type '
        'words (passport, id-card, driving-licence, business-licence, invoice, '
        'till-receipt and so on) rather than synonyms, letters/digits/- only, '
        'no spaces and no leading #.';
  }

  static bool _isChinese(AppLanguage language) =>
      language == AppLanguage.zhHans ||
      language == AppLanguage.zhHantTw ||
      language == AppLanguage.system;
}
