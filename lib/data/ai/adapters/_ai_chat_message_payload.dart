import '../ai_provider_adapter.dart';

/// Wire shapes for an outgoing chat message's images.
///
/// There are exactly two shapes in use across the adapters in this folder, and
/// they disagree about where an image lives:
///
/// * OpenAI-compatible (plain OpenAI, Azure OpenAI, and every `qwen` / `zhipu`
///   / `siliconflow` endpoint) puts images inline in `content` as
///   `{"type": "image_url", ...}` parts.
/// * Ollama keeps `content` a plain string and lists base64 images in a
///   sibling `images` array.
///
/// Both live here so the three adapters cannot drift apart on the question of
/// *when* an image gets sent: the answer must be "only when the message
/// actually carries one", because a text-only call has to keep producing
/// byte-identical request bodies to what these providers saw before.

/// The `content` field for a message, as an OpenAI-compatible provider wants it.
///
/// Stays a plain `String` for text-only messages. Providers and the proxies
/// people put in front of them are markedly happier with the historical shape,
/// so the parts form is reserved for messages that genuinely carry an image.
Object openAiCompatibleMessageContent(AiChatMessage message) {
  if (!message.hasImages) return message.content;

  return <Map<String, Object?>>[
    if (message.content.trim().isNotEmpty)
      <String, Object?>{'type': 'text', 'text': message.content},
    for (final image in message.images)
      <String, Object?>{
        'type': 'image_url',
        'image_url': <String, Object?>{'url': image.toDataUrl()},
      },
  ];
}

/// The base64 image list an Ollama message carries, or null when it has none.
///
/// Ollama wants bare base64 without the `data:` URL wrapper that the
/// OpenAI-compatible shape requires.
List<String>? ollamaMessageImages(AiChatMessage message) {
  if (!message.hasImages) return null;
  return <String>[for (final image in message.images) image.toBase64()];
}
