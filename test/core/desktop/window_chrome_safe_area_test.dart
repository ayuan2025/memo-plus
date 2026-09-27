import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/core/desktop/window_chrome_safe_area.dart';

void main() {
  test('macOS transparent titlebar reserves native traffic-light area', () {
    final insets = resolveDesktopWindowChromeInsets(
      platform: TargetPlatform.macOS,
      contentExtendsIntoTitleBar: true,
    );

    expect(insets.leading, kMacosTrafficLightReservedWidth);
    expect(insets.top, kMacosTitleBarHeight);
    expect(insets.trailing, 0);
  });

  test('non-titlebar and non-macOS contexts keep zero chrome inset', () {
    expect(
      resolveDesktopWindowChromeInsets(
        platform: TargetPlatform.macOS,
        contentExtendsIntoTitleBar: false,
      ).isEmpty,
      isTrue,
    );
    expect(
      resolveDesktopWindowChromeInsets(
        platform: TargetPlatform.windows,
        contentExtendsIntoTitleBar: true,
      ).isEmpty,
      isTrue,
    );
  });

  test('macOS compensation only covers missing leading width', () {
    expect(resolveMacosTrafficLightCompensation(currentLeadingWidth: 0), 92);
    expect(resolveMacosTrafficLightCompensation(currentLeadingWidth: 72), 20);
    expect(resolveMacosTrafficLightCompensation(currentLeadingWidth: 280), 0);
    expect(
      resolveMacosTrafficLightCompensation(
        currentLeadingWidth: 0,
        platform: TargetPlatform.windows,
      ),
      0,
    );
  });

  testWidgets(
    'shared safe area reserves macOS leading chrome only when needed',
    (tester) async {
      const childKey = ValueKey<String>('safe-area-child');

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DesktopWindowChromeSafeArea(
            platform: TargetPlatform.macOS,
            contentExtendsIntoTitleBar: true,
            child: SizedBox(key: childKey, width: 10, height: 10),
          ),
        ),
      );

      expect(
        tester.getTopLeft(find.byKey(childKey)).dx,
        kMacosTrafficLightReservedWidth,
      );

      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: DesktopWindowChromeSafeArea(
            platform: TargetPlatform.windows,
            contentExtendsIntoTitleBar: true,
            child: SizedBox(key: childKey, width: 10, height: 10),
          ),
        ),
      );

      expect(tester.getTopLeft(find.byKey(childKey)).dx, 0);
    },
  );
}
