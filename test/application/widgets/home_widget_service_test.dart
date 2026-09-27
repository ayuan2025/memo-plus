import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:memos_flutter_app/application/widgets/home_widget_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('memoflow/widgets');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('consumePendingLaunch parses legacy stats action as calendar', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getPendingWidgetLaunch':
              return null;
            case 'getPendingWidgetAction':
              return 'stats';
            default:
              return null;
          }
        });

    final payload = await HomeWidgetService.consumePendingLaunch();

    expect(payload, isNotNull);
    expect(payload!.widgetType, HomeWidgetType.calendar);
    expect(payload.memoUid, isNull);
    expect(payload.dayEpochSec, isNull);
  });

  test('consumePendingLaunch parses structured memo payload', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'getPendingWidgetLaunch':
              return <String, Object?>{
                'widgetType': 'dailyReview',
                'memoUid': 'memo-123',
              };
            default:
              return null;
          }
        });

    final payload = await HomeWidgetService.consumePendingLaunch();

    expect(payload, isNotNull);
    expect(payload!.widgetType, HomeWidgetType.dailyReview);
    expect(payload.memoUid, 'memo-123');
    expect(payload.dayEpochSec, isNull);
  });

  test('launch payload supports calendar alias fields', () {
    final payload = HomeWidgetLaunchPayload.fromDynamic(<String, Object?>{
      'action': 'stats',
      'dayEpochSec': '1711843200',
    });

    expect(payload, isNotNull);
    expect(payload!.widgetType, HomeWidgetType.calendar);
    expect(payload.dayEpochSec, 1711843200);
  });

  test('updateDailyReviewWidget forwards clearAvatar flag', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCall = call;
          return true;
        });

    final result = await HomeWidgetService.updateDailyReviewWidget(
      items: const <DailyReviewWidgetItem>[],
      title: 'Random Review',
      fallbackBody: 'Tap to open daily review',
      clearAvatar: true,
    );

    expect(result, isTrue);
    expect(capturedCall?.method, 'updateDailyReviewWidget');
    expect(capturedCall?.arguments, isA<Map<dynamic, dynamic>>());
    expect(
      (capturedCall!.arguments as Map<dynamic, dynamic>)['clearAvatar'],
      isTrue,
    );
  });

  test('clearHomeWidgets invokes native clear method', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCall = call;
          return true;
        });

    final result = await HomeWidgetService.clearHomeWidgets();

    expect(result, isTrue);
    expect(capturedCall?.method, 'clearHomeWidgets');
  });

  test('updateQuickInputWidget forwards localized hint', () async {
    MethodCall? capturedCall;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCall = call;
          return true;
        });

    final result = await HomeWidgetService.updateQuickInputWidget(
      hint: 'What\'s new?',
    );

    expect(result, isTrue);
    expect(capturedCall?.method, 'updateQuickInputWidget');
    expect(capturedCall?.arguments, isA<Map<dynamic, dynamic>>());
    expect(
      (capturedCall!.arguments as Map<dynamic, dynamic>)['hint'],
      'What\'s new?',
    );
  });
}
