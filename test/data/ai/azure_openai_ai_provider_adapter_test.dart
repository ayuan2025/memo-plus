import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/data/ai/adapters/azure_openai_ai_provider_adapter.dart';
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
        'query': request.uri.queryParameters,
        'headers': headers,
        'body': body,
      });

      request.response.headers.contentType = ContentType.json;
      if (request.uri.path == '/openai/chat/completions') {
        request.response.write(
          jsonEncode(<String, Object?>{
            'choices': <Object?>[
              <String, Object?>{
                'message': <String, Object?>{'content': 'azure hello'},
              },
            ],
          }),
        );
      } else if (request.uri.path == '/openai/embeddings') {
        request.response.write(
          jsonEncode(<String, Object?>{
            'data': <Object?>[
              <String, Object?>{
                'embedding': <Object?>[0.1, 0.2, 0.3],
              },
            ],
          }),
        );
      } else if (request.uri.path == '/openai/models') {
        request.response.write(
          jsonEncode(<String, Object?>{'data': <Object?>[]}),
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

  test('chat completion uses azure openai runtime endpoint', () async {
    const adapter = AzureOpenAiAiProviderAdapter();
    final service = _service(baseUrl: baseUrl);

    final result = await adapter.chatCompletion(
      AiChatCompletionRequest(
        service: service,
        model: service.models.first,
        messages: const <AiChatMessage>[
          AiChatMessage(role: 'user', content: 'hello'),
        ],
      ),
    );

    expect(result.text, 'azure hello');
    expect(requests.single['path'], '/openai/chat/completions');
    expect(requests.single['query'], <String, String>{
      'api-version': '2024-10-21',
    });
    final headers = requests.single['headers']! as Map<String, String>;
    expect(headers['api-key'], 'azure-key');
    final body = requests.single['body']! as Map<String, Object?>;
    expect(body['model'], 'gpt-4o-mini');
  });

  test('embedding uses azure openai runtime endpoint', () async {
    const adapter = AzureOpenAiAiProviderAdapter();
    final service = _service(baseUrl: baseUrl);

    final vector = await adapter.embed(
      AiEmbeddingRequest(
        service: service,
        model: service.models.last,
        input: 'hello',
      ),
    );

    expect(vector, <double>[0.1, 0.2, 0.3]);
    expect(requests.single['path'], '/openai/embeddings');
    expect(requests.single['query'], <String, String>{
      'api-version': '2024-10-21',
    });
    final body = requests.single['body']! as Map<String, Object?>;
    expect(body['model'], 'text-embedding-3-small');
    expect(body['input'], 'hello');
  });
}

AiServiceInstance _service({required String baseUrl}) {
  return AiServiceInstance(
    serviceId: 'svc_azure',
    templateId: aiTemplateAzureOpenAi,
    adapterKind: AiProviderAdapterKind.azureOpenAi,
    displayName: 'Azure OpenAI',
    enabled: true,
    baseUrl: baseUrl,
    apiKey: 'azure-key',
    customHeaders: const <String, String>{'api-version': '2024-10-21'},
    models: const <AiModelEntry>[
      AiModelEntry(
        modelId: 'mdl_chat',
        displayName: 'GPT-4o mini',
        modelKey: 'gpt-4o-mini',
        capabilities: <AiCapability>[AiCapability.chat],
        source: AiModelSource.manual,
        enabled: true,
      ),
      AiModelEntry(
        modelId: 'mdl_embed',
        displayName: 'Embedding Small',
        modelKey: 'text-embedding-3-small',
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
