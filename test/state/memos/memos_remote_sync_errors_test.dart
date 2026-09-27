import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/state/memos/memos_providers.dart';

void main() {
  test('summarizes HTTP 413 as attachment too large', () {
    final error = _dioError(
      statusCode: 413,
      data: const <String, Object?>{'message': 'payload too large'},
    );

    final summary = summarizeMemosHttpErrorForTesting(error);

    expect(summary.httpStatus, 413);
    expect(
      summary.presentationParams?['baseKey'],
      'legacy.msg_attachment_too_large',
    );
    expect(summary.message, 'payload too large');
  });

  test(
    'summarizes backend file size limit message as attachment too large',
    () {
      final error = _dioError(
        statusCode: 400,
        data: const <String, Object?>{
          'message': 'file size exceeds the limit: 60 MiB',
        },
      );

      final summary = summarizeMemosHttpErrorForTesting(error);

      expect(summary.httpStatus, 400);
      expect(
        summary.presentationParams?['baseKey'],
        'legacy.msg_attachment_too_large',
      );
      expect(summary.message, 'file size exceeds the limit: 60 MiB');
    },
  );
}

DioException _dioError({required int statusCode, required Object data}) {
  final requestOptions = RequestOptions(
    path: '/api/v1/attachments',
    method: 'POST',
    baseUrl: 'https://memos.example',
  );
  return DioException(
    requestOptions: requestOptions,
    response: Response<Object>(
      requestOptions: requestOptions,
      statusCode: statusCode,
      data: data,
    ),
    type: DioExceptionType.badResponse,
  );
}
