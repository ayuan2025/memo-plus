import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:memos_flutter_app/platform/platform_experience.dart';
import 'package:memos_flutter_app/platform/platform_target.dart';

void main() {
  test('classifies android phone experience', () {
    final experience = platformExperienceForTarget(PlatformTarget.android);

    expect(experience.runtime, PlatformRuntime.android);
    expect(experience.formFactor, PlatformFormFactor.phone);
    expect(experience.inputModel, PlatformInputModel.touch);
    expect(experience.windowModel, PlatformWindowModel.mobileScene);
    expect(experience.visualFamily, PlatformVisualFamily.materialMobile);
    expect(experience.navigationModel, PlatformNavigationModel.drawer);
  });

  test('classifies iPhone experience separately from iPad', () {
    final iPhone = platformExperienceForTarget(PlatformTarget.iPhone);
    final iPad = platformExperienceForTarget(PlatformTarget.iPad);

    expect(iPhone.runtime, PlatformRuntime.iOS);
    expect(iPhone.formFactor, PlatformFormFactor.phone);
    expect(iPhone.inputModel, PlatformInputModel.touch);
    expect(iPhone.navigationModel, PlatformNavigationModel.bottomTabs);

    expect(iPad.runtime, PlatformRuntime.iOS);
    expect(iPad.formFactor, PlatformFormFactor.tablet);
    expect(iPad.inputModel, PlatformInputModel.hybrid);
    expect(iPad.navigationModel, PlatformNavigationModel.splitView);
  });

  test('classifies desktop platforms with distinct visual families', () {
    final macOS = platformExperienceForTarget(PlatformTarget.macOS);
    final windows = platformExperienceForTarget(PlatformTarget.windows);
    final linux = platformExperienceForTarget(PlatformTarget.linux);

    expect(macOS.formFactor, PlatformFormFactor.desktop);
    expect(macOS.inputModel, PlatformInputModel.pointerKeyboard);
    expect(macOS.visualFamily, PlatformVisualFamily.appleDesktop);

    expect(windows.formFactor, PlatformFormFactor.desktop);
    expect(windows.visualFamily, PlatformVisualFamily.windowsDesktop);

    expect(linux.formFactor, PlatformFormFactor.desktop);
    expect(linux.visualFamily, PlatformVisualFamily.linuxDesktop);
  });

  test('classifies web fallback as browser viewport', () {
    final experience = platformExperienceForTarget(PlatformTarget.web);

    expect(experience.runtime, PlatformRuntime.web);
    expect(experience.formFactor, PlatformFormFactor.web);
    expect(experience.inputModel, PlatformInputModel.hybrid);
    expect(experience.windowModel, PlatformWindowModel.browserViewport);
    expect(experience.visualFamily, PlatformVisualFamily.webMaterial);
  });

  testWidgets('resolves iPad-width iOS through BuildContext', (tester) async {
    debugPlatformTargetOverride = TargetPlatform.iOS;
    addTearDown(() => debugPlatformTargetOverride = null);

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: MediaQueryData(size: Size(820, 1180)),
          child: SizedBox.expand(),
        ),
      ),
    );

    final experience = resolvePlatformExperience(
      tester.element(find.byType(SizedBox)),
    );
    expect(experience.target, PlatformTarget.iPad);
    expect(experience.formFactor, PlatformFormFactor.tablet);
  });
}
