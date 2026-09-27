import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

const double kMacosTrafficLightReservedWidth = 92;
const double kMacosTitleBarHeight = 52;

class DesktopWindowChromeInsets {
  const DesktopWindowChromeInsets({
    required this.top,
    required this.leading,
    required this.trailing,
  });

  const DesktopWindowChromeInsets.none() : top = 0, leading = 0, trailing = 0;

  final double top;
  final double leading;
  final double trailing;

  bool get isEmpty => top == 0 && leading == 0 && trailing == 0;

  EdgeInsetsDirectional asPadding({bool includeTop = false}) {
    return EdgeInsetsDirectional.only(
      start: leading,
      top: includeTop ? top : 0,
      end: trailing,
    );
  }
}

class DesktopWindowChromeSafeArea extends StatelessWidget {
  const DesktopWindowChromeSafeArea({
    super.key,
    required this.child,
    this.platform,
    this.contentExtendsIntoTitleBar = false,
    this.includeTop = false,
    this.includeLeading = true,
    this.includeTrailing = true,
  });

  final Widget child;
  final TargetPlatform? platform;
  final bool contentExtendsIntoTitleBar;
  final bool includeTop;
  final bool includeLeading;
  final bool includeTrailing;

  @override
  Widget build(BuildContext context) {
    final insets = resolveDesktopWindowChromeInsets(
      platform: platform ?? defaultTargetPlatform,
      contentExtendsIntoTitleBar: contentExtendsIntoTitleBar,
    );
    return Padding(
      padding: EdgeInsetsDirectional.only(
        start: includeLeading ? insets.leading : 0,
        top: includeTop ? insets.top : 0,
        end: includeTrailing ? insets.trailing : 0,
      ),
      child: child,
    );
  }
}

DesktopWindowChromeInsets resolveDesktopWindowChromeInsets({
  required TargetPlatform platform,
  bool contentExtendsIntoTitleBar = false,
}) {
  if (platform != TargetPlatform.macOS || !contentExtendsIntoTitleBar) {
    return const DesktopWindowChromeInsets.none();
  }
  return const DesktopWindowChromeInsets(
    top: kMacosTitleBarHeight,
    leading: kMacosTrafficLightReservedWidth,
    trailing: 0,
  );
}

double resolveMacosTrafficLightCompensation({
  required double currentLeadingWidth,
  TargetPlatform platform = TargetPlatform.macOS,
  bool contentExtendsIntoTitleBar = true,
}) {
  final insets = resolveDesktopWindowChromeInsets(
    platform: platform,
    contentExtendsIntoTitleBar: contentExtendsIntoTitleBar,
  );
  if (insets.leading <= currentLeadingWidth) return 0;
  return insets.leading - currentLeadingWidth;
}

class DesktopWindowChromeLeadingInset extends StatelessWidget {
  const DesktopWindowChromeLeadingInset({
    super.key,
    required this.contentExtendsIntoTitleBar,
    this.platform,
  });

  final bool contentExtendsIntoTitleBar;
  final TargetPlatform? platform;

  @override
  Widget build(BuildContext context) {
    final insets = resolveDesktopWindowChromeInsets(
      platform: platform ?? defaultTargetPlatform,
      contentExtendsIntoTitleBar: contentExtendsIntoTitleBar,
    );
    return SizedBox(width: insets.leading);
  }
}
