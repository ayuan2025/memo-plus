import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_motion.dart';
import 'package:memos_flutter_app/core/app_route_transitions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('buildFadeSlideRoute uses shared durations', (tester) async {
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

    final route =
        buildFadeSlideRoute<void>(
              context: capturedContext,
              builder: (_) => const Placeholder(),
            )
            as PageRouteBuilder<void>;

    expect(route.transitionDuration, AppMotion.route);
    expect(route.reverseTransitionDuration, AppMotion.exit);
  });

  testWidgets('route helpers disable transitions when system motion is off', (
    tester,
  ) async {
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

    final pageRoute =
        buildFadeSlideRoute<void>(
              context: capturedContext,
              builder: (_) => const Placeholder(),
            )
            as PageRouteBuilder<void>;
    final dialogRoute =
        buildDialogScaleRoute<void>(
              context: capturedContext,
              builder: (_) => const Placeholder(),
            )
            as RawDialogRoute<void>;

    expect(pageRoute.transitionDuration, Duration.zero);
    expect(pageRoute.reverseTransitionDuration, Duration.zero);
    expect(dialogRoute.transitionDuration, Duration.zero);
  });
}
