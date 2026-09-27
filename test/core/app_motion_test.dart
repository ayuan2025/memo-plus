import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_motion.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('returns configured durations when motion is enabled', (
    tester,
  ) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AppMotion.isEnabled(capturedContext), isTrue);
    expect(
      AppMotion.effectiveDuration(capturedContext, AppMotion.fast),
      AppMotion.fast,
    );
    expect(
      AppMotion.effectiveDuration(capturedContext, AppMotion.medium),
      AppMotion.medium,
    );
  });

  testWidgets('returns zero duration when motion is disabled', (tester) async {
    late BuildContext capturedContext;

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) {
          final mediaQuery = MediaQuery.of(context);
          return MediaQuery(
            data: mediaQuery.copyWith(disableAnimations: true),
            child: child!,
          );
        },
        home: Builder(
          builder: (context) {
            capturedContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(AppMotion.isEnabled(capturedContext), isFalse);
    expect(
      AppMotion.effectiveDuration(capturedContext, AppMotion.fast),
      Duration.zero,
    );
    expect(
      AppMotion.effectiveDuration(capturedContext, AppMotion.route),
      Duration.zero,
    );
  });
}
