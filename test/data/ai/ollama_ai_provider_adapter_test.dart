import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/ai/adapters/ollama_ai_provider_adapter.dart';
import 'package:memos_flutter_app/data/repositories/ai_settings_repository.dart';

void main() {
  late HttpServer server;
  late String baseUrl;
  late List<Map<String, Object?>> requests;

  setUp(() async {
    requests = <Map<String, Object?>>[];
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://${server.address.host}:${server.port}';
    server.listen((request) async {
      final bodyText = await utf8.decoder.bind(request).join();
      Object? body;
      if (bodyText.trim().isNotEmpty) {
        body = jsonDecode(bodyText);
      }
      final headers = <String, String>{};
      request.headers.forEach((name, values) {
        headers[name] = values.join(',');
      });
      requests.add(<String, Object?>{
        'method': request.method,
        'path': request.uri.path,
        'headers': headers,
        'body': body,
      });

      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/api/chat') {
        request.response.write(
          jsonEncode(<String, Object?>{
            'message': <String, Object?>{'content': 'ollama hello'},
          }),
        );
      } else if (request.uri.path == '/api/embed') {
        request.response.write(
          jsonEncode(<String, Object?>{
            'embeddings': <Object?>[
              <Object?>[0.9, 0.8, 0.7],
            ],
          }),
        );
      } else if (request.uri.path == '/api/tags') {
        request.response.write(
          jsonEncode(<String, Object?>{
            'models': <Object?>[
              <String, Object?>{'name': 'llama3.2'},
            ],
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
        request.response.write(
          jsonEncode(<String, Object?>{'error': 'unexpected path'}),
        );
      }
      await request.response.close();
    });
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('chat completion uses ollama native chat endpoint', () async {
    const adapter = OllamaAiProviderAdapter();
    final service = _service(baseUrl: baseUrl);

    final result = await adapter.chatCompletion(
      AiChatCompletionRequest(
        service: service,
        model: service.models.first,
        messages: const <AiChatMessage>[
          AiChatMessage(role: 'user', content: 'hello'),
        ],
        systemPrompt: 'be brief',
        temperature: 0.3,
        maxOutputTokens: 32,
      ),
    );

    expect(result.text, 'ollama hello');
    expect(requests.single['path'], '/api/chat');
    final body = requests.single['body']! as Map<String, Object?>;
    expect(body['model'], 'llama3.2');
    expect(body['stream'], isFalse);
    expect((body['messages']! as List<Object?>).length, 2);
    final options = body['options']! as Map<String, Object?>;
    expect(options['temperature'], 0.3);
    expect(options['num_predict'], 32);
  });

  test('embedding uses ollama native embed endpoint', () async {
    const adapter = OllamaAiProviderAdapter();
    final service = _service(baseUrl: baseUrl);

    final vector = await adapter.embed(
      AiEmbeddingRequest(
        service: service,
        model: service.models.last,
        input: 'hello',
      ),
    );

    expect(vector, <double>[0.9, 0.8, 0.7]);
    expect(requests.single['path'], '/api/embed');
    final body = requests.single['body']! as Map<String, Object?>;
    expect(body['model'], 'nomic-embed-text');
    expect(body['input'], 'hello');
  });

  test('list models sends auth header to ollama tags endpoint', () async {
    const adapter = OllamaAiProviderAdapter();
    final service = _service(baseUrl: baseUrl, apiKey: 'ollama-key');

    final models = await adapter.listModels(service);

    expect(models, hasLength(1));
    expect(requests.single['path'], '/api/tags');
    final headers = requests.single['headers']! as Map<String, String>;
    expect(headers['authorization'], 'Bearer ollama-key');
  });
}

AiServiceInstance _service({required String baseUrl, String apiKey = ''}) {
  return AiServiceInstance(
    serviceId: 'svc_ollama',
    templateId: aiTemplateOllama,
    adapterKind: AiProviderAdapterKind.ollama,
    displayName: 'Ollama',
    enabled: true,
    baseUrl: baseUrl,
    apiKey: apiKey,
    customHeaders: const <String, String>{},
    models: const <AiModelEntry>[
      AiModelEntry(
        modelId: 'mdl_chat',
        displayName: 'Llama 3.2',
        modelKey: 'llama3.2',
        capabilities: <AiCapability>[AiCapability.chat],
        source: AiModelSource.manual,
        enabled: true,
      ),
      AiModelEntry(
        modelId: 'mdl_embed',
        displayName: 'Nomic Embed',
        modelKey: 'nomic-embed-text',
        capabilities: <AiCapability>[AiCapability.embedding],
        source: AiModelSource.manual,
        enabled: true,
      ),
    ],
    lastValidatedAt: null,
    lastValidationStatus: AiValidationStatus.unknown,
    lastValidationMessage: null,
  );
}
