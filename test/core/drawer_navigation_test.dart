import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/app_motion.dart';
import 'package:memos_flutter_app/core/drawer_navigation.dart';

void main() {
  testWidgets('wide Windows drawer navigation uses desktop shared-axis route', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: MediaQuery(
            data: const MediaQueryData(size: Size(1600, 900)),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => closeDrawerThenPushReplacement(
                      context,
                      const _RouteTarget(),
                    ),
                    child: const Text('Navigate'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      expect(observer.replacedRoute, isA<PageRoute<dynamic>>());
      final route = observer.replacedRoute! as PageRoute<dynamic>;
      expect(route.transitionDuration, AppMotion.route);
      expect(route.reverseTransitionDuration, AppMotion.desktopOverlayExit);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });

  testWidgets('wide Windows drawer navigation respects disabled animations', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final observer = _TestNavigatorObserver();

      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(1600, 900),
              disableAnimations: true,
            ),
            child: Builder(
              builder: (context) {
                return Scaffold(
                  body: TextButton(
                    onPressed: () => closeDrawerThenPushReplacement(
                      context,
                      const _RouteTarget(),
                    ),
                    child: const Text('Navigate'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Navigate'));
      await tester.pump();

      expect(observer.replacedRoute, isA<PageRoute<dynamic>>());
      final route = observer.replacedRoute! as PageRoute<dynamic>;
      expect(route.transitionDuration, Duration.zero);
      expect(route.reverseTransitionDuration, Duration.zero);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}

class _RouteTarget extends StatelessWidget {
  const _RouteTarget();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Target')));
  }
}

class _TestNavigatorObserver extends NavigatorObserver {
  Route<dynamic>? replacedRoute;

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    replacedRoute = newRoute;
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
