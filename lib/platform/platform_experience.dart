import 'package:flutter/widgets.dart';

import 'platform_target.dart';

enum PlatformRuntime { android, iOS, macOS, windows, linux, web }

enum PlatformFormFactor { phone, tablet, desktop, web }

enum PlatformInputModel { touch, pointerKeyboard, hybrid }

enum PlatformWindowModel {
  mobileScene,
  tabletScene,
  desktopWindow,
  browserViewport,
}

enum PlatformVisualFamily {
  materialMobile,
  cupertinoMobile,
  appleDesktop,
  windowsDesktop,
  linuxDesktop,
  webMaterial,
}

enum PlatformNavigationModel {
  bottomTabs,
  drawer,
  splitView,
  sidebarRail,
  desktopSidebar,
  desktopOverlay,
}

class PlatformExperience {
  const PlatformExperience({
    required this.target,
    required this.runtime,
    required this.formFactor,
    required this.inputModel,
    required this.windowModel,
    required this.visualFamily,
    required this.navigationModel,
  });

  final PlatformTarget target;
  final PlatformRuntime runtime;
  final PlatformFormFactor formFactor;
  final PlatformInputModel inputModel;
  final PlatformWindowModel windowModel;
  final PlatformVisualFamily visualFamily;
  final PlatformNavigationModel navigationModel;

  bool get isApple =>
      runtime == PlatformRuntime.iOS || runtime == PlatformRuntime.macOS;

  bool get isDesktop => formFactor == PlatformFormFactor.desktop;

  bool get isMobileLike =>
      formFactor == PlatformFormFactor.phone ||
      formFactor == PlatformFormFactor.tablet;

  bool get usesAppleVisuals =>
      visualFamily == PlatformVisualFamily.cupertinoMobile ||
      visualFamily == PlatformVisualFamily.appleDesktop;
}

PlatformExperience resolvePlatformExperience(BuildContext context) {
  final target = resolvePlatformTarget(context);
  return platformExperienceForTarget(target);
}

@visibleForTesting
PlatformExperience platformExperienceForTarget(PlatformTarget target) {
  return switch (target) {
    PlatformTarget.android => const PlatformExperience(
      target: PlatformTarget.android,
      runtime: PlatformRuntime.android,
      formFactor: PlatformFormFactor.phone,
      inputModel: PlatformInputModel.touch,
      windowModel: PlatformWindowModel.mobileScene,
      visualFamily: PlatformVisualFamily.materialMobile,
      navigationModel: PlatformNavigationModel.drawer,
    ),
    PlatformTarget.iPhone => const PlatformExperience(
      target: PlatformTarget.iPhone,
      runtime: PlatformRuntime.iOS,
      formFactor: PlatformFormFactor.phone,
      inputModel: PlatformInputModel.touch,
      windowModel: PlatformWindowModel.mobileScene,
      visualFamily: PlatformVisualFamily.cupertinoMobile,
      navigationModel: PlatformNavigationModel.bottomTabs,
    ),
    PlatformTarget.iPad => const PlatformExperience(
      target: PlatformTarget.iPad,
      runtime: PlatformRuntime.iOS,
      formFactor: PlatformFormFactor.tablet,
      inputModel: PlatformInputModel.hybrid,
      windowModel: PlatformWindowModel.tabletScene,
      visualFamily: PlatformVisualFamily.cupertinoMobile,
      navigationModel: PlatformNavigationModel.splitView,
    ),
    PlatformTarget.macOS => const PlatformExperience(
      target: PlatformTarget.macOS,
      runtime: PlatformRuntime.macOS,
      formFactor: PlatformFormFactor.desktop,
      inputModel: PlatformInputModel.pointerKeyboard,
      windowModel: PlatformWindowModel.desktopWindow,
      visualFamily: PlatformVisualFamily.appleDesktop,
      navigationModel: PlatformNavigationModel.desktopSidebar,
    ),
    PlatformTarget.windows => const PlatformExperience(
      target: PlatformTarget.windows,
      runtime: PlatformRuntime.windows,
      formFactor: PlatformFormFactor.desktop,
      inputModel: PlatformInputModel.pointerKeyboard,
      windowModel: PlatformWindowModel.desktopWindow,
      visualFamily: PlatformVisualFamily.windowsDesktop,
      navigationModel: PlatformNavigationModel.desktopSidebar,
    ),
    PlatformTarget.linux => const PlatformExperience(
      target: PlatformTarget.linux,
      runtime: PlatformRuntime.linux,
      formFactor: PlatformFormFactor.desktop,
      inputModel: PlatformInputModel.pointerKeyboard,
      windowModel: PlatformWindowModel.desktopWindow,
      visualFamily: PlatformVisualFamily.linuxDesktop,
      navigationModel: PlatformNavigationModel.desktopSidebar,
    ),
    PlatformTarget.web => const PlatformExperience(
      target: PlatformTarget.web,
      runtime: PlatformRuntime.web,
      formFactor: PlatformFormFactor.web,
      inputModel: PlatformInputModel.hybrid,
      windowModel: PlatformWindowModel.browserViewport,
      visualFamily: PlatformVisualFamily.webMaterial,
      navigationModel: PlatformNavigationModel.drawer,
    ),
  };
}
