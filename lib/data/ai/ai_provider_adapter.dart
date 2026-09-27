import 'dart:convert';
import 'dart:typed_data';

import 'ai_provider_models.dart';
import 'ai_settings_models.dart';

export 'ai_settings_models.dart';

/// An image attached to a chat message.
///
/// Carried as raw bytes rather than a path or URL so a message stays a plain
/// value: no file handle has to survive the trip to the adapter, and the same
/// message works on platforms where the image only ever existed in memory
/// (a freshly scanned page, for instance).
class AiImagePart {
  const AiImagePart({required this.bytes, this.mimeType = 'image/jpeg'});

  final Uint8List bytes;
  final String mimeType;

  /// The image as bare base64, which is what Ollama's `images` field wants.
  String toBase64() => base64Encode(bytes);

  /// The image as an `image_url` data URL, which is the shape every
  /// OpenAI-compatible provider expects for an inline image.
  String toDataUrl() {
    return 'data:$mimeType;base64,${toBase64()}';
  }
}

class AiChatMessage {
  const AiChatMessage({
    required this.role,
    required this.content,
    this.images = const <AiImagePart>[],
  });

  final String role;
  final String content;

  /// Images to send along with [content].
  ///
  /// Empty for every text-only call, and adapters that do not support images
  /// keep sending `content` as a bare string, so adding this changes nothing
  /// about existing behaviour.
  final List<AiImagePart> images;

  bool get hasImages => images.isNotEmpty;
}

class AiChatCompletionRequest {
  const AiChatCompletionRequest({
    required this.service,
    required this.model,
    required this.messages,
    this.systemPrompt,
    this.temperature,
    this.maxOutputTokens,
    this.proxySettings,
  });

  final AiServiceInstance service;
  final AiModelEntry model;
  final List<AiChatMessage> messages;
  final String? systemPrompt;
  final double? temperature;
  final int? maxOutputTokens;
  final AiProxySettings? proxySettings;
}

class AiChatCompletionResult {
  const AiChatCompletionResult({required this.text, required this.raw});

  final String text;
  final Object? raw;
}

class AiEmbeddingRequest {
  const AiEmbeddingRequest({
    required this.service,
    required this.model,
    required this.input,
    this.proxySettings,
  });

  final AiServiceInstance service;
  final AiModelEntry model;
  final String input;
  final AiProxySettings? proxySettings;
}

class AiDiscoveredModel {
  const AiDiscoveredModel({
    required this.displayName,
    required this.modelKey,
    required this.capabilities,
    this.ownedBy,
  });

  final String displayName;
  final String modelKey;
  final List<AiCapability> capabilities;
  final String? ownedBy;
}

class AiServiceValidationResult {
  const AiServiceValidationResult({required this.status, this.message});

  final AiValidationStatus status;
  final String? message;
}

abstract class AiProviderAdapter {
  Future<AiServiceValidationResult> validateConfig(
    AiServiceInstance service, {
    AiProxySettings? proxySettings,
  });

  Future<List<AiDiscoveredModel>> listModels(
    AiServiceInstance service, {
    AiProxySettings? proxySettings,
  });

  Future<AiChatCompletionResult> chatCompletion(
    AiChatCompletionRequest request,
  );

  Future<List<double>> embed(AiEmbeddingRequest request);
}
